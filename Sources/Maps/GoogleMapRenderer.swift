import UIKit
import GoogleMaps
import YallaComponents

public final class GoogleMapRenderer: NSObject, IosMapRenderer, GMSMapViewDelegate {

    private var mapView: GMSMapView?
    private weak var listener: IosMapListener?
    private var closed = false

    private var pendingMarkers: [MapMarker] = []
    private var pendingRoutes: [MapRoute] = []
    private var pendingCircles: [MapCircle] = []
    private var pendingPadding = UIEdgeInsets.zero
    private var lastEmittedCamera: GMSCameraPosition?
    private var interactionEnabled = true
    private var pendingIsDark = false
    private var pendingUserLocation: GeoPoint?
    private var userLocationMarker: GMSMarker?
    private var userLocationCircle: GMSCircle?

    private var renderedMarkers: [String: GMSMarker] = [:]
    private var renderedRoutes: [String: GMSPolyline] = [:]
    private var renderedCircles: [String: GMSCircle] = [:]
    private var markerData: [String: MapMarker] = [:]
    private var routeData: [String: MapRoute] = [:]
    private var circleData: [String: MapCircle] = [:]
    private var userInitiatedMove = false
    private lazy var motion = MarkerMotionDriver { [weak self] poses in self?.applyMarkerPoses(poses) }

    public override init() { super.init() }

    public func createViewController() -> UIViewController {
        dispatchPrecondition(condition: .onQueue(.main))
        if mapView == nil {
            let mv = GMSMapView(options: GMSMapViewOptions())
            mv.delegate = self
            mv.paddingAdjustmentBehavior = .never
            mv.settings.compassButton = false
            mv.settings.rotateGestures = false
            mv.settings.tiltGestures = false
            mv.isBuildingsEnabled = false
            mv.setMinZoom(Float(MapConstants.shared.ZOOM_MIN), maxZoom: Float(MapConstants.shared.ZOOM_MAX))
            mapView = mv
            applyInteractionEnabled()
            applyPadding()
            applyColorScheme()
            renderMarkers(markers: pendingMarkers)
            renderRoutes(routes: pendingRoutes)
            renderCircles(circles: pendingCircles)
            renderUserLocation()
            DispatchQueue.main.async { [weak self] in self?.listener?.onReady() }
        }
        return MapHostViewController(mapSubview: mapView!)
    }

    public func setListener(listener: (any IosMapListener)?) {
        self.listener = listener
    }

    public func moveTo(target: GeoPoint, zoom: Float) {
        runOnMain {
            let current = self.mapView?.camera
            let cam = GMSCameraPosition(
                target: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                zoom: self.clampZoom(zoom),
                bearing: current?.bearing ?? 0,
                viewingAngle: current?.viewingAngle ?? 0
            )
            self.mapView?.camera = cam
        }
    }

    public func animateTo(target: GeoPoint, zoom: Float, durationMs: Int32) {
        runOnMain {
            let current = self.mapView?.camera
            let cam = GMSCameraPosition(
                target: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                zoom: self.clampZoom(zoom),
                bearing: current?.bearing ?? 0,
                viewingAngle: current?.viewingAngle ?? 0
            )
            self.mapView?.animate(to: cam)
        }
    }

    public func animateToWithBearing(target: GeoPoint, bearing: Float, zoom: Float, durationMs: Int32) {
        runOnMain {
            guard let mv = self.mapView else { return }
            let cam = GMSCameraPosition(
                target: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                zoom: self.clampZoom(zoom),
                bearing: CLLocationDirection(bearing),
                viewingAngle: Double(mv.camera.viewingAngle)
            )
            mv.animate(to: cam)
        }
    }

    public func fitBounds(points: [GeoPoint], leftPt: Float, topPt: Float, rightPt: Float, bottomPt: Float, animate: Bool) {
        let valid = points.filter { $0.lat != 0 || $0.lng != 0 }
        guard !valid.isEmpty else { return }
        if valid.count == 1 {
            let single = valid[0]
            runOnMain {
                let current = self.mapView?.camera
                let zoom = self.clampZoom(current?.zoom ?? 15)
                let cam = GMSCameraPosition(
                    target: CLLocationCoordinate2D(latitude: single.lat, longitude: single.lng),
                    zoom: zoom,
                    bearing: current?.bearing ?? 0,
                    viewingAngle: current?.viewingAngle ?? 0
                )
                if animate { self.mapView?.animate(to: cam) } else { self.mapView?.camera = cam }
            }
            return
        }
        runOnMain {
            guard let mv = self.mapView else { return }
            var bounds = GMSCoordinateBounds()
            for p in valid {
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: p.lat, longitude: p.lng))
            }
            let baseMargin: CGFloat = 24
            let insets = UIEdgeInsets(
                top: CGFloat(topPt) + baseMargin,
                left: CGFloat(leftPt) + baseMargin,
                bottom: CGFloat(bottomPt) + baseMargin,
                right: CGFloat(rightPt) + baseMargin
            )
            guard let fitted = mv.camera(for: bounds, insets: insets) else { return }
            let cam = GMSCameraPosition(
                target: fitted.target,
                zoom: min(fitted.zoom, Float(MapConstants.shared.FIT_ZOOM_MAX)),
                bearing: fitted.bearing,
                viewingAngle: fitted.viewingAngle
            )
            if animate { mv.animate(to: cam) } else { mv.camera = cam }
        }
    }

    public func zoomIn() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.animate(toZoom: self.clampZoom(mv.camera.zoom + 1))
        }
    }

    public func zoomOut() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.animate(toZoom: self.clampZoom(mv.camera.zoom - 1))
        }
    }

    public func setZoom(zoom: Float) {
        runOnMain { self.mapView?.animate(toZoom: self.clampZoom(zoom)) }
    }

    public func setStyleUrl(url: String) {
    }

    public func setStyleJson(json: String) {
        runOnMain {
            self.mapView?.mapStyle = (try? GMSMapStyle(jsonString: json))
        }
    }

    public func setColorScheme(isDark: Bool) {
        runOnMain {
            self.pendingIsDark = isDark
            self.applyColorScheme()
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
    }

    public func setInteractionEnabled(enabled: Bool) {
        runOnMain {
            self.interactionEnabled = enabled
            self.applyInteractionEnabled()
        }
    }

    public func setPaddingPt(leftPt: Float, topPt: Float, rightPt: Float, bottomPt: Float) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingPadding = UIEdgeInsets(
            top: CGFloat(topPt),
            left: CGFloat(leftPt),
            bottom: CGFloat(bottomPt),
            right: CGFloat(rightPt)
        )
        applyPadding()
    }

    public func setMarkers(markers: [MapMarker]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingMarkers = markers
        if mapView != nil { renderMarkers(markers: markers) }
    }

    public func setRoutes(routes: [MapRoute]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingRoutes = routes
        if mapView != nil { renderRoutes(routes: routes) }
    }

    public func setCircles(circles: [MapCircle]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingCircles = circles
        if mapView != nil { renderCircles(circles: circles) }
    }

    public func setUserLocation(point: GeoPoint?) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingUserLocation = point
        if mapView != nil { renderUserLocation() }
    }

    public func close() {
        dispatchPrecondition(condition: .onQueue(.main))
        if closed { return }
        closed = true
        motion.clear()
        renderedMarkers.values.forEach { $0.map = nil }
        renderedRoutes.values.forEach { $0.map = nil }
        renderedCircles.values.forEach { $0.map = nil }
        renderedMarkers.removeAll()
        renderedRoutes.removeAll()
        renderedCircles.removeAll()
        markerData.removeAll()
        routeData.removeAll()
        circleData.removeAll()
        userLocationMarker?.map = nil
        userLocationCircle?.map = nil
        userLocationMarker = nil
        userLocationCircle = nil
        mapView?.delegate = nil
        mapView?.removeFromSuperview()
        mapView = nil
    }

    private func applyPadding() {
        mapView?.padding = pendingPadding
    }

    private func applyInteractionEnabled() {
        guard let mv = mapView else { return }
        mv.settings.scrollGestures = interactionEnabled
        mv.settings.zoomGestures = interactionEnabled
        mv.settings.rotateGestures = false
        mv.settings.tiltGestures = false
    }

    private func applyColorScheme() {
        if #available(iOS 13.0, *) {
            mapView?.overrideUserInterfaceStyle = pendingIsDark ? .dark : .light
        }
    }

    private func clampZoom(_ zoom: Float) -> Float {
        return min(max(zoom, Float(MapConstants.shared.ZOOM_MIN)), Float(MapConstants.shared.ZOOM_MAX))
    }

    private func renderMarkers(markers: [MapMarker]) {
        guard let map = mapView else { return }
        let incoming = Dictionary(uniqueKeysWithValues: markers.map { ($0.id, $0) })
        let stale = Set(renderedMarkers.keys).subtracting(incoming.keys)
        stale.forEach { id in
            renderedMarkers.removeValue(forKey: id)?.map = nil
            markerData.removeValue(forKey: id)
        }
        for (id, marker) in incoming {
            let previous = markerData[id]
            if let existing = renderedMarkers[id] {
                let moved = previous?.point != marker.point || previous?.rotation != marker.rotation
                if marker.flat {
                    if moved { motion.push(id: id, point: marker.point, routeHeading: marker.routeHeading?.floatValue, serverHeading: marker.rotation) }
                } else if moved {
                    existing.position = CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng)
                    existing.rotation = CLLocationDegrees(marker.rotation)
                }
                if previous?.anchor != marker.anchor {
                    existing.groundAnchor = CGPoint(x: CGFloat(marker.anchor.x), y: CGFloat(marker.anchor.y))
                }
                if previous?.flat != marker.flat { existing.isFlat = marker.flat }
                if previous?.zIndex != marker.zIndex { existing.zIndex = Int32(marker.zIndex) }
                if previous?.icon != marker.icon, let iconValue = marker.icon {
                    existing.icon = MapIconLoader.uiImage(for: iconValue)
                }
            } else {
                let m = GMSMarker(position: CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng))
                m.rotation = CLLocationDegrees(marker.rotation)
                m.groundAnchor = CGPoint(x: CGFloat(marker.anchor.x), y: CGFloat(marker.anchor.y))
                m.isFlat = marker.flat
                m.zIndex = Int32(marker.zIndex)
                m.isTappable = true
                m.title = marker.contentDescription
                if let iconValue = marker.icon { m.icon = MapIconLoader.uiImage(for: iconValue) }
                m.map = map
                renderedMarkers[id] = m
                if marker.flat { motion.push(id: id, point: marker.point, routeHeading: marker.routeHeading?.floatValue, serverHeading: marker.rotation) }
            }
            markerData[id] = marker
        }
        motion.retain(ids: Set(incoming.values.filter { $0.flat }.map { $0.id }))
        motion.ensureRunning()
    }

    private func applyMarkerPoses(_ poses: [String: Pose]) {
        for (id, pose) in poses {
            guard let marker = renderedMarkers[id] else { continue }
            marker.position = CLLocationCoordinate2D(latitude: pose.point.lat, longitude: pose.point.lng)
            marker.rotation = CLLocationDegrees(pose.bearing)
        }
    }

    private func renderRoutes(routes: [MapRoute]) {
        guard let map = mapView else { return }
        let incoming = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        let stale = Set(renderedRoutes.keys).subtracting(incoming.keys)
        stale.forEach { id in
            renderedRoutes.removeValue(forKey: id)?.map = nil
            routeData.removeValue(forKey: id)
        }
        for (id, route) in incoming {
            let path = GMSMutablePath()
            for p in route.points { path.add(CLLocationCoordinate2D(latitude: p.lat, longitude: p.lng)) }
            if let existing = renderedRoutes[id] {
                existing.path = path
                existing.strokeColor = uiColor(fromArgb: route.colorArgb)
                existing.strokeWidth = CGFloat(route.widthDp)
                existing.zIndex = Int32(route.zIndex)
            } else {
                let line = GMSPolyline(path: path)
                line.strokeColor = uiColor(fromArgb: route.colorArgb)
                line.strokeWidth = CGFloat(route.widthDp)
                line.zIndex = Int32(route.zIndex)
                line.map = map
                renderedRoutes[id] = line
            }
            routeData[id] = route
        }
    }

    private func renderCircles(circles: [MapCircle]) {
        guard let map = mapView else { return }
        let incoming = Dictionary(uniqueKeysWithValues: circles.map { ($0.id, $0) })
        let stale = Set(renderedCircles.keys).subtracting(incoming.keys)
        stale.forEach { id in
            renderedCircles.removeValue(forKey: id)?.map = nil
            circleData.removeValue(forKey: id)
        }
        for (id, circle) in incoming {
            if let existing = renderedCircles[id] {
                existing.position = CLLocationCoordinate2D(latitude: circle.center.lat, longitude: circle.center.lng)
                existing.radius = CLLocationDistance(circle.radiusMeters)
                existing.fillColor = uiColor(fromArgb: circle.fillColorArgb)
                existing.strokeColor = uiColor(fromArgb: circle.strokeColorArgb)
                existing.strokeWidth = CGFloat(circle.strokeWidthDp)
                existing.zIndex = Int32(circle.zIndex)
            } else {
                let c = GMSCircle(position: CLLocationCoordinate2D(latitude: circle.center.lat, longitude: circle.center.lng), radius: CLLocationDistance(circle.radiusMeters))
                c.fillColor = uiColor(fromArgb: circle.fillColorArgb)
                c.strokeColor = uiColor(fromArgb: circle.strokeColorArgb)
                c.strokeWidth = CGFloat(circle.strokeWidthDp)
                c.zIndex = Int32(circle.zIndex)
                c.map = map
                renderedCircles[id] = c
            }
            circleData[id] = circle
        }
    }

    private func renderUserLocation() {
        guard let map = mapView else { return }
        guard let point = pendingUserLocation else {
            userLocationMarker?.map = nil
            userLocationCircle?.map = nil
            userLocationMarker = nil
            userLocationCircle = nil
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng)
        if let marker = userLocationMarker {
            marker.position = coordinate
        } else {
            let marker = GMSMarker(position: coordinate)
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isFlat = false
            marker.isTappable = false
            marker.icon = MapIconLoader.userLocationDotImage
            marker.map = map
            userLocationMarker = marker
        }
        if let circle = userLocationCircle {
            circle.position = coordinate
        } else {
            let circle = GMSCircle(position: coordinate, radius: 50)
            circle.fillColor = uiColor(fromArgb: 0x33562DF8)
            circle.strokeColor = uiColor(fromArgb: 0x66562DF8)
            circle.strokeWidth = 1
            circle.map = map
            userLocationCircle = circle
        }
    }

    private func uiColor(fromArgb argb: Int32) -> UIColor {
        let value = UInt32(bitPattern: argb)
        let a = CGFloat((value >> 24) & 0xFF) / 255.0
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    public func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        userInitiatedMove = gesture
    }

    public func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if let prev = lastEmittedCamera, cameraEpsilonEqual(prev, position) { return }
        lastEmittedCamera = position
        let geo = GeoPoint(lat: position.target.latitude, lng: position.target.longitude)
        listener?.onCameraMove(
            target: geo,
            zoom: position.zoom,
            bearing: Float(position.bearing),
            tilt: Float(position.viewingAngle),
            isByUser: userInitiatedMove
        )
    }

    public func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if let id = renderedMarkers.first(where: { $0.value === marker })?.key {
            listener?.onMarkerTapped(id: id)
        }
        return false
    }

    public func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        listener?.onMapTapped(point: GeoPoint(lat: coordinate.latitude, lng: coordinate.longitude))
    }

    public func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        listener?.onMapLongPressed(point: GeoPoint(lat: coordinate.latitude, lng: coordinate.longitude))
    }

    public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        lastEmittedCamera = position
        let geo = GeoPoint(lat: position.target.latitude, lng: position.target.longitude)
        listener?.onCameraIdle(
            target: geo,
            zoom: position.zoom,
            bearing: Float(position.bearing),
            tilt: Float(position.viewingAngle),
            isByUser: userInitiatedMove
        )
        userInitiatedMove = false
    }

    private func cameraEpsilonEqual(_ a: GMSCameraPosition, _ b: GMSCameraPosition) -> Bool {
        return abs(a.target.latitude - b.target.latitude) < 1e-6 &&
            abs(a.target.longitude - b.target.longitude) < 1e-6 &&
            abs(a.zoom - b.zoom) < 1e-3 &&
            abs(a.bearing - b.bearing) < 0.1 &&
            abs(a.viewingAngle - b.viewingAngle) < 0.1
    }
}
