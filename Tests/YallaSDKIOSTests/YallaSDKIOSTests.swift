import XCTest
@testable import YallaSDKIOS
import YallaResourcesIOS

final class YallaSDKIOSTests: XCTestCase {
    func testExposesModuleName() {
        XCTAssertEqual(YallaSDKIOS.moduleName, "YallaSDKIOS")
    }

    func testBundlesGeneratedStringCatalog() {
        XCTAssertNotNil(
            YallaResourcesIOS.bundle.url(
                forResource: "Localizable",
                withExtension: "xcstrings"
            )
        )
    }

    func testBundlesGeneratedIcons() {
        XCTAssertNotNil(YallaResourcesIOS.iconURL("ic_x"))
        XCTAssertNotNil(YallaResourcesIOS.iconURL("ic_x.svg"))
    }
}
