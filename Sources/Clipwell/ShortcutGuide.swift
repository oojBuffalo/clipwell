import SwiftUI

struct ShortcutGuide: View {
    let unavailable: [String]
    let back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                IconButton(symbol: "chevron.left", label: "Back to history", action: back)
                Text("Keyboard shortcuts")
                    .font(.system(size: 17, weight: .semibold)).tracking(-0.4)
            }
            .padding(.horizontal, 13)
            .padding(.bottom, 10)
            Rectangle().fill(Ink.line).frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    section("SYSTEM-WIDE")
                    shortcut("Open or close history", ["⌃", "⌥", "V"])
                    shortcut("Copy a recent clip", ["⌃", "⌥", "1 / 2 / 3"])
                    section("IN HISTORY")
                    shortcut("Select a clip", ["↑", "↓"])
                    shortcut("Copy selection", ["↵"])
                    shortcut("Pin or unpin selection", ["⌘", "P"])
                    shortcut("All clips / Pinned", ["⌘", "1 / 2"])
                    shortcut("Search clips", ["⌘", "F"])
                    shortcut("Back or close", ["esc"])
                    if !unavailable.isEmpty {
                        Label("Unavailable on this Mac: " + unavailable.joined(separator: ", "),
                              systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(Ink.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
            Spacer(minLength: 0)
            Text("⌃ Control      ⌥ Option      ⌘ Command")
                .font(.system(size: 10.5))
                .foregroundStyle(Ink.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .frame(height: 39)
                .background(Ink.inset.opacity(0.6))
                .overlay(alignment: .top) { Rectangle().fill(Ink.line).frame(height: 1) }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9.5, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(Ink.secondary)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    private func shortcut(_ name: String, _ keys: [String]) -> some View {
        HStack(spacing: 3) {
            Text(name).font(.system(size: 12.5))
            Spacer()
            ForEach(keys, id: \.self) { Keycap(key: $0) }
        }
        .frame(height: 31)
    }
}
