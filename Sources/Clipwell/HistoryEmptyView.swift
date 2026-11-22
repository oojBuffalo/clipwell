import SwiftUI

struct HistoryEmptyView: View {
    let isSearching: Bool
    let pinnedOnly: Bool
    let isPaused: Bool

    private var title: String {
        if isSearching { return "No matching clips" }
        if pinnedOnly { return "No pinned clips yet" }
        if isPaused { return "Clipboard history is paused" }
        return "No clips yet"
    }

    private var detail: String {
        if isSearching { return "Try a different word or phrase." }
        if pinnedOnly { return "Pin a clip with ⌘P to keep it here." }
        if isPaused { return "Click Paused above to start collecting clips." }
        return "Copy text in any app with ⌘C.\nYour clips will appear here."
    }

    var body: some View {
        VStack(spacing: 0) {
            if isSearching || pinnedOnly || isPaused {
                Image(systemName: isSearching ? "magnifyingglass" : pinnedOnly ? "pin" : "pause")
                    .font(.system(size: 25, weight: .light))
                    .foregroundStyle(Ink.accent)
                    .frame(width: 58, height: 58)
                    .background(Ink.tint, in: RoundedRectangle(cornerRadius: 17))
                    .padding(.bottom, 17)
                    .accessibilityHidden(true)
            } else {
                PaperIllustration()
                    .frame(width: 244, height: 136)
                    .padding(.bottom, 6)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(Ink.text)
            Text(detail)
                .font(.system(size: 12.5))
                .foregroundStyle(Ink.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 12)
    }
}

private struct PaperIllustration: View {
    private let moss = Color(red: 0.25, green: 0.44, blue: 0.32)
    private let leaf = Color(red: 0.73, green: 0.82, blue: 0.65)
    private let paper = Color(red: 1, green: 0.992, blue: 0.937)

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                for x in stride(from: 4.0, to: size.width, by: 10) {
                    for y in stride(from: 4.0, to: size.height, by: 10) {
                        let d = hypot((x - size.width / 2) / 118, (y - size.height / 2) / 66)
                        if d < 1 {
                            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.8, height: 1.8)),
                                     with: .color(Ink.accent.opacity(0.28 * (1 - d))))
                        }
                    }
                }
            }
            RoundedRectangle(cornerRadius: 5)
                .fill(leaf)
                .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(moss.opacity(0.48), lineWidth: 1) }
                .frame(width: 63, height: 78)
                .rotationEffect(.degrees(-17))
                .offset(x: -12, y: 3)
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.89, green: 0.92, blue: 0.82))
                .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(moss.opacity(0.48), lineWidth: 1) }
                .frame(width: 63, height: 78)
                .rotationEffect(.degrees(-5))
                .offset(x: -3, y: 2)
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    RoundedRectangle(cornerRadius: 1).fill(moss).frame(width: 18, height: 3.5)
                    ForEach([36, 32, 37, 23], id: \.self) { width in
                        Capsule().fill(leaf).frame(width: CGFloat(width), height: 2.5)
                    }
                }
                .frame(width: 62, height: 80)
                .background(paper, in: RoundedRectangle(cornerRadius: 5))
                .overlay { RoundedRectangle(cornerRadius: 5).strokeBorder(moss.opacity(0.8), lineWidth: 1.2) }
                .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
                RoundedRectangle(cornerRadius: 3)
                    .fill(moss)
                    .frame(width: 25, height: 9)
                    .overlay { Capsule().fill(leaf).frame(width: 9, height: 1.5) }
                    .offset(y: -4)
            }
            .rotationEffect(.degrees(9))
            .offset(x: 10, y: -1)
        }
    }
}
