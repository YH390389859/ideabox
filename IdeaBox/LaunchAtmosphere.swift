import SwiftUI

/// A finite, deterministic accent layer driven by the introduction's single clock.
/// Geometry uses a 360-point canvas, with the opening of the box at (180, 195).
struct LaunchAtmosphere: View {
    let elapsed: Double

    private let lilac = Color(red: 0.55, green: 0.51, blue: 0.83)
    private let sage = Color(red: 0.58, green: 0.69, blue: 0.59)
    private let apricot = Color(red: 0.81, green: 0.65, blue: 0.52)

    var body: some View {
        Canvas { context, _ in
            let visibility = smooth(0.2, 0.48, elapsed) * (1 - smooth(2.6, 3.2, elapsed))
            guard visibility > 0 else { return }
            context.opacity = visibility
            drawOrbits(in: &context)
            drawGatheringLights(in: &context)
            drawAfterglow(in: &context)
        }
        .frame(width: 360, height: 360)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawOrbits(in context: inout GraphicsContext) {
        let drawn = smooth(0.2, 0.94, elapsed)
        let retained = 1 - smooth(1.65, 2.62, elapsed)
        let tracks: [(Double, Double, Double, Double, Double, Color)] = [
            (141, 87, -0.39, 2.32, 2.54, lilac),
            (127, 100, 0.44, -0.9, 2.04, sage),
            (145, 104, -0.39, 0.14, 0.53, apricot)
        ]
        for (index, track) in tracks.enumerated() {
            let path = orbitPath(rx: track.0, ry: track.1, tilt: track.2,
                                 start: track.3, length: track.4 * drawn)
            context.stroke(path, with: .color(track.5.opacity(0.26 * retained)),
                           style: StrokeStyle(lineWidth: index == 2 ? 0.7 : 0.85, lineCap: .round))
            // A small bright tip gives each line the feeling of an ink stroke.
            let tipFade = smooth(0.22, 0.4, elapsed) * (1 - smooth(0.82, 1.2, elapsed))
            let tip = orbitPoint(rx: track.0, ry: track.1, tilt: track.2,
                                 angle: track.3 + track.4 * drawn)
            dot(at: tip, radius: 1.6, color: track.5.opacity(tipFade * 0.8), in: &context)
        }
    }

    private func drawGatheringLights(in context: inout GraphicsContext) {
        // Starts and control points sit around the mark, leaving its face unobstructed.
        let routes: [(CGPoint, CGPoint, CGPoint, Double, Color)] = [
            (CGPoint(x: 47, y: 165), CGPoint(x: 56, y: 261), CGPoint(x: 136, y: 244), 0.64, lilac),
            (CGPoint(x: 302, y: 111), CGPoint(x: 335, y: 213), CGPoint(x: 222, y: 255), 0.73, sage),
            (CGPoint(x: 91, y: 63), CGPoint(x: 25, y: 158), CGPoint(x: 122, y: 240), 0.85, apricot),
            (CGPoint(x: 311, y: 201), CGPoint(x: 266, y: 283), CGPoint(x: 221, y: 236), 0.94, lilac),
            (CGPoint(x: 53, y: 230), CGPoint(x: 114, y: 286), CGPoint(x: 173, y: 251), 1.02, sage),
            (CGPoint(x: 275, y: 71), CGPoint(x: 340, y: 160), CGPoint(x: 248, y: 228), 1.09, apricot)
        ]
        let destination = CGPoint(x: 180, y: 195)
        for (index, route) in routes.enumerated() {
            let progress = clamp((elapsed - route.3) / 0.57)
            guard progress > 0, progress < 1 else { continue }
            let travel = progress * progress * (2 - progress)
            let opacity = smooth(0, 0.17, progress) * (1 - smooth(0.73, 1, progress))
            // Three diminishing points form a restrained comet tail along the same curve.
            for tail in (0...3).reversed() {
                let position = cubic(route.0, route.1, route.2, destination,
                                     at: max(0, travel - Double(tail) * 0.028))
                let radius = tail == 0 ? (index.isMultiple(of: 2) ? 2.0 : 1.45) : 1.0
                let strength = tail == 0 ? 0.8 : 0.16 / Double(tail)
                dot(at: position, radius: radius, color: route.4.opacity(opacity * strength), in: &context)
            }
        }
    }

    private func drawAfterglow(in context: inout GraphicsContext) {
        let bloom = smooth(1.68, 2.4, elapsed)
        let ringOpacity = smooth(1.68, 1.9, elapsed) * (1 - smooth(2.04, 2.64, elapsed))
        // Open arcs emerge sideways from the star, never forming a loading ring.
        for side in 0..<2 {
            let radius = 34 + bloom * 93
            var arc = Path()
            let start = side == 0 ? -0.48 : Double.pi - 0.46
            for step in 0...32 {
                let angle = start + Double(step) / 32 * 0.76
                let point = CGPoint(x: 180 + cos(angle) * radius,
                                    y: 105 + sin(angle) * radius * 0.7)
                if step == 0 { arc.move(to: point) } else { arc.addLine(to: point) }
            }
            context.stroke(arc, with: .color(lilac.opacity(ringOpacity * 0.21)),
                           style: StrokeStyle(lineWidth: 0.75, lineCap: .round))
        }

        let stars: [(CGPoint, Double, Double, Color)] = [
            (CGPoint(x: 76, y: 103), 1.76, 5.0, lilac),
            (CGPoint(x: 271, y: 130), 1.87, 4.2, sage),
            (CGPoint(x: 237, y: 57), 1.96, 3.4, apricot),
            (CGPoint(x: 108, y: 265), 1.81, 2.7, lilac)
        ]
        for star in stars {
            let life = smooth(star.1, star.1 + 0.2, elapsed) * (1 - smooth(star.1 + 0.32, star.1 + 0.84, elapsed))
            let position = CGPoint(x: star.0.x, y: star.0.y - smooth(star.1, star.1 + 0.8, elapsed) * 5)
            context.fill(spark(at: position, radius: star.2 * (0.7 + life * 0.3)),
                         with: .color(star.3.opacity(life * 0.7)))
        }
    }

    private func orbitPath(rx: Double, ry: Double, tilt: Double, start: Double, length: Double) -> Path {
        var path = Path()
        for step in 0...72 {
            let point = orbitPoint(rx: rx, ry: ry, tilt: tilt, angle: start + length * Double(step) / 72)
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    private func orbitPoint(rx: Double, ry: Double, tilt: Double, angle: Double) -> CGPoint {
        let x = cos(angle) * rx
        let y = sin(angle) * ry
        return CGPoint(x: 180 + x * cos(tilt) - y * sin(tilt),
                       y: 170 + x * sin(tilt) + y * cos(tilt))
    }

    private func dot(at point: CGPoint, radius: Double, color: Color, in context: inout GraphicsContext) {
        context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius,
                                           width: radius * 2, height: radius * 2)), with: .color(color))
    }

    private func spark(at point: CGPoint, radius: Double) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: point.x, y: point.y - radius))
        path.addQuadCurve(to: CGPoint(x: point.x + radius * 0.72, y: point.y), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y + radius), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x - radius * 0.72, y: point.y), control: point)
        path.addQuadCurve(to: CGPoint(x: point.x, y: point.y - radius), control: point)
        path.closeSubpath()
        return path
    }

    private func cubic(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint, at t: Double) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * u * a.x + 3 * u * u * t * b.x + 3 * u * t * t * c.x + t * t * t * d.x,
                       y: u * u * u * a.y + 3 * u * u * t * b.y + 3 * u * t * t * c.y + t * t * t * d.y)
    }

    private func clamp(_ value: Double) -> Double { min(1, max(0, value)) }

    private func smooth(_ start: Double, _ end: Double, _ value: Double) -> Double {
        let t = clamp((value - start) / (end - start))
        return t * t * (3 - 2 * t)
    }
}
