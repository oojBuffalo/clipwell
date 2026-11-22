import SwiftUI

struct HistoryEmptyView: View {
    let isSearching: Bool
    let pinnedOnly: Bool
    let isPaused: Bool

    private var title: String {
        if isSearching { return "No matching clips" }
        if pinnedOnly { return "No pinned clips" }
        if isPaused { return "History is paused" }
        return "No clips yet"
    }

    private var detail: String {
        if isSearching { return "Try a different search." }
        if pinnedOnly { return "Select a clip and press ⌘P to pin it." }
        if isPaused { return "Click Paused to resume capture." }
        return "Copy text in any app to see it here."
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.headline)
            Text(detail).font(.callout).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
