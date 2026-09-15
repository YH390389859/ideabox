import SwiftUI

struct WovenThread: Identifiable {
    let id: UUID
    let color: Color
    let completed: Bool
    let history: [Bool]

    init(id: UUID = UUID(), color: Color = Color(red: 0.21, green: 0.33, blue: 0.91),
         completed: Bool = false, history: [Bool] = []) {
        self.id = id
        self.color = color
        self.completed = completed
        self.history = history
    }
}

/// A data-driven piece of cloth. The fibers are paths, so both their shape and
/// weave respond to a touch, a completed habit, and the introduction's reveal.
struct WovenArtwork: View {
    let threads: [WovenThread]
    var active = true
    var reveal: Double = 1
    var allowsInteraction = true

    /// The resting position of a lane, in the artwork's own view coordinates.
    /// External annotations share the exact same surface and fitting transform.
    static func anchor(for index: Int, count: Int, at vertical: Double, in size: CGSize) -> CGPoint {
        guard count > 0, size.width > 0, size.height > 0 else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        let lane = min(count - 1, max(0, index))
        let u = (Double(lane) + 0.5) / Double(count)
        let v = min(1, max(0, vertical))
        let geometry = FabricGeometry(phase: 0, tug: .zero, pulseAge: 1,
                                      tightenedLanes: [], laneCount: count, reveal: 1)
        let point = geometry.point(u, v)
        let layout = fittedLayout(in: size)
        return CGPoint(x: point.x * layout.scale + layout.offset.x,
                       y: point.y * layout.scale + layout.offset.y)
    }

    private static func fittedLayout(in size: CGSize) -> (scale: CGFloat, offset: CGPoint) {
        // The raised back corner reaches y = -18 in the blueprint's surface.
        // Reserve room above it as well as below the loose ends at y = 303.
        let scale = min(size.width / 350, size.height / 337)
        let offset = CGPoint(x: (size.width - 350 * scale) / 2,
                             y: (size.height - 337 * scale) / 2 + 25 * scale)
        return (scale, offset)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var origin = Date()
    @State private var dragging = false
    @State private var drag = CGSize.zero
    @State private var release = CGSize.zero
    @State private var releasedAt = Date.distantPast
    @State private var tightenedAt = Date.distantPast
    @State private var tightenedLanes: [Int] = []

    private var motionPaused: Bool { reduceMotion || !active || scenePhase != .active }

    private var completionState: [CompletionState] {
        threads.map { CompletionState(id: $0.id, completed: $0.completed) }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1.0 / 24, paused: motionPaused)) { timeline in
                let tug = currentTug(at: timeline.date)
                let phase = motionPaused ? 0 : timeline.date.timeIntervalSince(origin)
                let age = motionPaused ? 1 : timeline.date.timeIntervalSince(tightenedAt)
                Canvas { context, size in
                    let fabric = FabricGeometry(
                        phase: phase, tug: tug, pulseAge: age,
                        tightenedLanes: tightenedLanes, laneCount: max(threads.count, 1),
                        reveal: min(1, max(0, reveal))
                    )
                    drawCloth(in: &context, size: size, geometry: fabric)
                }
                .rotation3DEffect(.degrees(-Double(tug.height) * 9), axis: (x: 1, y: 0, z: 0), perspective: 0.32)
                .rotation3DEffect(.degrees(Double(tug.width) * 11), axis: (x: 0, y: 1, z: 0), perspective: 0.32)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 5)
                        .onChanged { value in
                            guard allowsInteraction, !motionPaused else { return }
                            dragging = true
                            drag = CGSize(
                                width: bounded(value.translation.width / max(1, geometry.size.width * 0.34)),
                                height: bounded(value.translation.height / max(1, geometry.size.height * 0.4))
                            )
                        }
                        .onEnded { _ in
                            release = drag
                            releasedAt = Date()
                            dragging = false
                            drag = .zero
                        },
                    including: allowsInteraction && !motionPaused ? .all : .none
                )
            }
        }
        .accessibilityHidden(true)
        .onChange(of: completionState) { before, after in
            let previous = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0.completed) })
            tightenedLanes = after.indices.filter { index in
                previous[after[index].id].map { $0 != after[index].completed } ?? after[index].completed
            }
            if !tightenedLanes.isEmpty, !motionPaused { tightenedAt = Date() }
        }
        .onChange(of: motionPaused) { _, paused in
            if paused { resetTouch() }
        }
        .onChange(of: allowsInteraction) { _, enabled in
            if !enabled { resetTouch() }
        }
    }

    private func resetTouch() {
        dragging = false
        drag = .zero
        release = .zero
        releasedAt = .distantPast
    }

    private func currentTug(at date: Date) -> CGSize {
        guard !motionPaused else { return .zero }
        if dragging { return drag }
        let age = max(0, date.timeIntervalSince(releasedAt))
        guard age < 1.15 else { return .zero }
        // A damped spring with zero initial velocity, sampled by the same clock
        // as the fabric. This keeps its perspective and its fibers in phase.
        let spring = exp(-6.8 * age) * (cos(11 * age) + 6.8 / 11 * sin(11 * age))
        return CGSize(width: release.width * spring, height: release.height * spring)
    }

    private func bounded(_ value: CGFloat) -> CGFloat { min(1, max(-1, value)) }

    private struct CompletionState: Equatable {
        let id: UUID
        let completed: Bool
    }

    private var neutralThread: Color { Color(red: 0.66, green: 0.69, blue: 0.61) }
    private var fiberLight: Color { Color(red: 0.97, green: 0.96, blue: 0.86) }
    private var fiberDark: Color { Color(red: 0.125, green: 0.165, blue: 0.17) }

    private func thread(at u: Double) -> WovenThread? {
        guard !threads.isEmpty else { return nil }
        return threads[min(threads.count - 1, Int(u * Double(threads.count)))]
    }

    private func drawCloth(in context: inout GraphicsContext, size: CGSize, geometry: FabricGeometry) {
        guard geometry.reveal > 0, size.width > 0, size.height > 0 else { return }
        let layout = Self.fittedLayout(in: size)
        context.translateBy(x: layout.offset.x, y: layout.offset.y)
        context.scaleBy(x: layout.scale, y: layout.scale)

        var shadow = context
        shadow.addFilter(.blur(radius: 10))
        let shadowAlpha = 0.105 * min(1, geometry.reveal * 2)
        shadow.fill(Path(ellipseIn: CGRect(x: 70, y: 282, width: 234, height: 16)),
                    with: .color(fiberDark.opacity(shadowAlpha)))

        drawColorBands(in: &context, geometry: geometry)
        drawWarp(in: &context, geometry: geometry)
        drawWeft(in: &context, geometry: geometry)
        drawHistory(in: &context, geometry: geometry)
        drawLooseEnds(in: &context, geometry: geometry)
    }

    private func drawColorBands(in context: inout GraphicsContext, geometry: FabricGeometry) {
        // Narrow translucent ribbons supply body under the individual fibers.
        // Unfinished lanes stay open and pale instead of becoming solid cloth.
        let count = 48
        for index in 0..<count {
            let u0 = Double(index) / Double(count)
            let u1 = Double(index + 1) / Double(count)
            let item = thread(at: (u0 + u1) / 2)
            let completed = item?.completed == true
            let color = completed ? item!.color : neutralThread
            let end = min(geometry.visibleLength(at: u0), geometry.visibleLength(at: u1))
            guard end > 0 else { continue }
            var ribbon = Path()
            ribbon.move(to: geometry.point(u0, 0))
            ribbon.addLine(to: geometry.point(u1, 0))
            for step in 1...32 { ribbon.addLine(to: geometry.point(u1, end * Double(step) / 32)) }
            for step in (0...32).reversed() { ribbon.addLine(to: geometry.point(u0, end * Double(step) / 32)) }
            ribbon.closeSubpath()
            let density = completed ? 0.38 : 0.095
            context.fill(ribbon, with: .linearGradient(
                Gradient(stops: [
                    .init(color: color.opacity(density * 0.75), location: 0),
                    .init(color: color.opacity(density), location: 0.3),
                    .init(color: color.opacity(density * 0.5), location: 0.62),
                    .init(color: color.opacity(density * 0.9), location: 1)
                ]),
                startPoint: geometry.point((u0 + u1) / 2, 0),
                endPoint: geometry.point((u0 + u1) / 2, 1)
            ))
        }
    }

    private func drawWarp(in context: inout GraphicsContext, geometry: FabricGeometry) {
        let fiberCount = 108
        for index in 0...fiberCount {
            let u = Double(index) / Double(fiberCount)
            let end = geometry.visibleLength(at: u)
            guard end > 0 else { continue }
            let item = thread(at: u)
            let completed = item?.completed == true
            let color = completed ? item!.color : neutralThread
            var fiber = Path()
            for step in 0...64 {
                let v = end * Double(step) / 64
                var point = geometry.point(u, v)
                // Subpixel interlacing stays deterministic as the cloth moves.
                point.x += sin(v * .pi * 176 + Double(index % 2) * .pi) * 0.13
                if step == 0 { fiber.move(to: point) } else { fiber.addLine(to: point) }
            }
            let width = completed ? (index.isMultiple(of: 3) ? 1.32 : 0.85) : 0.67
            context.stroke(fiber, with: .color(color.opacity(completed ? 0.87 : 0.61)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round))
            if index.isMultiple(of: 3) {
                context.stroke(fiber, with: .linearGradient(
                    Gradient(stops: [
                        .init(color: fiberLight.opacity(0.08), location: 0),
                        .init(color: fiberLight.opacity(0.62), location: 0.32),
                        .init(color: fiberLight.opacity(0.1), location: 0.57),
                        .init(color: fiberLight.opacity(0.44), location: 0.87),
                        .init(color: fiberLight.opacity(0.1), location: 1)
                    ]), startPoint: geometry.point(u, 0), endPoint: geometry.point(u, 1)
                ), lineWidth: 0.29)
            }
        }
    }

    private func drawWeft(in context: inout GraphicsContext, geometry: FabricGeometry) {
        for row in 0..<90 {
            let v = Double(row) / 89
            let visibleWidth = geometry.visibleWidth(at: v)
            guard visibleWidth > 0 else { continue }
            var path = Path()
            for step in 0...80 {
                let u = visibleWidth * Double(step) / 80
                var point = geometry.point(u, v)
                point.y += sin(u * .pi * 216 + Double(row % 2) * .pi) * 0.13
                if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            let light = row % 6 < 3
            context.stroke(path, with: .color((light ? fiberLight : fiberDark).opacity(light ? 0.56 : 0.18)),
                           style: StrokeStyle(lineWidth: light ? 0.68 : 0.55, lineCap: .round))
        }

        // Short satin catchlights follow the surface rather than the screen.
        for row in stride(from: 11, through: 76, by: 15) {
            let v = Double(row) / 89
            let end = min(0.69, geometry.visibleWidth(at: v))
            guard end > 0.15 else { continue }
            var highlight = Path()
            for step in 0...42 {
                let u = 0.15 + (end - 0.15) * Double(step) / 42
                let point = geometry.point(u, v)
                if step == 0 { highlight.move(to: point) } else { highlight.addLine(to: point) }
            }
            context.stroke(highlight, with: .color(fiberLight.opacity(0.67)), lineWidth: 0.78)
        }
    }

    private func drawHistory(in context: inout GraphicsContext, geometry: FabricGeometry) {
        guard !threads.isEmpty else { return }
        for (lane, item) in threads.enumerated() {
            let history = Array(item.history.suffix(14))
            guard !history.isEmpty else { continue }
            let u = (Double(lane) + 0.5) / Double(threads.count)
            let halfKnot = min(0.018, 0.16 / Double(threads.count))
            for (day, completed) in history.enumerated() where completed {
                let v = 0.1 + 0.8 * (Double(day) + 0.5) / Double(history.count)
                guard v < geometry.visibleLength(at: u + halfKnot) else { continue }
                var stitch = Path()
                stitch.move(to: geometry.point(u - halfKnot, v + 0.004))
                stitch.addCurve(to: geometry.point(u + halfKnot, v - 0.004),
                                control1: geometry.point(u - halfKnot * 0.3, v - 0.008),
                                control2: geometry.point(u + halfKnot * 0.3, v + 0.008))
                context.stroke(stitch, with: .color(item.color.opacity(item.completed ? 0.8 : 0.48)),
                               style: StrokeStyle(lineWidth: 1.25, lineCap: .round))
                var crossing = Path()
                crossing.move(to: geometry.point(u - halfKnot * 0.45, v - 0.004))
                crossing.addLine(to: geometry.point(u + halfKnot * 0.45, v + 0.004))
                context.stroke(crossing, with: .color(fiberLight.opacity(0.8)), lineWidth: 0.6)
            }
        }
    }

    private func drawLooseEnds(in context: inout GraphicsContext, geometry: FabricGeometry) {
        for index in stride(from: 3, through: 103, by: 5) {
            let u = Double(index) / 108
            guard geometry.visibleLength(at: u) > 0.998 else { continue }
            let start = geometry.point(u, 1)
            let item = thread(at: u)
            let color = item?.completed == true ? item!.color : neutralThread
            let length = 7.5 + Double(index % 4) * 1.55
            let sway = sin(geometry.phase * 0.8 + u * 5) * 1.2 + Double(geometry.tug.width) * 4
            var end = Path()
            end.move(to: start)
            end.addCurve(to: CGPoint(x: start.x + 1.5 + sway, y: start.y + length),
                         control1: CGPoint(x: start.x - 1.8, y: start.y + 3),
                         control2: CGPoint(x: start.x - 1.8 + sway, y: start.y + length - 2))
            context.stroke(end, with: .color(color.opacity(0.64)),
                           style: StrokeStyle(lineWidth: 0.63, lineCap: .round))
        }
    }
}

private struct FabricGeometry {
    let phase: Double
    let tug: CGSize
    let pulseAge: Double
    let tightenedLanes: [Int]
    let laneCount: Int
    let reveal: Double

    func visibleLength(at u: Double) -> Double {
        min(1, max(0, (reveal - u * 0.12) / 0.88))
    }

    func visibleWidth(at v: Double) -> Double {
        min(1, max(0, (reveal - v * 0.88) / 0.12))
    }

    func point(_ u: Double, _ v: Double) -> CGPoint {
        // The same saddle-like surface used by the approved vector blueprint.
        var x = 31 + 251 * u + 33 * sin(.pi * v) + 17 * sin(.pi * u) * sin(2 * .pi * v)
        var y = 38 + 209 * v - 43 * u * cos(.pi * v) + 22 * sin(2 * .pi * u + .pi * v)

        let edge = sin(.pi * v)
        let breathing = sin(phase * 0.62)
        x += edge * sin(.pi * u) * breathing * 1.5
        y += sin(phase * 0.71 + u * 2.4) * edge * 1.65
        x += Double(tug.width) * (edge * 9 + (u - 0.5) * 5)
        y += Double(tug.height) * sin(.pi * u) * (v - 0.4) * 13

        if pulseAge > 0, pulseAge < 0.5 {
            let progress = pulseAge / 0.5
            let envelope = sin(.pi * progress) * (1 - progress * 0.35)
            var laneWeight = 0.0
            for lane in tightenedLanes {
                let center = (Double(lane) + 0.5) / Double(laneCount)
                laneWeight = max(laneWeight, exp(-pow((u - center) * 5.5, 2)))
            }
            let wave = sin(v * .pi * 2.2 - progress * .pi * 2)
            y += wave * envelope * laneWeight * 6
            x += cos(v * .pi * 2.2 - progress * .pi * 2) * envelope * laneWeight * 2
        }
        return CGPoint(x: x, y: y)
    }
}
