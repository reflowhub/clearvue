import SwiftUI

struct TouchTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var touchedCells: Set<Int> = []

    private let columns = 6
    private let rows = 10
    private var totalCells: Int { columns * rows }

    var body: some View {
        ZStack {
            Color(red: 0x0A/255, green: 0x0A/255, blue: 0x0A/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TouchGridView(
                    columns: columns,
                    rows: rows,
                    touchedCells: $touchedCells
                )

                HStack {
                    Text("\(touchedCells.count) / \(totalCells)")
                        .font(.subheadline)
                        .foregroundColor(Theme.textMuted)
                        .monospacedDigit()

                    Spacer()

                    Button("Fail") {
                        onComplete(.fail, nil)
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(red: 1, green: 0x45/255, blue: 0x3A/255))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .ignoresSafeArea()
        .onChange(of: touchedCells.count) { newCount in
            if newCount >= totalCells {
                onComplete(.pass, "All \(totalCells) cells touched")
            }
        }
    }
}

struct TouchGridView: UIViewRepresentable {
    let columns: Int
    let rows: Int
    @Binding var touchedCells: Set<Int>

    func makeUIView(context: Context) -> TouchGridUIView {
        let view = TouchGridUIView()
        view.columns = columns
        view.rows = rows
        view.onCellTouched = { index in
            DispatchQueue.main.async {
                touchedCells.insert(index)
            }
        }
        view.isMultipleTouchEnabled = true
        return view
    }

    func updateUIView(_ uiView: TouchGridUIView, context: Context) {
        uiView.touchedCells = touchedCells
        uiView.setNeedsDisplay()
    }
}

class TouchGridUIView: UIView {
    var columns = 4
    var rows = 6
    var touchedCells: Set<Int> = []
    var onCellTouched: ((Int) -> Void)?

    private let gap: CGFloat = 2
    private let untouchedColor = UIColor(red: 0x1D/255, green: 0x1D/255, blue: 0x1F/255, alpha: 1)
    private let touchedColor = UIColor(red: 0x30/255, green: 0xD1/255, blue: 0x58/255, alpha: 1)

    override func draw(_ rect: CGRect) {
        let cellWidth = (rect.width - gap * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight = (rect.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

        for row in 0..<rows {
            for col in 0..<columns {
                let index = row * columns + col
                let x = CGFloat(col) * (cellWidth + gap)
                let y = CGFloat(row) * (cellHeight + gap)
                let cellRect = CGRect(x: x, y: y, width: cellWidth, height: cellHeight)
                let path = UIBezierPath(roundedRect: cellRect, cornerRadius: 4)
                let color = touchedCells.contains(index) ? touchedColor : untouchedColor
                color.setFill()
                path.fill()
            }
        }
    }

    private func handleTouches(_ touches: Set<UITouch>) {
        let cellWidth = (bounds.width - gap * CGFloat(columns - 1)) / CGFloat(columns)
        let cellHeight = (bounds.height - gap * CGFloat(rows - 1)) / CGFloat(rows)

        for touch in touches {
            let point = touch.location(in: self)
            let col = Int(point.x / (cellWidth + gap))
            let row = Int(point.y / (cellHeight + gap))
            if col >= 0 && col < columns && row >= 0 && row < rows {
                let index = row * columns + col
                if !touchedCells.contains(index) {
                    touchedCells.insert(index)
                    onCellTouched?(index)
                    setNeedsDisplay()
                }
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouches(touches)
    }
}
