import XCTest
import YallaComponents
@testable import Maps

/// Pins the Bytes-icon cache-key content digest (review #6). The key must be derived from the byte
/// CONTENT (so the same payload yields a stable key and two different payloads never collide), not from
/// `KotlinByteArray.hashValue` which is identity/address-derived — unstable across runs and collidable,
/// causing the wrong cached bitmap to be served.
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
        // A naive sum/length-only key could collide these; the digest must not.
        let a = makeArray([1, 2, 3])
        let b = makeArray([1, 2, 3, 0])
        XCTAssertNotEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testReorderedBytesDiffer() {
        // Order matters: a content hash must distinguish permutations of the same multiset.
        let a = makeArray([1, 2, 3, 4])
        let b = makeArray([4, 3, 2, 1])
        XCTAssertNotEqual(MapIconLoader.bytesDigest(a), MapIconLoader.bytesDigest(b))
    }

    func testEmptyPayloadIsStable() {
        XCTAssertEqual(MapIconLoader.bytesDigest(makeArray([])), MapIconLoader.bytesDigest(makeArray([])))
    }
}
