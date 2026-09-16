import SwiftUI

/// A single thread loops back, then continues into a new line.
struct NewConversationThreadMark: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            Path { path in
                path.move(to: CGPoint(x: w * 0.03, y: h * 0.78))
                path.addCurve(to: CGPoint(x: w * 0.55, y: h * 0.24),
                              control1: CGPoint(x: w * 0.40, y: h * 0.84),
                              control2: CGPoint(x: w * 0.31, y: h * 0.22))
                path.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.69),
                              control1: CGPoint(x: w * 0.94, y: h * 0.12),
                              control2: CGPoint(x: w * 0.73, y: h * 0.84))
                path.addCurve(to: CGPoint(x: w * 0.97, y: h * 0.40),
                              control1: CGPoint(x: w * 0.14, y: h * 0.52),
                              control2: CGPoint(x: w * 0.56, y: h * 0.36))
            }
            .stroke(Loom.ink, style: StrokeStyle(lineWidth: 1.35, lineCap: .round, lineJoin: .round))
        }
        .accessibilityHidden(true)
    }
}

/// Custom confirmation retains the existing clear-conversation semantics.
struct NewConversationPrompt: View {
    let canConfirm: Bool
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var titleSize = 31.0
    @State private var appeared = false
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Loom.ink.opacity(0.48)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onCancel)
                    .accessibilityHidden(true)

                ViewThatFits(in: .vertical) {
                    paper
                    ScrollView(showsIndicators: false) {
                        paper.padding(.vertical, 8)
                    }
                }
                .frame(maxWidth: 360, maxHeight: max(0, geometry.size.height - 24))
                .padding(.horizontal, 22)
                .scaleEffect(reduceMotion || appeared ? 1 : 0.97)
                .offset(y: reduceMotion || appeared ? 0 : 12)
                .opacity(appeared ? 1 : 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onCancel)
        .onAppear {
            titleFocused = true
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.32, dampingFraction: 0.88)) {
                appeared = true
            }
        }
    }

    private var paper: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                NewConversationThreadArtwork().frame(height: 76)
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(Loom.secondary)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel("继续当前对话")
                .accessibilityIdentifier("agent-new-conversation-close")
                .padding(.trailing, -12).padding(.top, -12)
            }
            .padding(.bottom, 13)

            Text("BEGIN AGAIN")
                .font(.system(.caption2, design: .monospaced, weight: .medium))
                .tracking(1.7).foregroundStyle(Loom.cobalt)
                .accessibilityHidden(true)
            Text("再起一线")
                .font(.system(size: titleSize, weight: .medium))
                .tracking(-1.1).foregroundStyle(Loom.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 7)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("agent-new-conversation-title")
                .accessibilityFocused($titleFocused)
            Text("将清空本机的当前对话。\n已保存的日常、习惯和收集仍会保留。")
                .font(.subheadline).lineSpacing(6)
                .foregroundStyle(Loom.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 15).padding(.bottom, 24)

            Button(role: .destructive, action: onConfirm) {
                Text("清空并开始")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 40).padding(.vertical, 15)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 15, weight: .regular))
                            .padding(.trailing, 22).accessibilityHidden(true)
                    }
                    .foregroundStyle(Loom.paper)
                    .background(Loom.ink, in: Capsule())
                    .contentShape(Capsule())
            }
            .disabled(!canConfirm)
            .accessibilityIdentifier("agent-new-conversation-confirm")

            Button(action: onCancel) {
                Text("继续这段对话")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Loom.ink)
                    .padding(.bottom, 6)
                    .overlay(alignment: .bottom) { Rectangle().fill(Loom.hairline).frame(height: 1) }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("agent-new-conversation-cancel")
            .padding(.top, 12)
        }
        .buttonStyle(StudioPressStyle())
        .padding(27)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xF7F4EB), in: RoundedRectangle(cornerRadius: 23))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Loom.hairline.opacity(0.65), style: StrokeStyle(lineWidth: 0.6, dash: [1, 5]))
                .padding(13).allowsHitTesting(false).accessibilityHidden(true)
        }
        .shadow(color: Loom.ink.opacity(0.10), radius: 24, x: 0, y: 12)
    }
}

private struct NewConversationThreadArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.40))
                    p.addCurve(to: CGPoint(x: w * 0.22, y: h * 0.24), control1: CGPoint(x: w * 0.12, y: h * 0.42), control2: CGPoint(x: w * 0.19, y: h * 0.06))
                    p.addCurve(to: CGPoint(x: w * 0.13, y: h * 0.62), control1: CGPoint(x: w * 0.43, y: h * 0.02), control2: CGPoint(x: w * 0.30, y: h * 0.89))
                    p.addCurve(to: CGPoint(x: w * 0.37, y: h * 0.34), control1: CGPoint(x: w * 0.04, y: h * 0.26), control2: CGPoint(x: w * 0.29, y: h * 0.08))
                    p.addCurve(to: CGPoint(x: w * 0.29, y: h * 0.72), control1: CGPoint(x: w * 0.63, y: h * 0.69), control2: CGPoint(x: w * 0.20, y: h * 0.94))
                    p.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.46), control1: CGPoint(x: w * 0.22, y: h * 0.41), control2: CGPoint(x: w * 0.43, y: h * 0.22))
                }
                .stroke(Color(hex: 0xB4BFA7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

                Path { p in
                    p.move(to: CGPoint(x: w * 0.33, y: h * 0.66))
                    p.addCurve(to: CGPoint(x: w * 0.53, y: h * 0.35), control1: CGPoint(x: w * 0.46, y: h * 0.57), control2: CGPoint(x: w * 0.43, y: h * 0.04))
                    p.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.53), control1: CGPoint(x: w * 0.68, y: h * 0.77), control2: CGPoint(x: w * 0.39, y: h * 0.64))
                    p.addCurve(to: CGPoint(x: w * 0.65, y: h * 0.40), control1: CGPoint(x: w * 0.48, y: h * 0.23), control2: CGPoint(x: w * 0.60, y: h * 0.49))
                    p.addCurve(to: CGPoint(x: w * 0.81, y: h * 0.17), control1: CGPoint(x: w * 0.72, y: h * 0.39), control2: CGPoint(x: w * 0.72, y: h * 0.17))
                    p.addLine(to: CGPoint(x: w * 0.98, y: h * 0.17))
                }
                .trim(from: 0, to: revealed || reduceMotion ? 1 : 0)
                .stroke(Loom.cobalt, style: StrokeStyle(lineWidth: 1.55, lineCap: .round))
                Circle().fill(Loom.cobalt).frame(width: 5, height: 5)
                    .position(x: w * 0.98, y: h * 0.17)
                    .opacity(revealed || reduceMotion ? 1 : 0)
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.42).delay(0.08)) { revealed = true }
        }
    }
}
