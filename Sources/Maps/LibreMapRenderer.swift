import UIKit
import MapLibre
import YallaComponents

public final class LibreMapRenderer: NSObject, IosMapRenderer, MLNMapViewDelegate {

    private let styleURL: String
    private var mapView: MLNMapView?
    private var style: MLNStyle?
    private weak var listener: IosMapListener?
    private var closed = false

    private var pendingMarkers: [MapMarker] = []
    private var routeBindings: [String: String] = [:]
    private var pendingRoutes: [MapRoute] = []
    private var pendingPadding = UIEdgeInsets.zero
    private var lastEmittedCenter: CLLocationCoordinate2D?
    private var warnedCirclesUnsupported = false
    private var interactionEnabled = true
    private var pendingUserLocation: GeoPoint?
    private var userLocationAnnotation: MLNPointAnnotation?
    private var userLocationSource: MLNShapeSource?
    private var userLocationLayer: MLNCircleStyleLayer?

    private var renderedAnnotations: [String: MLNPointAnnotation] = [:]
    private var markerImages: [String: UIImage] = [:]
    private var sharedIconKeys: [String: String] = [:]
    private var sharedIconReuseIds: Set<String> = []
    private var markerData: [String: MapMarker] = [:]
    private var routeData: [String: MapRoute] = [:]
    private var routeSources: [String: MLNShapeSource] = [:]
    private var routeLayers: [String: MLNLineStyleLayer] = [:]
    // Flat ("car") markers that declared `followsRouteId`, mapped to that route id so the trimmed
    // route from the motion model can be written back to the right line layer as the car eats it.
    private var followedRouteByMarker: [String: String] = [:]
    private var seededRoutePoints: [String: [GeoPoint]] = [:]
    // Honesty-connector line layers (raw GPS -> snapped car) per flat marker, added only while the
    // model emits a connector for that marker and removed when it goes nil.
    private var connectorSources: [String: MLNShapeSource] = [:]
    private var connectorLayers: [String: MLNLineStyleLayer] = [:]
    // Live custom annotation views for flat car markers, keyed by marker id, so their rotation can
    // be re-compensated when the map camera rotates.
    private var carAnnotationViews: [String: LibreCarAnnotationView] = [:]
    private var lastMarkerViewBearing: CLLocationDirection?
    private var userInitiatedMove = false

    /// Feature flag — chord interpolation is the production default. Flip this to `true` *before the
    /// map is created* (i.e. before ``createViewController()``) to opt this renderer into
    /// route-following; with it off, `followsRouteId` markers stay pure chord interpolators and the
    /// motion model's `setRoute` is a no-op. Platform flips are done interactively on-device, not in
    /// the SDK (see yalla-sdk ADR 0003).
    public let routeFollowingEnabled: Bool
    private lazy var motion = MarkerMotionDriver(
        mode: routeFollowingEnabled ? MotionMode.RouteFollowing.shared : MotionMode.ChordOnly.shared,
        onFrame: { [weak self] poses in self?.applyAnnotationPoses(poses) },
        onRoute: { [weak self] markerId, points in self?.applyRemainingRoute(markerId: markerId, points: points) },
        onConnector: { [weak self] markerId, connector in self?.applyConnector(markerId: markerId, connector: connector) }
    )

    public init(styleURL: String, routeFollowingEnabled: Bool = false) {
        self.styleURL = styleURL
        self.routeFollowingEnabled = routeFollowingEnabled
        super.init()
    }

    public func createViewController() -> UIViewController {
        dispatchPrecondition(condition: .onQueue(.main))
        if mapView == nil {
            let mv = MLNMapView(frame: .zero, styleURL: URL(string: styleURL))
            mv.delegate = self
            mv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mv.automaticallyAdjustsContentInset = false
            mv.compassView.isHidden = true
            mv.showsAttributionButton = false
            mv.showsLogoView = false
            mv.isRotateEnabled = false
            mv.isPitchEnabled = false
            mv.minimumZoomLevel = MapConstants.shared.ZOOM_MIN
            mv.maximumZoomLevel = MapConstants.shared.ZOOM_MAX
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
            tap.require(toFail: mv.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer && ($0 as? UITapGestureRecognizer)?.numberOfTapsRequired == 2 }) ?? UITapGestureRecognizer())
            mv.addGestureRecognizer(tap)
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            mv.addGestureRecognizer(longPress)
            mapView = mv
            applyInteractionEnabled()
            applyPadding()
            renderUserLocation()
        }
        return MapHostViewController(mapSubview: mapView!)
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let mv = mapView else { return }
        let pt = gesture.location(in: mv)
        if let id = annotationIdAt(point: pt, in: mv) {
            listener?.onMarkerTapped(id: id)
        } else {
            let coord = mv.convert(pt, toCoordinateFrom: mv)
            listener?.onMapTapped(point: GeoPoint(lat: coord.latitude, lng: coord.longitude))
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let mv = mapView else { return }
        let pt = gesture.location(in: mv)
        let coord = mv.convert(pt, toCoordinateFrom: mv)
        listener?.onMapLongPressed(point: GeoPoint(lat: coord.latitude, lng: coord.longitude))
    }

    private func annotationIdAt(point: CGPoint, in mv: MLNMapView) -> String? {
        let hitRadius: CGFloat = 22
        for (id, annotation) in renderedAnnotations {
            let coord = annotation.coordinate
            let projected = mv.convert(coord, toPointTo: mv)
            let dx = projected.x - point.x
            let dy = projected.y - point.y
            if (dx * dx + dy * dy) <= hitRadius * hitRadius { return id }
        }
        return nil
    }

    public func setListener(listener: (any IosMapListener)?) {
        self.listener = listener
    }

    public func moveTo(target: GeoPoint, zoom: Float) {
        runOnMain {
            self.mapView?.setCenter(
                CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                zoomLevel: Double(self.clampZoom(zoom)),
                animated: false
            )
        }
    }

    public func animateTo(target: GeoPoint, zoom: Float, durationMs: Int32) {
        runOnMain {
            guard let mv = self.mapView else { return }
            self.animateCamera(to: target, zoom: zoom, heading: mv.camera.heading, durationMs: durationMs)
        }
    }

    public func animateToWithBearing(target: GeoPoint, bearing: Float, zoom: Float, durationMs: Int32) {
        runOnMain {
            self.animateCamera(to: target, zoom: zoom, heading: CLLocationDirection(bearing), durationMs: durationMs)
        }
    }

    private func animateCamera(to target: GeoPoint, zoom: Float, heading: CLLocationDirection, durationMs: Int32) {
        _ = durationMs
        guard let mv = mapView else { return }
        let center = CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng)
        mv.setCenter(center, zoomLevel: Double(clampZoom(zoom)), direction: heading, animated: true)
    }

    public func fitBounds(points: [GeoPoint], leftPt: Float, topPt: Float, rightPt: Float, bottomPt: Float, animate: Bool) {
        let valid = points.filter { $0.hasFix }
        guard !valid.isEmpty else { return }
        if valid.count == 1 {
            let single = valid[0]
            runOnMain {
                let zoom = Double(self.clampZoom(Float(self.mapView?.zoomLevel ?? 15)))
                self.mapView?.setCenter(
                    CLLocationCoordinate2D(latitude: single.lat, longitude: single.lng),
                    zoomLevel: zoom,
                    animated: animate
                )
            }
            return
        }
        runOnMain {
            guard let mv = self.mapView else { return }
            var coords = valid.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
            let baseMargin: CGFloat = 24
            let insets = UIEdgeInsets(
                top: CGFloat(topPt) + baseMargin,
                left: CGFloat(leftPt) + baseMargin,
                bottom: CGFloat(bottomPt) + baseMargin,
                right: CGFloat(rightPt) + baseMargin
            )
            let previousMax = mv.maximumZoomLevel
            mv.maximumZoomLevel = MapConstants.shared.FIT_ZOOM_MAX
            mv.setVisibleCoordinates(
                &coords,
                count: UInt(coords.count),
                edgePadding: insets,
                animated: animate
            )
            mv.maximumZoomLevel = previousMax
        }
    }

    public func zoomIn() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.setZoomLevel(Double(self.clampZoom(Float(mv.zoomLevel + 1))), animated: true)
        }
    }

    public func zoomOut() {
        runOnMain {
            guard let mv = self.mapView else { return }
            mv.setZoomLevel(Double(self.clampZoom(Float(mv.zoomLevel - 1))), animated: true)
        }
    }

    public func setZoom(zoom: Float) {
        runOnMain { self.mapView?.setZoomLevel(Double(self.clampZoom(zoom)), animated: true) }
    }

    public func setStyleUrl(url: String) {
        runOnMain {
            guard let parsed = URL(string: url) else { return }
            guard let mv = self.mapView else { return }
            if mv.styleURL == parsed { return }
            self.motion.clear()
            self.style = nil
            self.routeSources.removeAll()
            self.routeLayers.removeAll()
            self.connectorSources.removeAll()
            self.connectorLayers.removeAll()
            self.routeData.removeAll()
            if let annotations = mv.annotations { mv.removeAnnotations(annotations) }
            self.renderedAnnotations.removeAll()
            self.markerData.removeAll()
            self.markerImages.removeAll()
            self.sharedIconKeys.removeAll()
            self.sharedIconReuseIds.removeAll()
            self.followedRouteByMarker.removeAll()
            self.seededRoutePoints.removeAll()
            self.carAnnotationViews.removeAll()
            self.lastMarkerViewBearing = nil
            self.userLocationAnnotation = nil
            self.userLocationSource = nil
            self.userLocationLayer = nil
            mv.styleURL = parsed
        }
    }

    public func setStyleJson(json: String) {
    }

    public func setColorScheme(isDark: Bool) {
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

    public func setInteractionEnabled(enabled: Bool) {
        runOnMain {
            self.interactionEnabled = enabled
            self.applyInteractionEnabled()
        }
    }

    public func setMarkers(markers: [MapMarker]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingMarkers = markers
        if mapView != nil { renderMarkers(markers: markers) }
    }

    public func setRouteBindings(bindings: [String: String]) {
        dispatchPrecondition(condition: .onQueue(.main))
        guard routeBindings != bindings else { return }
        routeBindings = bindings
        if mapView != nil {
            for marker in markerData.values where marker.flat {
                applyFollowedRoute(markerId: marker.id, marker: marker)
            }
        }
    }

    public func setRoutes(routes: [MapRoute]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingRoutes = routes
        if mapView != nil { renderRoutes(routes: routes) }
    }

    public func setCircles(circles: [MapCircle]) {
        dispatchPrecondition(condition: .onQueue(.main))
        if !circles.isEmpty && !warnedCirclesUnsupported {
            warnedCirclesUnsupported = true
            NSLog("[YallaMaps] MapLibre does not support geographic circles; setCircles is a no-op.")
        }
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
        if let mv = mapView, let annotations = mv.annotations { mv.removeAnnotations(annotations) }
        if let style = style {
            routeLayers.values.forEach { style.removeLayer($0) }
            routeSources.values.forEach { style.removeSource($0) }
            connectorLayers.values.forEach { style.removeLayer($0) }
            connectorSources.values.forEach { style.removeSource($0) }
            if let layer = userLocationLayer { style.removeLayer(layer) }
            if let source = userLocationSource { style.removeSource(source) }
        }
        connectorLayers.removeAll()
        connectorSources.removeAll()
        userLocationAnnotation = nil
        userLocationLayer = nil
        userLocationSource = nil
        routeLayers.removeAll()
        routeSources.removeAll()
        renderedAnnotations.removeAll()
        markerImages.removeAll()
        sharedIconKeys.removeAll()
        sharedIconReuseIds.removeAll()
        followedRouteByMarker.removeAll()
        seededRoutePoints.removeAll()
        carAnnotationViews.removeAll()
        lastMarkerViewBearing = nil
        markerData.removeAll()
        routeData.removeAll()
        mapView?.delegate = nil
        mapView?.removeFromSuperview()
        mapView = nil
        style = nil
    }

    private func applyPadding() {
        guard let mv = mapView else { return }
        mv.contentInset = pendingPadding
    }

    private func applyInteractionEnabled() {
        guard let mv = mapView else { return }
        mv.isScrollEnabled = interactionEnabled
        mv.isZoomEnabled = interactionEnabled
        mv.isRotateEnabled = false
        mv.isPitchEnabled = false
    }

    private func clampZoom(_ zoom: Float) -> Float {
        return min(max(zoom, Float(MapConstants.shared.ZOOM_MIN)), Float(MapConstants.shared.ZOOM_MAX))
    }

    private func renderMarkers(markers: [MapMarker]) {
        guard let mv = mapView else { return }
        let incoming = Dictionary(uniqueKeysWithValues: markers.map { ($0.id, $0) })
        let stale = Set(renderedAnnotations.keys).filter { id in
            markerData[id] != nil && incoming[id] == nil
        }
        for id in stale {
            if let ann = renderedAnnotations.removeValue(forKey: id) { mv.removeAnnotation(ann) }
            markerData.removeValue(forKey: id)
            markerImages.removeValue(forKey: id)
            sharedIconKeys.removeValue(forKey: id)
            carAnnotationViews.removeValue(forKey: id)
            removeConnector(markerId: id)
            if followedRouteByMarker.removeValue(forKey: id) != nil {
                seededRoutePoints.removeValue(forKey: id)
                motion.setRoute(id: id, route: nil)
            }
        }
        for (id, marker) in incoming {
            let previous = markerData[id]
            if let icon = marker.icon {
                let key = sharedIconKey(for: icon)
                if !sharedIconReuseIds.contains(key) {
                    if let img = MapIconLoader.uiImage(for: icon) {
                        markerImages[key] = img
                        sharedIconReuseIds.insert(key)
                    }
                }
                sharedIconKeys[id] = key
            }
            if let existing = renderedAnnotations[id] {
                let moved = previous?.point != marker.point
                let motionChanged = moved || previous?.routeHeading != marker.routeHeading || previous?.rotation != marker.rotation
                if motionChanged {
                    if marker.flat {
                        motion.push(id: id, point: marker.point, routeHeading: marker.routeHeading?.floatValue, serverHeading: marker.rotation)
                    } else if moved {
                        existing.coordinate = CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng)
                    }
                }
                if previous?.contentDescription != marker.contentDescription {
                    existing.subtitle = marker.contentDescription
                }
                // A flat car keeps its live custom view across updates, so refresh its image in
                // place when the icon changes (the view is not rebuilt by viewFor: otherwise).
                if marker.flat, previous?.icon != marker.icon,
                   let carView = carAnnotationViews[id],
                   let key = sharedIconKeys[id], let image = markerImages[key] {
                    carView.setImage(image)
                }
            } else {
                let ann = MLNPointAnnotation()
                ann.coordinate = CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng)
                ann.title = id
                ann.subtitle = marker.contentDescription
                mv.addAnnotation(ann)
                renderedAnnotations[id] = ann
                if marker.flat { motion.push(id: id, point: marker.point, routeHeading: marker.routeHeading?.floatValue, serverHeading: marker.rotation) }
            }
            if marker.flat { applyFollowedRoute(markerId: id, marker: marker) }
            markerData[id] = marker
        }
        motion.retain(ids: Set(incoming.values.filter { $0.flat }.map { $0.id }))
        motion.ensureRunning()
    }

    private func applyAnnotationPoses(_ poses: [String: Pose]) {
        let cameraBearing = mapView?.camera.heading ?? 0
        for (id, pose) in poses {
            renderedAnnotations[id]?.coordinate = CLLocationCoordinate2D(latitude: pose.point.lat, longitude: pose.point.lng)
            // Flat (car) markers carry a custom rotatable view; static pins ignore heading.
            if let carView = carAnnotationViews[id] {
                carView.setWorldHeading(CLLocationDirection(pose.bearing))
                carView.applyRotation(cameraBearing: cameraBearing)
            }
        }
    }

    /// Re-compensates every live car view's rotation for the current map bearing, so each car
    /// keeps pointing along its world heading as the map rotates. Mirrors the colleagues'
    /// `refreshAllMarkerViewRotations`; gated on a bearing-change epsilon to avoid churn.
    private func refreshCarViewRotations() {
        guard let bearing = mapView?.camera.heading else { return }
        if let last = lastMarkerViewBearing, abs(bearing - last) <= 0.0001 { return }
        lastMarkerViewBearing = bearing
        for carView in carAnnotationViews.values {
            carView.applyRotation(cameraBearing: bearing)
        }
    }

    /// Resolves the route a marker follows: a `setRouteBindings` entry wins over the deprecated
    /// `MapMarker.followsRouteId` field, which remains a fallback for callers not yet migrated.
    private func followedRouteId(for marker: MapMarker) -> String? {
        return routeBindings[marker.id] ?? marker.followsRouteId
    }

    /// Glues a flat car marker to the route it follows, or detaches it when the binding (or
    /// geometry) is gone/changed. Points come from the matching `MapRoute`. The followed route id
    /// is resolved binding-first (see ``followedRouteId(for:)``).
    private func applyFollowedRoute(markerId: String, marker: MapMarker) {
        guard let routeId = followedRouteId(for: marker),
              let route = routeData[routeId] ?? pendingRoutes.first(where: { $0.id == routeId }) else {
            if followedRouteByMarker.removeValue(forKey: markerId) != nil {
                seededRoutePoints.removeValue(forKey: markerId)
                motion.setRoute(id: markerId, route: nil)
            }
            return
        }
        followedRouteByMarker[markerId] = routeId
        if !Self.pointsEqual(seededRoutePoints[markerId], route.points) {
            seededRoutePoints[markerId] = route.points
            motion.setRoute(id: markerId, route: route.points)
        }
    }

    /// Writes the trimmed remaining route back onto the followed line layer so it visibly shrinks
    /// behind the car as it advances.
    private func applyRemainingRoute(markerId: String, points: [GeoPoint]) {
        guard let routeId = followedRouteByMarker[markerId],
              let source = routeSources[routeId] else { return }
        if points.count < 2 {
            // Arrived (or degenerate): collapse the line to nothing rather than leaving a stub.
            source.shape = nil
            return
        }
        var coords = points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
        source.shape = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
    }

    /// Draws (or tears down) the honesty connector — a short line from the driver's raw GPS fix to
    /// the snapped point the car is rendered at — handed verbatim by the motion model. A nil
    /// connector (on the line / off-route chord fallback / route mode off) removes the line. The
    /// renderer never computes the connector; it only draws what the model emits.
    private func applyConnector(markerId: String, connector: RouteConnector?) {
        guard let style = style else { return }
        guard let connector = connector else {
            removeConnector(markerId: markerId)
            return
        }
        var coords = [
            CLLocationCoordinate2D(latitude: connector.rawPoint.lat, longitude: connector.rawPoint.lng),
            CLLocationCoordinate2D(latitude: connector.snappedPoint.lat, longitude: connector.snappedPoint.lng)
        ]
        let feature = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
        if let source = connectorSources[markerId] {
            source.shape = feature
        } else {
            let source = MLNShapeSource(identifier: "yalla-connector-src-\(markerId)", shape: feature, options: nil)
            style.addSource(source)
            let layer = MLNLineStyleLayer(identifier: "yalla-connector-lyr-\(markerId)", source: source)
            layer.lineCap = NSExpression(forConstantValue: "round")
            layer.lineColor = NSExpression(forConstantValue: UIColor(argb: MapConnectorStyle.colorArgb))
            layer.lineWidth = NSExpression(forConstantValue: MapConnectorStyle.widthDp)
            layer.lineDashPattern = NSExpression(forConstantValue: MapConnectorStyle.dashLengthsPt)
            style.addLayer(layer)
            connectorSources[markerId] = source
            connectorLayers[markerId] = layer
        }
    }

    private func removeConnector(markerId: String) {
        if let layer = connectorLayers.removeValue(forKey: markerId) { style?.removeLayer(layer) }
        if let source = connectorSources.removeValue(forKey: markerId) { style?.removeSource(source) }
    }

    private static func pointsEqual(_ a: [GeoPoint]?, _ b: [GeoPoint]) -> Bool {
        guard let a = a, a.count == b.count else { return false }
        for i in 0..<a.count {
            if abs(a[i].lat - b[i].lat) > 1e-7 || abs(a[i].lng - b[i].lng) > 1e-7 { return false }
        }
        return true
    }

    private func renderRoutes(routes: [MapRoute]) {
        guard let style = style else { return }
        let incoming = Dictionary(uniqueKeysWithValues: routes.map { ($0.id, $0) })
        let routeKeys = Set(routeData.keys)
        let stale = routeKeys.subtracting(incoming.keys)
        for id in stale {
            if let layer = routeLayers.removeValue(forKey: id) { style.removeLayer(layer) }
            if let source = routeSources.removeValue(forKey: id) { style.removeSource(source) }
            routeData.removeValue(forKey: id)
        }
        for (id, route) in incoming {
            let previous = routeData[id]
            let pointsChanged = !Self.pointsEqual(previous?.points, route.points)
            if let source = routeSources[id] {
                if pointsChanged {
                    var coords = route.points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
                    source.shape = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
                }
                if let layer = routeLayers[id] {
                    if previous?.colorArgb != route.colorArgb {
                        layer.lineColor = NSExpression(forConstantValue: UIColor(argb: route.colorArgb))
                    }
                    if previous?.widthDp != route.widthDp {
                        layer.lineWidth = NSExpression(forConstantValue: route.widthDp)
                    }
                }
            } else {
                var coords = route.points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
                let polyline = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
                let sourceId = "yalla-route-src-\(id)"
                let layerId = "yalla-route-lyr-\(id)"
                let source = MLNShapeSource(identifier: sourceId, shape: polyline, options: nil)
                style.addSource(source)
                let layer = MLNLineStyleLayer(identifier: layerId, source: source)
                layer.lineCap = NSExpression(forConstantValue: "round")
                layer.lineJoin = NSExpression(forConstantValue: "round")
                layer.lineColor = NSExpression(forConstantValue: UIColor(argb: route.colorArgb))
                layer.lineWidth = NSExpression(forConstantValue: route.widthDp)
                if let firstSymbol = style.layers.first(where: { $0 is MLNSymbolStyleLayer }) {
                    style.insertLayer(layer, below: firstSymbol)
                } else {
                    style.addLayer(layer)
                }
                routeSources[id] = source
                routeLayers[id] = layer
            }
            routeData[id] = route
        }
        reseedFollowedRoutes()
    }

    /// Re-seeds the motion model for any flat marker whose followed route geometry changed since
    /// it was last seeded, so a route refetch arriving without a marker update still trims the
    /// right line layer (setRoute re-projects, so the car does not jump).
    private func reseedFollowedRoutes() {
        for (markerId, routeId) in followedRouteByMarker {
            guard let points = routeData[routeId]?.points else { continue }
            if !Self.pointsEqual(seededRoutePoints[markerId], points) {
                seededRoutePoints[markerId] = points
                motion.setRoute(id: markerId, route: points)
            }
        }
    }

    private func renderUserLocation() {
        guard let mv = mapView else { return }
        guard let point = pendingUserLocation else {
            if let annotation = userLocationAnnotation { mv.removeAnnotation(annotation) }
            userLocationAnnotation = nil
            if let style = style {
                if let layer = userLocationLayer { style.removeLayer(layer) }
                if let source = userLocationSource { style.removeSource(source) }
            }
            userLocationLayer = nil
            userLocationSource = nil
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: point.lat, longitude: point.lng)
        if let annotation = userLocationAnnotation {
            annotation.coordinate = coordinate
        } else {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = coordinate
            userLocationAnnotation = annotation
            mv.addAnnotation(annotation)
        }
        guard let style = style else { return }
        let feature = MLNPointFeature()
        feature.coordinate = coordinate
        let radiusAtZoomZero = 50.0 / (156543.03392 * cos(point.lat * .pi / 180.0))
        let stops: [NSNumber: NSNumber] = [
            0: NSNumber(value: radiusAtZoomZero),
            22: NSNumber(value: radiusAtZoomZero * 4194304.0)
        ]
        let radiusExpression = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'exponential', 2, %@)", stops)
        if let source = userLocationSource {
            source.shape = feature
            userLocationLayer?.circleRadius = radiusExpression
        } else {
            let source = MLNShapeSource(identifier: "yalla-user-location-src", shape: feature, options: nil)
            style.addSource(source)
            let layer = MLNCircleStyleLayer(identifier: "yalla-user-location-lyr", source: source)
            layer.circleRadius = radiusExpression
            layer.circleColor = NSExpression(forConstantValue: UIColor(argb: 0x33562DF8 as Int32))
            layer.circleStrokeColor = NSExpression(forConstantValue: UIColor(argb: 0x66562DF8 as Int32))
            layer.circleStrokeWidth = NSExpression(forConstantValue: 1)
            style.addLayer(layer)
            userLocationSource = source
            userLocationLayer = layer
        }
    }

    public func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        self.style = style
        renderMarkers(markers: pendingMarkers)
        renderRoutes(routes: pendingRoutes)
        renderUserLocation()
        listener?.onReady()
    }

    public func mapView(_ mapView: MLNMapView, regionWillChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        userInitiatedMove = reason.contains(.gesturePan) ||
            reason.contains(.gesturePinch) ||
            reason.contains(.gestureRotate) ||
            reason.contains(.gestureTilt) ||
            reason.contains(.gestureZoomIn) ||
            reason.contains(.gestureZoomOut)
    }

    public func mapView(_ mapView: MLNMapView, regionIsChangingWith reason: MLNCameraChangeReason) {
        refreshCarViewRotations()
        let center = mapView.centerCoordinate
        if let prev = lastEmittedCenter, centerEpsilonEqual(prev, center) { return }
        lastEmittedCenter = center
        let geo = GeoPoint(lat: center.latitude, lng: center.longitude)
        listener?.onCameraMove(
            target: geo,
            zoom: Float(mapView.zoomLevel),
            bearing: Float(mapView.direction),
            tilt: Float(mapView.camera.pitch),
            isByUser: userInitiatedMove
        )
    }

    public func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        refreshCarViewRotations()
        let center = mapView.centerCoordinate
        lastEmittedCenter = center
        let geo = GeoPoint(lat: center.latitude, lng: center.longitude)
        listener?.onCameraIdle(
            target: geo,
            zoom: Float(mapView.zoomLevel),
            bearing: Float(mapView.direction),
            tilt: Float(mapView.camera.pitch),
            isByUser: userInitiatedMove
        )
        userInitiatedMove = false
    }

    public func mapView(_ mapView: MLNMapView, imageFor annotation: MLNAnnotation) -> MLNAnnotationImage? {
        if let pointAnnotation = annotation as? MLNPointAnnotation, pointAnnotation === userLocationAnnotation {
            if let cached = mapView.dequeueReusableAnnotationImage(withIdentifier: "yalla-user-location-dot") { return cached }
            return MLNAnnotationImage(image: MapIconLoader.userLocationDotImage, reuseIdentifier: "yalla-user-location-dot")
        }
        guard let id = annotation.title.flatMap({ $0 }) else { return nil }
        // Flat (car) markers are rendered through a rotatable custom view (see viewFor:); only the
        // static, upright pins go through the image path.
        if markerData[id]?.flat == true { return nil }
        guard let sharedKey = sharedIconKeys[id], let image = markerImages[sharedKey] else { return nil }
        if let cached = mapView.dequeueReusableAnnotationImage(withIdentifier: sharedKey) { return cached }
        return MLNAnnotationImage(image: image, reuseIdentifier: sharedKey)
    }

    /// Returns a rotatable custom view ONLY for flat (car) markers; everything else returns nil so
    /// MapLibre falls back to the upright `imageFor:` path. The view hosts the marker's image
    /// centered so rotation pivots about the car's middle, and is seeded with the current pose /
    /// camera bearing so it appears already oriented on first display.
    public func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
        if let pointAnnotation = annotation as? MLNPointAnnotation, pointAnnotation === userLocationAnnotation {
            return nil
        }
        guard let id = annotation.title.flatMap({ $0 }), markerData[id]?.flat == true else { return nil }
        guard let sharedKey = sharedIconKeys[id], let image = markerImages[sharedKey] else { return nil }
        let reuseId = "yalla-car-\(sharedKey)"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? LibreCarAnnotationView)
            ?? LibreCarAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        view.setImage(image)
        carAnnotationViews[id] = view
        // Seed orientation from the current marker heading and camera so the car is not briefly
        // upright before the next motion frame.
        let heading = CLLocationDirection(markerData[id]?.rotation ?? 0)
        view.setWorldHeading(heading)
        view.applyRotation(cameraBearing: mapView.camera.heading)
        return view
    }

    private func sharedIconKey(for icon: MapMarkerIcon) -> String {
        if let res = icon as? MapMarkerIcon.Resource { return "yalla-icon-res-\(res.name)" }
        if let pin = icon as? MapMarkerIcon.Pin {
            return "yalla-icon-pin-\(pin.colorArgb)-\(pin.label ?? "")"
        }
        if let bytes = icon as? MapMarkerIcon.Bytes {
            return "yalla-icon-bytes-\(MapIconLoader.bytesDigest(bytes.data))"
        }
        if let dot = icon as? MapMarkerIcon.Dot {
            return "yalla-icon-dot-\(dot.fillColorArgb)-\(dot.strokeColorArgb)-\(dot.diameterDp)-\(dot.strokeWidthDp)"
        }
        return "yalla-icon-unknown"
    }

    func centerEpsilonEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        return abs(a.latitude - b.latitude) < MapEpsilon.positionDegrees &&
            abs(a.longitude - b.longitude) < MapEpsilon.positionDegrees
    }
}
