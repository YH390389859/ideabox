import SwiftUI

// IdeaBox's shared visual language. All dimensions are in points.
enum Studio {
    static let background = Loom.paper
    static let ink = Loom.ink
    static let secondary = Loom.secondary
    static let accent = Loom.cobalt
    static let lavender = Color(hex: 0xE4E8F9)
    static let sage = Color(hex: 0xE2E6D6)
    static let peach = Color(hex: 0xF0E0D5)
    static let line = Loom.hairline
    static let radius: CGFloat = 12
    static let spring = Animation.spring(response: 0.38, dampingFraction: 0.78)
}

struct StudioPressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    func studioCard(fill: Color = .white, radius: CGFloat = Studio.radius) -> some View {
        background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).stroke(Studio.line.opacity(0.7), lineWidth: 0.7))
    }
}

struct StudioPageHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(2.2).foregroundStyle(Studio.secondary)
            Text(title)
                .font(.system(size: 29, weight: .semibold))
                .tracking(-1).foregroundStyle(Studio.ink)
                .minimumScaleFactor(0.8).lineLimit(1)
            if let subtitle {
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Studio.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }
}

struct StudioSectionHeading: View {
    let title: String
    var detail: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 18, weight: .semibold)).foregroundStyle(Studio.ink)
            Spacer()
            if let detail {
                if let action {
                    Button(action: action) {
                        HStack(spacing: 5) {
                            Text(detail)
                            Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold))
                        }
                    }.buttonStyle(StudioPressStyle())
                } else { Text(detail) }
            }
        }
        .font(.system(size: 12, weight: .medium)).foregroundStyle(Studio.secondary)
    }
}

struct StudioIcon: View {
    let symbol: String
    var color: Color = Studio.accent
    var fill: Color = Studio.lavender
    var size: CGFloat = 42
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.43, weight: .medium))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(fill, in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

struct StudioEmptyState: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 14) {
            StudioIcon(symbol: symbol, size: 58)
            Text(title).font(.system(size: 18, weight: .semibold)).foregroundStyle(Studio.ink)
            Text(message).font(.system(size: 13)).foregroundStyle(Studio.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 38).padding(.horizontal, 24)
    }
}

struct StudioPill: View {
    let title: String
    var selected = false
    var body: some View {
        Text(title).font(.system(size: 12, weight: .medium))
            .foregroundStyle(selected ? .white : Studio.secondary)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(selected ? Studio.ink : .white, in: Capsule())
    }
}

struct StudioSheetHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 26, weight: .semibold)).foregroundStyle(Studio.ink)
            Text(subtitle).font(.system(size: 13)).foregroundStyle(Studio.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudioPrimaryButton: View {
    let title: String
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title).font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 52)
                .background(disabled ? Studio.secondary.opacity(0.4) : Studio.ink, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(StudioPressStyle()).disabled(disabled)
    }
}
