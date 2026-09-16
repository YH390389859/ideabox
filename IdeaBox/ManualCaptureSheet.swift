import SwiftUI

/// A single sheet owns the picker and editor, so closing either returns to the same conversation.
struct ManualCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 30.0
    @State private var destination: CaptureKind?

    private enum CaptureKind: String, CaseIterable {
        case text, voice, link, habit

        var title: String {
            switch self {
            case .text: "写下来"
            case .voice: "录一段"
            case .link: "留链接"
            case .habit: "添加习惯"
            }
        }
        var detail: String {
            switch self {
            case .text: "文字、心情，还有此刻的想法。"
            case .voice: "留住声音，也留住说话的语气。"
            case .link: "收下值得回来的那一页。"
            case .habit: "从一件想坚持的小事开始。"
            }
        }
        var index: String {
            switch self {
            case .text: "01 / NOTE"
            case .voice: "02 / VOICE"
            case .link: "03 / LINK"
            case .habit: "04 / HABIT"
            }
        }
        var surface: Color {
            switch self {
            case .text: Color(hex: 0xFBFAF4)
            case .voice: Color(hex: 0xE8EBDD)
            case .link: Color(hex: 0xEFE3D8)
            case .habit: Color(hex: 0xE2E7EA)
            }
        }
    }

    var body: some View {
        Group {
            switch destination {
            case .text: RecordComposerSheet(kind: .text)
            case .voice: RecordComposerSheet(kind: .voice)
            case .link: RecordComposerSheet(kind: .link)
            case .habit: HabitEditorSheet()
            case nil: picker
            }
        }
        .tint(Loom.cobalt)
        .background(Loom.paper.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: destination)
    }

    private var picker: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    LoomEyebrow(text: "KEEP IT IN YOUR OWN WAY")
                    Spacer(minLength: 0)
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .medium))
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(StudioPressStyle())
                    .accessibilityLabel("返回对话")
                }
                Text("按自己的方式，\n留下。")
                    .font(.system(size: titleSize, weight: .medium))
                    .tracking(-1).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                Text("直接记录，保存在这台 iPhone。")
                    .font(.subheadline).foregroundStyle(Loom.secondary)
                    .padding(.top, 12).padding(.bottom, 28)

                VStack(spacing: 12) {
                    ForEach(CaptureKind.allCases, id: \.self) { kind in
                        option(kind)
                    }
                }

                Rectangle().fill(Loom.hairline).frame(height: 0.7).padding(.top, 28)
                Text("随时回来，再把日常说给我听。")
                    .font(.caption).foregroundStyle(Loom.secondary)
                    .padding(.top, 16)
                LoomEyebrow(text: "SAVED ON DEVICE")
                    .frame(maxWidth: .infinity, alignment: .trailing).padding(.top, 18)
            }
            .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 24)
        }
        .foregroundStyle(Loom.ink)
        .accessibilityIdentifier("manual-capture-picker")
    }

    private func option(_ kind: CaptureKind) -> some View {
        Button { destination = kind } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 7) {
                    LoomEyebrow(text: kind.index)
                    Text(kind.title).font(.title3.weight(.medium))
                    Text(kind.detail).font(.caption).foregroundStyle(Loom.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize {
                    motif(kind).frame(width: 42, height: 52).accessibilityHidden(true)
                }
                Image(systemName: "arrow.up.right").font(.system(size: 17, weight: .regular))
            }
            .foregroundStyle(Loom.ink)
            .padding(.horizontal, 17).padding(.vertical, 15)
            .frame(minHeight: 94).background(kind.surface)
            .contentShape(Rectangle())
        }
        .buttonStyle(StudioPressStyle())
        .accessibilityLabel(kind.title)
        .accessibilityHint(kind.detail)
        .accessibilityIdentifier("manual-capture-\(kind.rawValue)")
    }

    /// Small material marks echo the paper, sound and woven collection without competing with the labels.
    private func motif(_ kind: CaptureKind) -> some View {
        Canvas { context, size in
            var path = Path()
            switch kind {
            case .text:
                path.move(to: CGPoint(x: 3, y: 2))
                path.addLine(to: CGPoint(x: 31, y: 2))
                path.addLine(to: CGPoint(x: 41, y: 12))
                path.addLine(to: CGPoint(x: 41, y: 50))
                path.addLine(to: CGPoint(x: 3, y: 50))
                path.closeSubpath()
                for y in stride(from: 18, through: 40, by: 7) {
                    path.move(to: CGPoint(x: 11, y: y))
                    path.addLine(to: CGPoint(x: 32, y: y))
                }
                context.stroke(path, with: .color(Loom.secondary.opacity(0.3)), lineWidth: 0.8)
            case .voice:
                for (index, height) in [9.0, 20, 35, 23, 44, 31, 16].enumerated() {
                    let x = 5 + Double(index) * 5
                    path.move(to: CGPoint(x: x, y: (size.height - height) / 2))
                    path.addLine(to: CGPoint(x: x, y: (size.height + height) / 2))
                }
                context.stroke(path, with: .color(Loom.olive.opacity(0.55)), lineWidth: 1)
            case .link:
                path.move(to: CGPoint(x: 14, y: 7))
                path.addLine(to: CGPoint(x: 23, y: 39))
                path.addLine(to: CGPoint(x: 33, y: 27))
                path.move(to: CGPoint(x: 8, y: 25))
                path.addLine(to: CGPoint(x: 21, y: 13))
                path.addLine(to: CGPoint(x: 28, y: 45))
                context.stroke(path, with: .color(Loom.clay.opacity(0.7)), lineWidth: 1)
            case .habit:
                for offset in stride(from: 4.0, through: 40.0, by: 9.0) {
                    path.move(to: CGPoint(x: offset, y: 5))
                    path.addLine(to: CGPoint(x: offset, y: 47))
                    path.move(to: CGPoint(x: 0, y: offset + 4))
                    path.addLine(to: CGPoint(x: 42, y: offset + 4))
                }
                context.stroke(path, with: .color(Loom.secondary.opacity(0.4)), lineWidth: 0.8)
                context.fill(Path(ellipseIn: CGRect(x: 18, y: 23, width: 6, height: 6)), with: .color(Loom.cobalt))
            }
        }
    }
}
