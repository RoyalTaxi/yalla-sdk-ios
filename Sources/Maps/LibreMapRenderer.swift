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
    private var pendingRoutes: [MapRoute] = []
    private var pendingPadding = UIEdgeInsets.zero
    private var lastEmittedCenter: CLLocationCoordinate2D?
    private var warnedCirclesUnsupported = false
    private var warnedRotationUnsupported = false
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
    private var userInitiatedMove = false
    private lazy var motion = MarkerMotionDriver { [weak self] poses in self?.applyAnnotationPoses(poses) }

    public init(styleURL: String) {
        self.styleURL = styleURL
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
            let cam = MLNMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                altitude: mv.camera.altitude,
                pitch: mv.camera.pitch,
                heading: mv.camera.heading
            )
            mv.setZoomLevel(Double(self.clampZoom(zoom)), animated: false)
            mv.setCamera(cam, withDuration: Double(durationMs) / 1000.0, animationTimingFunction: nil)
        }
    }

    public func animateToWithBearing(target: GeoPoint, bearing: Float, zoom: Float, durationMs: Int32) {
        runOnMain {
            guard let mv = self.mapView else { return }
            let cam = MLNMapCamera(
                lookingAtCenter: CLLocationCoordinate2D(latitude: target.lat, longitude: target.lng),
                altitude: mv.camera.altitude,
                pitch: mv.camera.pitch,
                heading: CLLocationDirection(bearing)
            )
            mv.setZoomLevel(Double(self.clampZoom(zoom)), animated: false)
            mv.setCamera(cam, withDuration: Double(durationMs) / 1000.0, animationTimingFunction: nil)
        }
    }

    public func fitBounds(points: [GeoPoint], leftPt: Float, topPt: Float, rightPt: Float, bottomPt: Float, animate: Bool) {
        let valid = points.filter { $0.lat != 0 || $0.lng != 0 }
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
            self.routeData.removeAll()
            if let annotations = mv.annotations { mv.removeAnnotations(annotations) }
            self.renderedAnnotations.removeAll()
            self.markerData.removeAll()
            self.markerImages.removeAll()
            self.sharedIconKeys.removeAll()
            self.sharedIconReuseIds.removeAll()
            self.userLocationAnnotation = nil
            self.userLocationSource = nil
            self.userLocationLayer = nil
            mv.styleURL = parsed
        }
    }

    public func setStyleJson(json: String) {
        // MapLibre iOS accepts JSON via MLNStyle.styleJSON — but routing is rare in practice; ignore.
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

    public func setRoutes(routes: [MapRoute]) {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingRoutes = routes
        if mapView != nil { renderRoutes(routes: routes) }
    }

    public func setCircles(circles: [MapCircle]) {
        dispatchPrecondition(condition: .onQueue(.main))
        if !circles.isEmpty && !warnedCirclesUnsupported {
            warnedCirclesUnsupported = true
            NSLog("[YallaMaps] MapLibre does not support geographic circles; setCircles is a no-op. MapCapabilities.LIBRE.supportsCircles = false.")
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
            if let layer = userLocationLayer { style.removeLayer(layer) }
            if let source = userLocationSource { style.removeSource(source) }
        }
        userLocationAnnotation = nil
        userLocationLayer = nil
        userLocationSource = nil
        routeLayers.removeAll()
        routeSources.removeAll()
        renderedAnnotations.removeAll()
        markerImages.removeAll()
        sharedIconKeys.removeAll()
        sharedIconReuseIds.removeAll()
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
                if previous?.point != marker.point {
                    if marker.flat {
                        motion.push(id: id, point: marker.point, routeHeading: marker.routeHeading?.floatValue, serverHeading: marker.rotation)
                    } else {
                        existing.coordinate = CLLocationCoordinate2D(latitude: marker.point.lat, longitude: marker.point.lng)
                    }
                }
                if previous?.contentDescription != marker.contentDescription {
                    existing.subtitle = marker.contentDescription
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
            markerData[id] = marker
        }
        motion.retain(ids: Set(incoming.values.filter { $0.flat }.map { $0.id }))
        motion.ensureRunning()
    }

    private func applyAnnotationPoses(_ poses: [String: Pose]) {
        if !poses.isEmpty && !warnedRotationUnsupported {
            warnedRotationUnsupported = true
            NSLog("[YallaMaps] MapLibre-iOS MLNPointAnnotation cannot rotate; car markers glide position-only and drop Pose.bearing until the MLNSymbolStyleLayer rewrite (YLL-798 P1-3).")
        }
        for (id, pose) in poses {
            renderedAnnotations[id]?.coordinate = CLLocationCoordinate2D(latitude: pose.point.lat, longitude: pose.point.lng)
        }
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
            var coords = route.points.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lng) }
            let polyline = MLNPolylineFeature(coordinates: &coords, count: UInt(coords.count))
            if let source = routeSources[id] {
                source.shape = polyline
                if let layer = routeLayers[id] {
                    if previous?.colorArgb != route.colorArgb {
                        layer.lineColor = NSExpression(forConstantValue: UIColor(argb: route.colorArgb))
                    }
                    if previous?.widthDp != route.widthDp {
                        layer.lineWidth = NSExpression(forConstantValue: route.widthDp)
                    }
                }
            } else {
                let sourceId = "yalla-route-src-\(id)"
                let layerId = "yalla-route-lyr-\(id)"
                let source = MLNShapeSource(identifier: sourceId, shape: polyline, options: nil)
                style.addSource(source)
                let layer = MLNLineStyleLayer(identifier: layerId, source: source)
                layer.lineCap = NSExpression(forConstantValue: "round")
                layer.lineJoin = NSExpression(forConstantValue: "round")
                layer.lineColor = NSExpression(forConstantValue: UIColor(argb: route.colorArgb))
                layer.lineWidth = NSExpression(forConstantValue: route.widthDp)
                style.addLayer(layer)
                routeSources[id] = source
                routeLayers[id] = layer
            }
            routeData[id] = route
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
            mv.addAnnotation(annotation)
            userLocationAnnotation = annotation
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
            layer.circleColor = NSExpression(forConstantValue: UIColor(argb: 0x33562DF8))
            layer.circleStrokeColor = NSExpression(forConstantValue: UIColor(argb: 0x66562DF8))
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
        guard let sharedKey = sharedIconKeys[id], let image = markerImages[sharedKey] else { return nil }
        if let cached = mapView.dequeueReusableAnnotationImage(withIdentifier: sharedKey) { return cached }
        return MLNAnnotationImage(image: image, reuseIdentifier: sharedKey)
    }

    private func sharedIconKey(for icon: MapMarkerIcon) -> String {
        if let res = icon as? MapMarkerIcon.Resource { return "yalla-icon-res-\(res.name)" }
        if let pin = icon as? MapMarkerIcon.Pin {
            return "yalla-icon-pin-\(pin.colorArgb)-\(pin.label ?? "")"
        }
        if let bytes = icon as? MapMarkerIcon.Bytes {
            return "yalla-icon-bytes-\(bytes.data.hashValue)"
        }
        if let dot = icon as? MapMarkerIcon.Dot {
            return "yalla-icon-dot-\(dot.fillColorArgb)-\(dot.strokeColorArgb)-\(dot.diameterDp)-\(dot.strokeWidthDp)"
        }
        return "yalla-icon-unknown"
    }

    private func centerEpsilonEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        return abs(a.latitude - b.latitude) < 1e-6 && abs(a.longitude - b.longitude) < 1e-6
    }
}
