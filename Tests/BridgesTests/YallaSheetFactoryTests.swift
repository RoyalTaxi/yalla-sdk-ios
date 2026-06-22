import UIKit
import XCTest
@testable import Bridges

@MainActor
final class YallaSheetFactoryTests: XCTestCase {
    func testContentHandleExposesTheEmbeddedSheetController() {
        let factory = YallaSheetFactory()
        let content = UIViewController()
        let handle = factory.createContent(
            fullHeight: false,
            sheetSwipeEnabled: true,
            title: "Title",
            showClose: true,
            contentController: content,
            onClose: nil,
            onDismissRequest: {}
        )
        XCTAssertTrue(handle.viewController is Sheet, "the handle must expose the native sheet wrapper")
    }

    func testShellHandleExposesWrapperNotTheRawContentController() {
        let factory = YallaSheetFactory()
        let content = UIViewController()
        let handle = factory.createShell(
            fullHeight: false,
            sheetSwipeEnabled: true,
            contentController: content,
            onDismissRequest: {}
        )
        XCTAssertTrue(handle.viewController is ShellSheetController)
        XCTAssertFalse(handle.viewController === content)
    }
}
