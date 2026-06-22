import UIKit
import XCTest
@testable import Bridges

final class UIColorArgbTests: XCTestCase {
    private func channels(_ color: UIColor) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    func testOpaqueRedDecodesToFullRed() {
        let (r, g, b, a) = channels(UIColor(argb: 0xFFFF0000))
        XCTAssertEqual(r, 1, accuracy: 0.001)
        XCTAssertEqual(g, 0, accuracy: 0.001)
        XCTAssertEqual(b, 0, accuracy: 0.001)
        XCTAssertEqual(a, 1, accuracy: 0.001)
    }

    func testChannelOrderIsArgb() {
        let (r, g, b, a) = channels(UIColor(argb: 0x80102030))
        XCTAssertEqual(a, CGFloat(0x80) / 255, accuracy: 0.001)
        XCTAssertEqual(r, CGFloat(0x10) / 255, accuracy: 0.001)
        XCTAssertEqual(g, CGFloat(0x20) / 255, accuracy: 0.001)
        XCTAssertEqual(b, CGFloat(0x30) / 255, accuracy: 0.001)
    }

    func testFullyTransparentDecodesWithZeroAlpha() {
        let (_, _, _, a) = channels(UIColor(argb: 0x00FFFFFF))
        XCTAssertEqual(a, 0, accuracy: 0.001)
    }
}
