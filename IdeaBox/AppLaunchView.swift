import SwiftUI

struct AppLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchVisible = true
    @State private var didBegin = false
    @State private var startedAt: Date?
    @State private var revealing = false

    var body: some View {
        ZStack {
            Loom.paper.ignoresSafeArea()
            ContentView(allowsAmbientMotion: !launchVisible)
                .opacity(revealing ? 1 : 0)
                .offset(y: revealing || reduceMotion ? 0 : 8)
                .allowsHitTesting(!launchVisible)
                .accessibilityHidden(launchVisible)
            if launchVisible {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion || scenePhase != .active)) { context in
                    let elapsed = reduceMotion ? 0 : max(0, context.date.timeIntervalSince(startedAt ?? context.date))
                    LoomOpening(elapsed: min(2.65, elapsed))
                }
                .opacity(revealing ? 0 : 1)
                .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if launchVisible && !reduceMotion {
                Button("跳过") { finishImmediately() }
                    .font(.system(size: 12)).foregroundStyle(Loom.secondary)
                    .padding(.horizontal, 18).frame(height: 44)
                    .background(Loom.paper.opacity(0.9))
                    .padding(.trailing, 24).padding(.bottom, 16)
                    .opacity(revealing ? 0 : 1)
                    .allowsHitTesting(!revealing).accessibilityHidden(revealing)
                    .accessibilityLabel("跳过开屏动画")
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await playIntroduction()
        }
        .onChange(of: scenePhase) { _, phase in if phase == .background { finishImmediately() } }
        .onChange(of: reduceMotion) { _, enabled in if enabled { finishImmediately() } }
    }

    @MainActor private func playIntroduction() async {
        guard launchVisible, !didBegin else { return }
        didBegin = true
        startedAt = Date()
        do {
            if reduceMotion {
                withAnimation(.easeOut(duration: 0.12)) { revealing = true }
                try await Task.sleep(for: .milliseconds(140))
            } else {
                try await Task.sleep(for: .milliseconds(2150))
                guard launchVisible else { return }
                withAnimation(.easeInOut(duration: 0.44)) { revealing = true }
                try await Task.sleep(for: .milliseconds(460))
            }
            launchVisible = false
        } catch { finishImmediately() }
    }

    private func finishImmediately() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { revealing = true; launchVisible = false }
    }
}

private struct LoomOpening: View {
    let elapsed: Double
    private var brandThreads: [WovenThread] {
        let colors = [Loom.cobalt, Loom.cobalt, Loom.clay, Loom.acid, Loom.cobalt, Loom.cobalt, Loom.acid, Loom.clay]
        return colors.enumerated().map { index, color in
            WovenThread(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!, color: color, completed: true)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2 - 40)
            let forming = smooth(0.32, 1.83)
            ZStack {
                Loom.paper
                LoomSign().frame(width: 176, height: 176)
                    .scaleEffect(1 + smooth(0.12, 0.62) * 0.16)
                    .opacity(1 - smooth(0.3, 0.72))
                    .position(center)
                WovenArtwork(threads: brandThreads, active: false, reveal: forming, allowsInteraction: false)
                    .frame(width: 278, height: 276)
                    .position(center)
                shuttle(width: min(340, geometry.size.width - 48))
                    .frame(width: min(340, geometry.size.width - 48), height: 278)
                    .position(center)
                VStack(spacing: 14) {
                    HStack(spacing: 2.5) {
                        ForEach(Array("IDEABOX".enumerated()), id: \.offset) { index, character in
                            let shown = smooth(1.48 + Double(index) * 0.055, 1.75 + Double(index) * 0.055)
                            Text(String(character)).font(.system(size: 23, weight: .medium, design: .monospaced))
                                .foregroundStyle(Loom.ink)
                                .opacity(shown).offset(y: (1 - shown) * 8)
                        }
                    }
                    Text("把日常，织成自己的作品。")
                        .font(.system(size: 12)).tracking(1).foregroundStyle(Loom.secondary)
                        .opacity(smooth(1.82, 2.14))
                }.position(x: center.x, y: geometry.size.height / 2 + 139)
            }
        }.ignoresSafeArea()
    }

    private func shuttle(width: CGFloat) -> some View {
        let p = min(0.999, max(0, (elapsed - 0.42) / 1.24))
        let pass = Int(p * 3)
        let travel = p * 3 - Double(pass)
        let across = min(1, travel / 0.76)
        let turn = pass < 2 ? max(0, (travel - 0.76) / 0.24) : 0
        let easedTurn = turn * turn * (3 - 2 * turn)
        let outward = sin(turn * .pi) * 10
        let x = 10 + (pass.isMultiple(of: 2) ? across : 1 - across) * (width - 20)
            + (pass.isMultiple(of: 2) ? outward : -outward)
        let y = 56 + Double(pass) * 77 + sin(across * .pi) * 13 + easedTurn * 77
        let opacity = smooth(0.42, 0.6) * (1 - smooth(1.5, 1.79))
        return ZStack {
            Canvas { context, size in
                for lane in 0..<3 {
                    let drawn = min(1, max(0, (p * 3 - Double(lane)) / 0.76))
                    guard drawn > 0 else { continue }
                    let leftToRight = lane.isMultiple(of: 2)
                    var path = Path()
                    let y = 56.0 + Double(lane) * 77
                    for step in 0...40 {
                        let u = drawn * Double(step) / 40
                        let px = leftToRight ? u : 1 - u
                        let point = CGPoint(x: 10 + px * (size.width - 20), y: y + sin(u * .pi) * 13)
                        if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
                    }
                    context.stroke(path, with: .color([Loom.cobalt, Loom.clay, Loom.olive][lane].opacity(0.38)), lineWidth: 0.7)
                }
            }
            ShuttleShape().fill(pass == 1 ? Loom.clay : Loom.ink)
                .frame(width: 32, height: 11)
                .rotationEffect(.degrees((pass.isMultiple(of: 2) ? 8 : -8) + easedTurn * 180))
                .position(x: x, y: y)
        }.opacity(opacity)
    }

    private func smooth(_ start: Double, _ end: Double) -> Double {
        let p = min(1, max(0, (elapsed - start) / (end - start)))
        return p * p * (3 - 2 * p)
    }
}

#Preview { AppLaunchView().preferredColorScheme(.light) }
