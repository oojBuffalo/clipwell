import Combine
import Foundation

@MainActor
final class PanelSession: ObservableObject {
    enum Screen { case history, shortcuts, confirmClear }
    enum Command { case move(Int), copy, pin, focusSearch }

    @Published var screen = Screen.history
    @Published var query = ""
    @Published var pinnedOnly = false
    @Published var selection: UUID?
    @Published var unavailableShortcuts: [String] = []
    let commands = PassthroughSubject<Command, Never>()

    func reset() {
        screen = .history
        pinnedOnly = false
        query = ""
        selection = nil
        focusSearch()
    }

    func goBack() -> Bool {
        guard screen != .history else { return false }
        screen = .history
        focusSearch()
        return true
    }

    func moveSelection(_ delta: Int) { commands.send(.move(delta)) }
    func activateSelection() { commands.send(.copy) }
    func togglePinSelection() { commands.send(.pin) }
    func focusSearch() { commands.send(.focusSearch) }

    func setFilter(_ pinned: Bool) {
        screen = .history
        pinnedOnly = pinned
        selection = nil
    }
}
