import SwiftUI

/// Where each step goes on the board. Up to four steps fit on one row, and more wrap onto a second row.
struct WhiteboardLayout {
    static let nodeSize = CGSize(width: 132, height: 58)
    static let columnGap: CGFloat = 44
    static let rowGap: CGFloat = 44
    static let margin: CGFloat = 26
    static let titleHeight: CGFloat = 46
    static let bottomPadding: CGFloat = 24
    static let trayHeight: CGFloat = 16

    let perRow: Int
    let boardSize: CGSize

    /// The board plus the marker tray underneath it.
    var totalHeight: CGFloat {
        boardSize.height + Self.trayHeight
    }

    init(count: Int) {
        perRow = count <= 4 ? max(count, 1) : (count + 1) / 2
        let rows = CGFloat((max(count, 1) + perRow - 1) / perRow)
        let columns = CGFloat(perRow)
        boardSize = CGSize(
            width: Self.margin * 2 + columns * Self.nodeSize.width + (columns - 1) * Self.columnGap,
            height: Self.titleHeight + rows * Self.nodeSize.height + (rows - 1) * Self.rowGap + Self.bottomPadding
        )
    }

    func row(of index: Int) -> Int {
        index / perRow
    }

    func frame(of index: Int) -> CGRect {
        CGRect(
            x: Self.margin + CGFloat(index % perRow) * (Self.nodeSize.width + Self.columnGap),
            y: Self.titleHeight + CGFloat(row(of: index)) * (Self.nodeSize.height + Self.rowGap),
            width: Self.nodeSize.width,
            height: Self.nodeSize.height
        )
    }
}

private enum Marker {
    static let blue = Color(red: 0.12, green: 0.38, blue: 0.80)
    static let red = Color(red: 0.84, green: 0.25, blue: 0.22)
    static let green = Color(red: 0.14, green: 0.60, blue: 0.36)
    static let ink = Color(red: 0.13, green: 0.15, blue: 0.18)
}

/// A whiteboard with the steps sketched on it in marker, as if someone drew it while explaining.
struct WhiteboardView: View {
    let steps: [String]

    private let ink = StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
    private let thin = StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round)

    private var layout: WhiteboardLayout {
        WhiteboardLayout(count: steps.count)
    }

    var body: some View {
        let board = layout.boardSize
        ZStack(alignment: .topLeading) {
            surface(board)
            sketches(board)
            writing(board)
            tray(board)
        }
        .frame(width: board.width, height: layout.totalHeight, alignment: .topLeading)
    }

    // MARK: - The board

    private func surface(_ board: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        let paper = LinearGradient(
            colors: [Color(white: 0.99), Color(red: 0.93, green: 0.94, blue: 0.92)],
            startPoint: .top,
            endPoint: .bottom
        )
        let frame = LinearGradient(
            colors: [Color(white: 0.87), Color(white: 0.62)],
            startPoint: .top,
            endPoint: .bottom
        )
        return shape
            .fill(paper)
            .overlay(shape.strokeBorder(frame, lineWidth: 7))
            .frame(width: board.width, height: board.height)
    }

    private func tray(_ board: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(white: 0.82), Color(white: 0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 250, height: 8)

            HStack(spacing: 8) {
                pen(Marker.blue)
                pen(Marker.red)
                pen(Marker.ink)
                eraser
            }
            .offset(y: -8)
        }
        .position(x: board.width / 2, y: board.height + 5)
    }

    private func pen(_ color: Color) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.95)).frame(width: 8, height: 8)
            Capsule().fill(color).frame(width: 26, height: 8)
        }
        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
    }

    private var eraser: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.3))
            .frame(width: 30, height: 10)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.7)).frame(height: 4)
            }
            .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
    }

    // MARK: - Marker drawing

    private func sketches(_ board: CGSize) -> some View {
        Canvas { context, _ in
            drawSmudges(&context)
            drawTitleUnderline(&context)
            drawBoxes(&context)
            drawArrows(&context)
        }
        .frame(width: board.width, height: board.height)
    }

    /// Faint streaks, like marker that was never fully wiped off.
    private func drawSmudges(_ context: inout GraphicsContext) {
        let board = layout.boardSize
        func spot(_ horizontal: CGFloat, _ vertical: CGFloat) -> CGPoint {
            CGPoint(x: board.width * horizontal, y: board.height * vertical)
        }

        let streaks: [(start: CGPoint, end: CGPoint)] = [
            (spot(0.15, 0.82), spot(0.4, 0.74)),
            (spot(0.6, 0.2), spot(0.88, 0.3)),
            (spot(0.5, 0.9), spot(0.78, 0.86))
        ]
        let smudge = StrokeStyle(lineWidth: 22, lineCap: .round)
        for (index, streak) in streaks.enumerated() {
            let path = Sketch.line(from: streak.start, to: streak.end, wobble: 6, seed: 200 + index)
            context.stroke(path, with: .color(Color.gray.opacity(0.07)), style: smudge)
        }
    }

    private func drawTitleUnderline(_ context: inout GraphicsContext) {
        let margin = WhiteboardLayout.margin
        let first = Sketch.line(
            from: CGPoint(x: margin, y: 38),
            to: CGPoint(x: margin + 130, y: 38),
            wobble: 3,
            seed: 90
        )
        let second = Sketch.line(
            from: CGPoint(x: margin + 10, y: 42),
            to: CGPoint(x: margin + 112, y: 41),
            wobble: 3,
            seed: 91
        )
        context.stroke(first, with: .color(Marker.green), style: ink)
        context.stroke(second, with: .color(Marker.green.opacity(0.7)), style: thin)
    }

    private func drawBoxes(_ context: inout GraphicsContext) {
        for index in steps.indices {
            let frame = layout.frame(of: index)
            context.stroke(Sketch.rectangle(frame, seed: index * 3), with: .color(Marker.blue), style: ink)
            context.stroke(
                Sketch.rectangle(frame.insetBy(dx: 1.5, dy: 1.5), seed: index * 3 + 1),
                with: .color(Marker.blue.opacity(0.5)),
                style: thin
            )

            // A red number circled in the corner, over a patch of clean board so the box lines don't show through.
            let badge = CGPoint(x: frame.minX + 2, y: frame.minY + 2)
            let patch = CGRect(x: badge.x - 12, y: badge.y - 12, width: 24, height: 24)
            context.fill(Path(ellipseIn: patch), with: .color(Color(white: 0.985)))
            let circle = Sketch.circle(center: badge, radius: 12, seed: 40 + index)
            context.stroke(circle, with: .color(Marker.red), style: ink)
        }
    }

    private func drawArrows(_ context: inout GraphicsContext) {
        for index in 0..<max(steps.count - 1, 0) {
            let from = layout.frame(of: index)
            let to = layout.frame(of: index + 1)
            let path: Path
            if layout.row(of: index) == layout.row(of: index + 1) {
                path = Sketch.arrow(
                    from: CGPoint(x: from.maxX + 7, y: from.midY),
                    to: CGPoint(x: to.minX - 9, y: to.midY),
                    seed: 60 + index
                )
            } else {
                path = Sketch.curvedArrow(
                    from: CGPoint(x: from.midX, y: from.maxY + 7),
                    to: CGPoint(x: to.midX, y: to.minY - 9),
                    bend: 36,
                    seed: 60 + index
                )
            }
            context.stroke(path, with: .color(Marker.ink), style: ink)
        }
    }

    // MARK: - Handwriting

    private func writing(_ board: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            Text("How it works")
                .font(marker(21))
                .foregroundStyle(Marker.ink)
                .position(x: WhiteboardLayout.margin + 64, y: 22)

            ForEach(steps.indices, id: \.self) { index in
                let frame = layout.frame(of: index)

                Text(steps[index])
                    .font(marker(14))
                    .foregroundStyle(Marker.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
                    .frame(width: frame.width - 24, height: frame.height - 10)
                    .position(x: frame.midX, y: frame.midY)

                Text("\(index + 1)")
                    .font(marker(13))
                    .foregroundStyle(Marker.red)
                    .position(x: frame.minX + 2, y: frame.minY + 2)
            }
        }
        .frame(width: board.width, height: board.height, alignment: .topLeading)
    }

    /// Marker Felt ships with macOS. If it is ever missing, SwiftUI falls back to the system font.
    private func marker(_ size: CGFloat) -> Font {
        .custom("MarkerFelt-Wide", size: size)
    }
}
