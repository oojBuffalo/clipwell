import SwiftUI

struct ClipRow: View {
    let entry: ClipEntry
    let isSelected: Bool
    let copy: () -> Void
    let pin: () -> Void
    let remove: () -> Void
    @State private var hovered = false

    private var website: URL? {
        guard entry.text.hasPrefix("https://") || entry.text.hasPrefix("http://"),
              entry.text.utf8.count < 2048,
              entry.text.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let url = URL(string: entry.text), url.host != nil else { return nil }
        return url
    }

    private var preview: String {
        let start = entry.text.drop(while: \.isWhitespace).prefix(180)
        return start.isEmpty ? "Whitespace" : start.split(whereSeparator: \.isNewline).joined(separator: " ")
    }

    var body: some View {
        let site = website
        HStack(spacing: 8) {
            Button(action: copy) {
                HStack(spacing: 11) {
                    Image(systemName: site == nil ? "text.alignleft" : "link")
                        .font(.system(size: 15, weight: .medium))
                        .frame(width: 31, height: 33)
                        .foregroundStyle(site == nil ? Ink.secondary : Ink.accent)
                        .background(site == nil ? Ink.inset : Ink.tint, in: RoundedRectangle(cornerRadius: 7))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: preview)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Ink.text)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        HStack(spacing: 5) {
                            Text(site?.host ?? "Plain text").lineLimit(1)
                            Text("·")
                            Text(entry.createdAt, format: .dateTime.hour().minute())
                        }
                        .font(.system(size: 10.5))
                        .foregroundStyle(Ink.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Copies this clip and closes history")
            Button(action: pin) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundStyle(entry.isPinned ? Ink.accent : Ink.secondary)
                    .frame(width: 25, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(hovered || isSelected || entry.isPinned ? 1 : 0)
            .accessibilityLabel(entry.isPinned ? "Unpin clip" : "Pin clip")
            .help(entry.isPinned ? "Unpin clip" : "Pin clip")
        }
        .padding(.horizontal, 9)
        .frame(height: 54)
        .background(isSelected ? Ink.tint.opacity(0.84) : hovered ? Ink.inset : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .onHover { hovered = $0 }
        .contextMenu {
            Button("Copy", action: copy)
            Button(entry.isPinned ? "Unpin" : "Pin", action: pin)
            Divider()
            Button("Delete Clip", role: .destructive, action: remove)
        }
    }
}
