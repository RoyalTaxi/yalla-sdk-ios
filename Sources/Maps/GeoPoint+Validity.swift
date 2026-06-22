import YallaComponents

extension GeoPoint {
    var hasFix: Bool {
        !(lat == 0 && lng == 0)
    }
}
