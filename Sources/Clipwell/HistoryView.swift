import SwiftUI

struct HistoryView: View {
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
            header
            switch session.screen {
            case .history:
                searchField
                filters
                Rectangle().fill(Ink.line).frame(height: 1)
                historyList
                footer
            case .shortcuts:
                ShortcutGuide(unavailable: session.unavailableShortcuts) { _ = session.goBack() }
            case .confirmClear:
                clearConfirmation
            }
        }
        .foregroundStyle(Ink.text)
        .frame(width: 428, height: 534)
        .background(Ink.surface)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(Ink.line.opacity(0.9), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .tint(Ink.accent)
        .onReceive(session.commands, perform: handle)
    }

    private var header: some View {
        HStack(spacing: 9) {
            BrandMark().frame(width: 31, height: 31)
            Text("Clipwell")
                .font(.system(size: 20, weight: .semibold))
                .tracking(-0.8)
            Spacer()
            Button(action: store.togglePause) {
                HStack(spacing: 5) {
                    Circle().fill(store.isPaused ? Color.orange : Ink.accent)
                        .frame(width: 5, height: 5)
                    Text(store.isPaused ? "Paused" : "Listening")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(store.isPaused ? Ink.secondary : Ink.accent)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(store.isPaused ? Ink.inset : Ink.tint, in: Capsule())
            }
            .buttonStyle(.plain)
            .help(store.isPaused ? "Resume clipboard history" : "Pause clipboard history")
            .accessibilityHint(store.isPaused ? "Resumes clipboard history" : "Pauses clipboard history")
            Menu {
                Button("Keyboard Shortcuts") { session.screen = .shortcuts }
                Button(store.isPaused ? "Resume History" : "Pause History", action: store.togglePause)
                Button("Clear Unpinned History…") { session.screen = .confirmClear }
                    .disabled(!store.entries.contains { !$0.isPinned })
                Divider()
                Button("Quit Clipwell", action: quit)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .accessibilityLabel("More options")
            .help("More options")
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass").font(.system(size: 14, weight: .medium))
                .foregroundStyle(Ink.secondary)
            TextField("Search your clips", text: $session.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($searchFocused)
                .accessibilityLabel("Search your clips")
            if session.query.isEmpty {
                Keycap(key: "⌘ F").accessibilityHidden(true)
            } else {
                Button {
                    session.query = ""
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Ink.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 11)
        .frame(height: 38)
        .background(Ink.inset, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(searchFocused ? Ink.accent.opacity(0.5) : Ink.line, lineWidth: 0.8)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 18)
    }

    private var filters: some View {
        HStack(spacing: 5) {
            filter("All clips", symbol: "square.stack", pinned: false)
            filter("Pinned", symbol: "pin", pinned: true)
            Spacer()
            let count = visibleEntries.count
            Text("\(count) \(count == 1 ? "clip" : "clips")")
                .font(.system(size: 11))
                .foregroundStyle(Ink.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func filter(_ name: String, symbol: String, pinned: Bool) -> some View {
        let active = pinned == session.pinnedOnly
        return Button { session.setFilter(pinned) } label: {
            Label(name, systemImage: symbol)
                .labelStyle(.titleAndIcon)
                .font(.system(size: 11.5, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? Ink.accent : Ink.secondary)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(active ? Ink.tint : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
        .help(pinned ? "Pinned clips (⌘2)" : "All clips (⌘1)")
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
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .tracking(1.1)
                                    .foregroundStyle(Ink.secondary)
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
        if Calendar.current.isDateInToday(date) { return "TODAY" }
        if Calendar.current.isDateInYesterday(date) { return "YESTERDAY" }
        return date.formatted(date: .abbreviated, time: .omitted).uppercased()
    }

    private var footer: some View {
        HStack(spacing: 5) {
            if copyFailed {
                Text("Couldn’t copy. Try again.").foregroundStyle(Ink.text)
            } else if visibleEntries.isEmpty {
                Keycap(key: "⌃ ⌥ V").accessibilityLabel("Control Option V")
                Text("Open history")
            } else {
                HStack(spacing: 2) { Keycap(key: "↑"); Keycap(key: "↓") }
                Text("Navigate").padding(.trailing, 8)
                Keycap(key: "↵")
                Text("Copy")
            }
            Spacer()
            IconButton(symbol: "keyboard", label: "Keyboard shortcuts") { session.screen = .shortcuts }
        }
        .font(.system(size: 10.5))
        .foregroundStyle(Ink.secondary)
        .padding(.horizontal, 18)
        .frame(height: 39)
        .background(Ink.inset.opacity(0.6))
        .overlay(alignment: .top) { Rectangle().fill(Ink.line).frame(height: 1) }
    }

    private var clearConfirmation: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "trash").font(.system(size: 27)).foregroundStyle(Ink.secondary)
            Text("Clear unpinned history?").font(.headline)
            Text("This deletes all unpinned clips from Clipwell.\nYour pinned clips and current clipboard are kept.")
                .font(.system(size: 12.5))
                .foregroundStyle(Ink.secondary)
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
