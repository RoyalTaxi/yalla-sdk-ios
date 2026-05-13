import XCTest
@testable import YallaSDKIOS

final class YallaSDKIOSTests: XCTestCase {
    func testExposesModuleName() {
        XCTAssertEqual(YallaSDKIOS.moduleName, "YallaSDKIOS")
    }
}
