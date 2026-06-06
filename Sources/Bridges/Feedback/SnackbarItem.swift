import Foundation

struct SnackbarItem {
    let id: UUID
    let message: String
    let isError: Bool

    init(message: String, isError: Bool) {
        self.id = UUID()
        self.message = message
        self.isError = isError
    }
}
