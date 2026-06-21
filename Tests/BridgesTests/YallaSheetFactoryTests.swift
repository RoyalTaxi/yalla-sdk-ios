import UIKit
import XCTest
@testable import Bridges

/// Pins the sheet handle's `viewController` stability contract (review H1/H2).
///
/// The Kotlin `onFullyExpanded` poll reads `handle.viewController.isBeingPresented()` live, and the
/// handle's `viewController` is a stored value set once at construction. The fix removed the
/// recreate-on-re-present behavior so the wrapper — and thus the value handed to the handle — stays
/// the same live instance for the controller's lifetime. These tests fail if the factory ever again
/// hands the handle a controller it later swaps out from under it.
///
/// Note: exercising an actual dismiss→re-show re-present requires a presented window, which is not
/// available in headless CI; these pin the construction-time contract the re-present fix preserves.
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
        // The handle must expose the native sheet wrapper, never the raw Compose content controller —
        // and that wrapper is the stable instance the re-present fix preserves.
        XCTAssertTrue(handle.viewController is ShellSheetController)
        XCTAssertFalse(handle.viewController === content)
    }
}
