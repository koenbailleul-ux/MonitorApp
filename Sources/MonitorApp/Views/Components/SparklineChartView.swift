import SwiftUI

public struct SparklineChartView: View {
    public let data: [Double]
    public let lineColor: Color
    public let height: CGFloat
    public let maxValue: Double?
    
    public init(data: [Double], lineColor: Color = .blue, height: CGFloat = 45, maxValue: Double? = nil) {
        self.data = data
        self.lineColor = lineColor
        self.height = height
        self.maxValue = maxValue
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let points = normalizedPoints(in: proxy.size)
            
            ZStack {
                // Gradient Fill
                if points.count >= 2 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: proxy.size.height))
                        for pt in points {
                            path.addLine(to: pt)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: proxy.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [lineColor.opacity(0.35), lineColor.opacity(0.02)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                
                // Line
                if points.count >= 2 {
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            path.addLine(to: points[i])
                        }
                    }
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(height: height)
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let maxVal = maxValue ?? max(data.max() ?? 100.0, 1.0)
        let stepX = size.width / CGFloat(max(data.count - 1, 1))
        
        return data.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let clampedVal = max(0.0, min(value, maxVal))
            let y = size.height - (CGFloat(clampedVal / maxVal) * (size.height - 4)) - 2
            return CGPoint(x: x, y: y)
        }
    }
}
