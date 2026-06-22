import XCTest
import YallaComponents
@testable import Maps

final class MapIconLoaderTests: XCTestCase {

    private func makeArray(_ bytes: [Int8]) -> KotlinByteArray {
        let array = KotlinByteArray(size: Int32(bytes.count))
        for (i, b) in bytes.enumerated() {
            array.set(index: Int32(i), value: b)
        }
        return array
    }

    func testSamePayloadProducesSameDigest() {
        let a = makeArray([1, 2, 3, 4, 5])
        let b = makeArray([1, 2, 3, 4, 5])
        XCTAssertEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testDifferentPayloadsProduceDifferentDigests() {
        let a = makeArray([1, 2, 3, 4, 5])
        let b = makeArray([1, 2, 3, 4, 6])
        XCTAssertNotEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testDifferentLengthSamePrefixDiffers() {
        let a = makeArray([1, 2, 3])
        let b = makeArray([1, 2, 3, 0])
        XCTAssertNotEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testReorderedBytesDiffer() {
        let a = makeArray([1, 2, 3, 4])
        let b = makeArray([4, 3, 2, 1])
        XCTAssertNotEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testEmptyPayloadIsStable() {
        XCTAssertEqual(MapIconLoader.bytesDigest(makeArray([])), MapIconLoader.bytesDigest(makeArray([])))
    }
}
