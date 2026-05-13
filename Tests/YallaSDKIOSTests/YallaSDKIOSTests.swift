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

    func testBundlesGeneratedAssets() {
        XCTAssertNotNil(YallaResourcesIOS.drawableURL("img_logo_splash"))
        XCTAssertNotNil(YallaResourcesIOS.drawableURL("img_logo_splash.png"))
        XCTAssertNotNil(YallaResourcesIOS.fontURL("inter_regular"))
        XCTAssertNotNil(YallaResourcesIOS.fontURL("inter_regular.ttf"))
        XCTAssertNotNil(
            YallaResourcesIOS.fileURL(
                "lottie_order_search",
                withExtension: "json"
            )
        )
    }
}
