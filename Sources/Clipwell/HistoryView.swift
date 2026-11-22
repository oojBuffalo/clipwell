import SwiftUI

struct HistoryView: View {
    static let panelSize = CGSize(width: 368, height: 354)

    @ObservedObject var store: HistoryStore
    @ObservedObject var session: PanelSession
    let dismiss: () -> Void
    let quit: () -> Void

    @FocusState private var searchFocused: Bool
    @State private var copyFailed = false

    private var visibleEntries: [ClipEntry] {
        let search = session.query.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.entries.filter { entry in
            (!session.pinnedOnly || entry.isPinned) &&
            (search.isEmpty || entry.text.localizedStandardContains(search))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            switch session.screen {
            case .history:
                toolbar
                Divider()
                historyList
                if copyFailed {
                    Text("Couldn’t copy. Try again.")
                        .font(.callout)
                        .padding(6)
                }
            case .shortcuts:
                ShortcutGuide(unavailable: session.unavailableShortcuts) { _ = session.goBack() }
            case .confirmClear:
                clearConfirmation
            }
        }
        .frame(width: Self.panelSize.width, height: Self.panelSize.height)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay {
            RoundedRectangle(cornerRadius: 11)
                .strokeBorder(.quaternary, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .onReceive(session.commands, perform: handle)
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(session.pinnedOnly ? "Search pinned clips" : "Search clips", text: $session.query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
            if !session.query.isEmpty {
                Button {
                    session.query = ""
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Clear search")
            }
            if store.isPaused {
                Button("Paused", action: store.togglePause)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .help("Resume clipboard history")
                    .accessibilityHint("Resumes clipboard history")
            }
            Button { session.setFilter(!session.pinnedOnly) } label: {
                Image(systemName: session.pinnedOnly ? "pin.fill" : "pin")
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(session.pinnedOnly ? .primary : .secondary)
            .accessibilityLabel("Pinned clips only")
            .accessibilityAddTraits(session.pinnedOnly ? .isSelected : [])
            .help(session.pinnedOnly ? "Show all clips (⌘1)" : "Show pinned clips (⌘2)")
            Menu {
                Button("Keyboard Shortcuts") { session.screen = .shortcuts }
                Button(store.isPaused ? "Resume History" : "Pause History", action: store.togglePause)
                Button("Clear Unpinned History…") { session.screen = .confirmClear }
                    .disabled(!store.entries.contains { !$0.isPinned })
                Divider()
                Button("Quit Clipwell", action: quit)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .foregroundStyle(.secondary)
            .fixedSize()
            .accessibilityLabel("More options")
            .help("More options")
        }
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .frame(height: 44)
    }

    @ViewBuilder private var historyList: some View {
        let entries = visibleEntries
        if entries.isEmpty {
            HistoryEmptyView(isSearching: !session.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                             pinnedOnly: session.pinnedOnly, isPaused: store.isPaused)
        } else {
            ScrollViewReader { reader in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { i, entry in
                            if i == 0 || !Calendar.current.isDate(entry.createdAt, inSameDayAs: entries[i - 1].createdAt) {
                                Text(Self.dayLabel(entry.createdAt))
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 9)
                                    .padding(.top, 10)
                                    .padding(.bottom, 4)
                            }
                            ClipRow(entry: entry, isSelected: entry.id == (session.selection ?? entries.first?.id),
                                    copy: { copy(entry) }, pin: { store.togglePin(entry) },
                                    remove: { store.remove(entry) })
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 9)
                    .padding(.bottom, 10)
                }
                .onChange(of: session.selection) { _, id in
                    if let target = id ?? entries.first?.id { reader.scrollTo(target) }
                }
                .onChange(of: session.query) {
                    session.selection = nil
                    if let first = entries.first?.id { reader.scrollTo(first, anchor: .top) }
                }
                .onChange(of: entries.map(\.id)) {
                    if let id = session.selection, !entries.contains(where: { $0.id == id }) {
                        session.selection = nil
                    }
                }
            }
        }
    }

    private static func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private var clearConfirmation: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Clear unpinned history?").font(.headline)
            Text("This deletes all unpinned clips from Clipwell.\nYour pinned clips and current clipboard are kept.")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack {
                Button("Cancel") { _ = session.goBack() }
                Button("Clear History", role: .destructive) {
                    store.clearUnpinned()
                    _ = session.goBack()
                }
            }.padding(.top, 4)
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    private func copy(_ entry: ClipEntry) {
        copyFailed = !store.copy(entry)
        if !copyFailed { dismiss() }
    }

    private func handle(_ command: PanelSession.Command) {
        guard session.screen == .history else { return }
        if case .focusSearch = command {
            copyFailed = false
            Task { @MainActor in searchFocused = true }
            return
        }
        let entries = visibleEntries
        guard !entries.isEmpty else { return }
        let index = entries.firstIndex { $0.id == session.selection } ?? 0
        switch command {
        case .move(let delta): session.selection = entries[min(max(0, index + delta), entries.count - 1)].id
        case .pin: store.togglePin(entries[index])
        case .copy: copy(entries[index])
        case .focusSearch: break
        }
    }
}
