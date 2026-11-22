import SwiftUI

struct ShortcutGuide: View {
    let unavailable: [String]
    let back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Button(action: back) {
                    Label("Back to history", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Back to history")
                Text("Keyboard shortcuts")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        heading("System-wide")
                        shortcut("Open or close history", "⌃⌥V")
                        shortcut("Copy a recent clip", "⌃⌥1, ⌃⌥2, ⌃⌥3")
                        if !unavailable.isEmpty {
                            Label("Unavailable on this Mac: " + unavailable.joined(separator: ", "),
                                  systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        heading("In history")
                        shortcut("Select a clip", "↑ / ↓")
                        shortcut("Copy selection", "Return")
                        shortcut("Pin or unpin selection", "⌘P")
                        shortcut("All clips / Pinned", "⌘1 / ⌘2")
                        shortcut("Search clips", "⌘F")
                        shortcut("Back or close", "Esc")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }

            Divider()
            Text("⌃ Control    ⌥ Option    ⌘ Command")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .frame(height: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func heading(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func shortcut(_ name: String, _ keys: String) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(keys).foregroundStyle(.secondary)
        }
        .font(.callout)
        .frame(minHeight: 19)
        .accessibilityElement(children: .combine)
    }
}
