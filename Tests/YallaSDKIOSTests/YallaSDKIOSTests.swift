import XCTest
@testable import YallaSDKIOS
import YallaDesignIOS
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
        XCTAssertEqual(YallaResourcesIOS.imageAssetName("img_logo_splash.png"), "img_logo_splash")
        XCTAssertNotNil(YallaResourcesIOS.platformImage("img_logo_splash"))
        XCTAssertNotNil(YallaResourcesIOS.fontURL("inter_regular"))
        XCTAssertNotNil(YallaResourcesIOS.fontURL("inter_regular.ttf"))
        XCTAssertNotNil(
            YallaResourcesIOS.fileURL(
                "lottie_order_search",
                withExtension: "json"
            )
        )
    }

    func testGeneratedDesignAccessors() {
        XCTAssertEqual(YallaThemedImage.login.assetName, "yalla_img_login")
        XCTAssertNotNil(
            YallaResourcesIOS.bundle.url(
                forResource: "Contents",
                withExtension: "json",
                subdirectory: "YallaImages.xcassets/yalla_img_login.imageset"
            )
        )
        XCTAssertEqual(YallaTypography.Body.Base.regular.fontResourceName, "sfpro_normal")
        XCTAssertEqual(YallaTypography.Custom.carNumber.fontResourceName, "nummernschild")
    }
}
