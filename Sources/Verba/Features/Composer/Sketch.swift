import SwiftUI

/// Shapes that look drawn by hand with a marker: slightly wobbly lines, corners that overshoot, loose circles.
/// The wobble is seeded, so a shape looks identical every time it is drawn.
enum Sketch {
    private struct Noise {
        private var state: UInt64

        init(seed: Int) {
            state = UInt64(truncatingIfNeeded: seed &+ 1) &* 2_654_435_761
        }

        /// A repeatable value between -amount and +amount.
        mutating func next(_ amount: CGFloat) -> CGFloat {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let unit = CGFloat((state >> 33) % 2001) / 1000 - 1
            return unit * amount
        }
    }

    /// A slightly bowed line, like a quick stroke of a marker.
    static func line(from start: CGPoint, to end: CGPoint, wobble: CGFloat = 2.5, seed: Int) -> Path {
        var noise = Noise(seed: seed)
        let from = CGPoint(x: start.x + noise.next(1.2), y: start.y + noise.next(1.2))
        let to = CGPoint(x: end.x + noise.next(1.2), y: end.y + noise.next(1.2))
        let control = CGPoint(
            x: (start.x + end.x) / 2 + noise.next(wobble),
            y: (start.y + end.y) / 2 + noise.next(wobble)
        )

        var path = Path()
        path.move(to: from)
        path.addQuadCurve(to: to, control: control)
        return path
    }

    /// A box drawn as four separate strokes whose ends overshoot the corners.
    static func rectangle(_ rect: CGRect, seed: Int) -> Path {
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]

        var path = Path()
        for index in corners.indices {
            let start = corners[index]
            let end = corners[(index + 1) % corners.count]
            let extended = extend(start, end, by: 4)
            path.addPath(line(from: extended.start, to: extended.end, wobble: 2, seed: seed * 7 + index))
        }
        return path
    }

    /// A loose, slightly uneven circle.
    static func circle(center: CGPoint, radius: CGFloat, seed: Int) -> Path {
        var noise = Noise(seed: seed)
        let rect = CGRect(
            x: center.x - radius + noise.next(1.5),
            y: center.y - radius + noise.next(1.5),
            width: radius * 2 + noise.next(2),
            height: radius * 2 + noise.next(2)
        )
        return Path(ellipseIn: rect)
    }

    /// A line with a hand-drawn arrowhead at the end.
    static func arrow(from start: CGPoint, to end: CGPoint, seed: Int) -> Path {
        var path = line(from: start, to: end, wobble: 3, seed: seed)
        let angle = atan2(end.y - start.y, end.x - start.x)
        path.addPath(arrowHead(at: end, angle: angle, seed: seed))
        return path
    }

    /// A bent arrow, used to carry the flow from the end of one row to the start of the next.
    static func curvedArrow(from start: CGPoint, to end: CGPoint, bend: CGFloat, seed: Int) -> Path {
        var noise = Noise(seed: seed)
        let control = CGPoint(
            x: (start.x + end.x) / 2 + bend + noise.next(3),
            y: (start.y + end.y) / 2 + noise.next(3)
        )

        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        path.addPath(arrowHead(at: end, angle: atan2(end.y - control.y, end.x - control.x), seed: seed))
        return path
    }

    // MARK: - Helpers

    private static func arrowHead(at tip: CGPoint, angle: CGFloat, seed: Int) -> Path {
        var path = Path()
        for (index, side) in [CGFloat(-1), CGFloat(1)].enumerated() {
            let direction = angle + .pi + side * 0.5
            let wingTip = CGPoint(x: tip.x + cos(direction) * 13, y: tip.y + sin(direction) * 13)
            path.addPath(line(from: tip, to: wingTip, wobble: 1, seed: seed + 11 + index))
        }
        return path
    }

    private static func extend(
        _ start: CGPoint,
        _ end: CGPoint,
        by amount: CGFloat
    ) -> (start: CGPoint, end: CGPoint) {
        let deltaX = end.x - start.x
        let deltaY = end.y - start.y
        let length = max(hypot(deltaX, deltaY), 0.001)
        let unitX = deltaX / length * amount
        let unitY = deltaY / length * amount
        return (
            CGPoint(x: start.x - unitX, y: start.y - unitY),
            CGPoint(x: end.x + unitX, y: end.y + unitY)
        )
    }
}
