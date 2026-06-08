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

    private var renderedMarkers: [String: GMSMarker] = [:]
    private var renderedRoutes: [String: GMSPolyline] = [:]
    private var renderedCircles: [String: GMSCircle] = [:]
    private var markerData: [String: MapMarker] = [:]
    private var routeData: [String: MapRoute] = [:]
    private var circleData: [String: MapCircle] = [:]
    private var userInitiatedMove = false

    public override init() { super.init() }

    public func createViewController() -> UIViewController {
        dispatchPrecondition(condition: .onQueue(.main))
        if mapView == nil {
            let mv = GMSMapView(options: GMSMapViewOptions())
            mv.delegate = self
            mv.paddingAdjustmentBehavior = .never
            mapView = mv
            applyPadding()
            renderMarkers(markers: pendingMarkers)
            renderRoutes(routes: pendingRoutes)
            renderCircles(circles: pendingCircles)
            DispatchQueue.main.async { [weak self] in self?.listener?.onReady() }
        }
        return MapHostViewController(mapSubview: mapView!)
    }

    public func setListener(listener: (any IosMapListener)?) {
        self.listener = listener
    }

    public func moveTo(target: GeoPoint, zoom: Float) {
        runOnMain {
            let cam = GMSCameraPosition.camera(withLatitude: target.lat, longitude: target.lng, zoom: zoom)
            self.mapView?.camera = cam
        }
    }

    public func animateTo(target: GeoPoint, zoom: Float, durationMs: Int32) {
        runOnMain {
            let cam = GMSCameraPosition.camera(withLatitude: target.lat, longitude: target.lng, zoom: zoom)
            self.mapView?.animate(to: cam)
        }
    }

    public func animateToWithBearing(target: GeoPoint, bearing: Float, zoom: Float, durationMs: Int32) {
        runOnMain {
            guard let mv = self.mapView else { return }
            let cam = GMSCameraPosition(
                target: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                zoom: zoom,
                bearing: CLLocationDirection(bearing),
                viewingAngle: Double(mv.camera.viewingAngle)
            )
            mv.animate(to: cam)
        }
    }

    public func fitBounds(points: [GeoPoint], leftPt: Float, topPt: Float, rightPt: Float, bottomPt: Float, animate: Bool) {
        guard !points.isEmpty else { return }
        if points.count == 1 {
            let single = points[0]
            runOnMain {
                let zoom = self.mapView?.camera.zoom ?? 15
                let cam = GMSCameraPosition.camera(withLatitude: single.lat, longitude: single.lng, zoom: zoom)
                self.mapView?.camera = cam
            }
            return
        }
        runOnMain {
            guard let mv = self.mapView else { return }
            var bounds = GMSCoordinateBounds()
            for p in points {
                bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: p.lat, longitude: p.lng))
            }
            let baseMargin: CGFloat = 24
            let insets = UIEdgeInsets(top: baseMargin, left: baseMargin, bottom: baseMargin, right: baseMargin)
            let update = GMSCameraUpdate.fit(bounds, with: insets)
            if animate { mv.animate(with: update) } else { mv.moveCamera(update) }
        }
    }

    public func zoomIn() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.animate(toZoom: mv.camera.zoom + 1)
        }
    }

    public func zoomOut() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.animate(toZoom: mv.camera.zoom - 1)
        }
    }

    public func setZoom(zoom: Float) {
        runOnMain { self.mapView?.animate(toZoom: zoom) }
    }

    public func setStyleUrl(url: String) {
        // Google Maps iOS does not support remote style URLs; ignore.
    }

    public func setStyleJson(json: String) {
        runOnMain {
            self.mapView?.mapStyle = (try? GMSMapStyle(jsonString: json))
        }
    }

    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread { block() } else { DispatchQueue.main.async(execute: block) }
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

    public func close() {
        dispatchPrecondition(condition: .onQueue(.main))
        if closed { return }
        closed = true
        renderedMarkers.values.forEach { $0.map = nil }
        renderedRoutes.values.forEach { $0.map = nil }
        renderedCircles.values.forEach { $0.map = nil }
        renderedMarkers.removeAll()
        renderedRoutes.removeAll()
        renderedCircles.removeAll()
        markerData.removeAll()
        routeData.removeAll()
        circleData.removeAll()
        mapView?.delegate = nil
        mapView?.removeFromSuperview()
        mapView = nil
    }

    private func applyPadding() {
        mapView?.padding = pendingPadding
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
                if previous?.point != marker.point {
                    existing.position = CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng)
                }
                if previous?.rotation != marker.rotation { existing.rotation = CLLocationDegrees(marker.rotation) }
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
            }
            markerData[id] = marker
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
        return true
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
