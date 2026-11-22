import SwiftUI

struct ClipRow: View {
    let entry: ClipEntry
    let isSelected: Bool
    let copy: () -> Void
    let pin: () -> Void
    let remove: () -> Void
    @State private var hovered = false

    private var preview: String {
        let start = entry.text.drop(while: \.isWhitespace).prefix(180)
        return start.isEmpty ? "Whitespace" : start.split(whereSeparator: \.isNewline).joined(separator: " ")
    }

    var body: some View {
        let showsPin = hovered || isSelected || entry.isPinned
        HStack(spacing: 3) {
            Button(action: copy) {
                HStack(spacing: 10) {
                    Text(verbatim: preview)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(entry.createdAt, format: .dateTime.hour().minute())
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                .padding(.leading, 8)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint("Copies this clip and closes history")
            .accessibilityAction(named: entry.isPinned ? "Unpin clip" : "Pin clip", pin)
            .accessibilityAction(named: "Delete clip", remove)

            Button(action: pin) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(showsPin ? 1 : 0)
            .allowsHitTesting(showsPin)
            .accessibilityLabel(entry.isPinned ? "Unpin clip" : "Pin clip")
            .help(entry.isPinned ? "Unpin clip" : "Pin clip")
        }
        .font(.body)
        .frame(height: 30)
        .background(Color.primary.opacity(isSelected ? 0.10 : hovered ? 0.05 : 0),
                    in: RoundedRectangle(cornerRadius: 5))
        .onHover { hovered = $0 }
        .contextMenu {
            Button("Copy", action: copy)
            Button(entry.isPinned ? "Unpin" : "Pin", action: pin)
            Divider()
            Button("Delete Clip", role: .destructive, action: remove)
        }
    }
}
