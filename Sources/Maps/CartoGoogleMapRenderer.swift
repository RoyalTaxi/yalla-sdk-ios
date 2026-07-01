import UIKit
import GoogleMaps
import YallaComponents

public final class CartoGoogleMapRenderer: NSObject, GoogleIosMapRenderer, GMSMapViewDelegate {

    private let mapView: GMSMapView
    private var delegate: GoogleIosMapDelegate?
    private var readyAnnounced = false
    private var userInitiatedMove = false

    private var icons: [String: UIImage] = [:]
    private var staticMarkers: [String: GMSMarker] = [:]
    private var staticData: [String: GoogleIosMarker] = [:]
    private var posedMarkers: [String: GMSMarker] = [:]
    private var posedIconKeys: [String: String] = [:]
    private var polylines: [String: GMSPolyline] = [:]
    private var circleOverlays: [String: GMSCircle] = [:]

    public init(camera: GoogleIosCamera, minZoom: Float, maxZoom: Float) {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(
            target: CLLocationCoordinate2D(latitude: camera.lat, longitude: camera.lng),
            zoom: camera.zoom,
            bearing: CLLocationDirection(camera.bearing),
            viewingAngle: Double(camera.tilt)
        )
        mapView = GMSMapView(options: options)
        super.init()
        mapView.delegate = self
        mapView.paddingAdjustmentBehavior = .never
        mapView.settings.compassButton = false
        mapView.settings.rotateGestures = false
        mapView.settings.tiltGestures = false
        mapView.settings.scrollGestures = true
        mapView.settings.zoomGestures = true
        mapView.isBuildingsEnabled = false
        mapView.setMinZoom(minZoom, maxZoom: maxZoom)
        DispatchQueue.main.async { [weak self] in self?.announceReady() }
    }

    public var view: UIView { mapView }

    public func setDelegate(delegate: GoogleIosMapDelegate?) {
        self.delegate = delegate
        if readyAnnounced { delegate?.onReady() }
    }

    private func announceReady() {
        readyAnnounced = true
        delegate?.onReady()
    }

    public func setCamera(camera: GoogleIosCamera) {
        mapView.camera = gmsCamera(camera)
    }

    public func animateCamera(camera: GoogleIosCamera, durationMs: Int32) {
        CATransaction.begin()
        CATransaction.setValue(Double(durationMs) / 1000.0, forKey: kCATransactionAnimationDuration)
        mapView.animate(to: gmsCamera(camera))
        CATransaction.commit()
    }

    public func fitBounds(points: [GeoPoint], paddingPt: Double, maxZoom: Float, animate: Bool) {
        guard !points.isEmpty else { return }
        var bounds = GMSCoordinateBounds()
        for p in points {
            bounds = bounds.includingCoordinate(CLLocationCoordinate2D(latitude: p.lat, longitude: p.lng))
        }
        let inset = CGFloat(paddingPt)
        let insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        guard let fitted = mapView.camera(for: bounds, insets: insets) else { return }
        let capped = GMSCameraPosition(
            target: fitted.target,
            zoom: min(fitted.zoom, maxZoom),
            bearing: fitted.bearing,
            viewingAngle: fitted.viewingAngle
        )
        if animate { mapView.animate(to: capped) } else { mapView.camera = capped }
    }

    public func setPadding(bottomPt: Double, durationMs: Int32) {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat(bottomPt), right: 0)
        if durationMs > 0 {
            UIView.animate(withDuration: Double(durationMs) / 1000.0) { self.mapView.padding = insets }
        } else {
            UIView.performWithoutAnimation { self.mapView.padding = insets }
        }
    }

    public func setAppearance(isDark: Bool, styleJson: String?) {
        mapView.overrideUserInterfaceStyle = isDark ? .dark : .light
        mapView.mapStyle = styleJson.flatMap { try? GMSMapStyle(jsonString: $0) }
    }

    public func setIcons(icons: [String: UIImage]) {
        self.icons = icons
        for (id, marker) in staticMarkers {
            marker.icon = staticData[id]?.iconKey.flatMap { icons[$0] }
        }
        for (id, marker) in posedMarkers {
            marker.icon = posedIconKeys[id].flatMap { icons[$0] }
        }
    }

    public func setMarkers(markers: [GoogleIosMarker]) {
        let incoming = Dictionary(markers.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        for id in Set(staticMarkers.keys).subtracting(incoming.keys) {
            staticMarkers.removeValue(forKey: id)?.map = nil
            staticData.removeValue(forKey: id)
        }
        for (id, marker) in incoming {
            if let existing = staticMarkers[id] {
                update(existing, from: staticData[id], to: marker)
            } else {
                staticMarkers[id] = makeMarker(marker)
            }
            staticData[id] = marker
        }
    }

    public func applyPose(pose: GoogleIosPose) {
        staticMarkers.removeValue(forKey: pose.id)?.map = nil
        staticData.removeValue(forKey: pose.id)
        let position = CLLocationCoordinate2D(latitude: pose.lat, longitude: pose.lng)
        if let existing = posedMarkers[pose.id] {
            existing.position = position
            existing.rotation = CLLocationDegrees(pose.bearing)
            if posedIconKeys[pose.id] != pose.iconKey {
                existing.icon = pose.iconKey.flatMap { icons[$0] }
            }
        } else {
            let m = GMSMarker(position: position)
            m.groundAnchor = CGPoint(x: CGFloat(pose.anchorU), y: CGFloat(pose.anchorV))
            m.rotation = CLLocationDegrees(pose.bearing)
            m.isFlat = true
            m.isTappable = false
            m.icon = pose.iconKey.flatMap { icons[$0] }
            m.map = mapView
            posedMarkers[pose.id] = m
        }
        posedIconKeys[pose.id] = pose.iconKey
    }

    public func setRoutes(routes: [GoogleIosRoute]) {
        let incoming = Dictionary(routes.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        for id in Set(polylines.keys).subtracting(incoming.keys) {
            polylines.removeValue(forKey: id)?.map = nil
        }
        for (id, route) in incoming {
            let path = GMSMutablePath()
            for p in route.points { path.add(CLLocationCoordinate2D(latitude: p.lat, longitude: p.lng)) }
            let line = polylines[id] ?? GMSPolyline()
            line.path = path
            line.strokeColor = UIColor(argb: route.colorArgb)
            line.strokeWidth = CGFloat(route.widthPt)
            line.zIndex = Int32(route.zIndex)
            if route.dashed {
                let styles = [GMSStrokeStyle.solidColor(UIColor(argb: route.colorArgb)), GMSStrokeStyle.solidColor(.clear)]
                line.spans = GMSStyleSpans(path, styles, [10, 6], .rhumb)
            } else {
                line.spans = nil
            }
            if polylines[id] == nil {
                line.map = mapView
                polylines[id] = line
            }
        }
    }

    public func setCircles(circles: [GoogleIosCircle]) {
        let incoming = Dictionary(circles.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        for id in Set(circleOverlays.keys).subtracting(incoming.keys) {
            circleOverlays.removeValue(forKey: id)?.map = nil
        }
        for (id, circle) in incoming {
            let overlay = circleOverlays[id] ?? GMSCircle()
            overlay.position = CLLocationCoordinate2D(latitude: circle.lat, longitude: circle.lng)
            overlay.radius = CLLocationDistance(circle.radiusMeters)
            overlay.fillColor = UIColor(argb: circle.fillArgb)
            overlay.strokeColor = UIColor(argb: circle.strokeArgb)
            overlay.strokeWidth = CGFloat(circle.strokeWidthPt)
            overlay.zIndex = Int32(circle.zIndex)
            if circleOverlays[id] == nil {
                overlay.map = mapView
                circleOverlays[id] = overlay
            }
        }
    }

    public func dispose() {
        mapView.delegate = nil
        delegate = nil
        staticMarkers.values.forEach { $0.map = nil }
        posedMarkers.values.forEach { $0.map = nil }
        polylines.values.forEach { $0.map = nil }
        circleOverlays.values.forEach { $0.map = nil }
        staticMarkers.removeAll()
        staticData.removeAll()
        posedMarkers.removeAll()
        posedIconKeys.removeAll()
        polylines.removeAll()
        circleOverlays.removeAll()
        mapView.removeFromSuperview()
    }

    private func gmsCamera(_ camera: GoogleIosCamera) -> GMSCameraPosition {
        GMSCameraPosition(
            target: CLLocationCoordinate2D(latitude: camera.lat, longitude: camera.lng),
            zoom: camera.zoom,
            bearing: CLLocationDirection(camera.bearing),
            viewingAngle: Double(camera.tilt)
        )
    }

    private func makeMarker(_ marker: GoogleIosMarker) -> GMSMarker {
        let m = GMSMarker(position: CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lng))
        m.groundAnchor = CGPoint(x: CGFloat(marker.anchorU), y: CGFloat(marker.anchorV))
        m.rotation = CLLocationDegrees(marker.rotation)
        m.isFlat = marker.flat
        m.zIndex = Int32(marker.zIndex)
        m.isTappable = false
        m.icon = marker.iconKey.flatMap { icons[$0] }
        m.map = mapView
        return m
    }

    private func update(_ existing: GMSMarker, from previous: GoogleIosMarker?, to marker: GoogleIosMarker) {
        if previous?.lat != marker.lat || previous?.lng != marker.lng {
            existing.position = CLLocationCoordinate2D(latitude: marker.lat, longitude: marker.lng)
        }
        if previous?.rotation != marker.rotation { existing.rotation = CLLocationDegrees(marker.rotation) }
        if previous?.anchorU != marker.anchorU || previous?.anchorV != marker.anchorV {
            existing.groundAnchor = CGPoint(x: CGFloat(marker.anchorU), y: CGFloat(marker.anchorV))
        }
        if previous?.flat != marker.flat { existing.isFlat = marker.flat }
        if previous?.zIndex != marker.zIndex { existing.zIndex = Int32(marker.zIndex) }
        if previous?.iconKey != marker.iconKey { existing.icon = marker.iconKey.flatMap { icons[$0] } }
    }

    public func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        userInitiatedMove = gesture
    }

    public func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        delegate?.onCameraMove(
            lat: position.target.latitude,
            lng: position.target.longitude,
            zoom: position.zoom,
            bearing: Float(position.bearing),
            tilt: Float(position.viewingAngle),
            isByUser: userInitiatedMove
        )
    }

    public func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        delegate?.onCameraIdle(
            lat: position.target.latitude,
            lng: position.target.longitude,
            zoom: position.zoom,
            bearing: Float(position.bearing),
            tilt: Float(position.viewingAngle),
            isByUser: userInitiatedMove
        )
        userInitiatedMove = false
    }

    public func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        delegate?.onMapTapped(lat: coordinate.latitude, lng: coordinate.longitude)
    }

    public func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        delegate?.onMapLongPressed(lat: coordinate.latitude, lng: coordinate.longitude)
    }
}
