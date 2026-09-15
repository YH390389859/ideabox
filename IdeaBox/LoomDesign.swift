import SwiftUI

enum Loom {
    static let paper = Color(hex: 0xF3F0E8)
    static let ink = Color(hex: 0x202A2B)
    static let cobalt = Color(hex: 0x3555E8)
    static let acid = Color(hex: 0xD9EB77)
    static let clay = Color(hex: 0xC96C50)
    static let secondary = Color(hex: 0x7C827C)
    static let hairline = Color(hex: 0xD8D8CB)
    static let olive = Color(hex: 0x879F35)

    static func threadColor(for habit: Habit) -> Color {
        let hash = habit.id.uuidString.utf8.reduce(UInt64(1469598103934665603)) { ($0 ^ UInt64($1)) &* 1099511628211 }
        return [cobalt, cobalt, clay, olive, Color(hex: 0x648F83)][Int(hash % 5)]
    }
}

struct LoomEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(1.15).foregroundStyle(Loom.secondary)
            .lineLimit(1).minimumScaleFactor(0.75)
    }
}

struct LoomHeader: View {
    let index: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LoomEyebrow(text: index).padding(.bottom, 5)
            Text(title).font(.system(size: 30, weight: .medium)).tracking(-1.2)
                .foregroundStyle(Loom.ink).lineLimit(1).minimumScaleFactor(0.8)
            Text(subtitle).font(.system(size: 12)).foregroundStyle(Loom.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(.top, 14)
    }
}

struct ShuttleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.width * 0.24, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.width * 0.76, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.width * 0.76, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.width * 0.24, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Brand sign drawn from two bands that alternate over and under.
struct LoomSign: View {
    var color: Color = Loom.cobalt
    var body: some View {
        Canvas { context, size in
            let w = size.width
            for line in 0..<4 {
                var horizontal = Path()
                let y = w * (0.28 + Double(line) * 0.145)
                horizontal.move(to: CGPoint(x: w * 0.08, y: y))
                horizontal.addCurve(to: CGPoint(x: w * 0.92, y: y - w * 0.10), control1: CGPoint(x: w * 0.37, y: y - w * 0.22), control2: CGPoint(x: w * 0.64, y: y + w * 0.16))
                context.stroke(horizontal, with: .color(color), style: StrokeStyle(lineWidth: max(1, w * 0.035), lineCap: .round))
                var vertical = Path()
                let x = w * (0.28 + Double(line) * 0.145)
                vertical.move(to: CGPoint(x: x, y: w * 0.08))
                vertical.addCurve(to: CGPoint(x: x - w * 0.10, y: w * 0.92), control1: CGPoint(x: x - w * 0.22, y: w * 0.37), control2: CGPoint(x: x + w * 0.16, y: w * 0.64))
                context.stroke(vertical, with: .color(color.opacity(0.65)), style: StrokeStyle(lineWidth: max(1, w * 0.025), lineCap: .round))
            }
        }.accessibilityHidden(true)
    }
}
