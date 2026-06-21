import Foundation

/// Runs `work` on the main thread, inline if already there, otherwise hopped asynchronously.
///
/// Every native renderer in this layer mutates UIKit, which is main-thread-only. The Compose↔native
/// bridge invokes the handle closures from Kotlin on the main thread today, but that contract is not
/// enforceable from the Kotlin side, so the bridge owns it defensively: every handle closure and
/// every factory entry point routes through here. Running inline when already on main keeps the
/// common path synchronous (no needless frame deferral); the async hop only engages off-main.
func onMain(_ work: @escaping () -> Void) {
    if Thread.isMainThread {
        work()
    } else {
        DispatchQueue.main.async(execute: work)
    }
}
