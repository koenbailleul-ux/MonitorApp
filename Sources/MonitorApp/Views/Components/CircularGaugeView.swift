import SwiftUI

public struct CircularGaugeView: View {
    public let value: Double // 0.0 - 100.0
    public let title: String
    public let subtitle: String
    public let tintColor: Color
    public let size: CGFloat
    
    public init(
        value: Double,
        title: String,
        subtitle: String = "",
        tintColor: Color = .blue,
        size: CGFloat = 80
    ) {
        self.value = value
        self.title = title
        self.subtitle = subtitle
        self.tintColor = tintColor
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(tintColor.opacity(0.15), lineWidth: 7)
            
            // Progress arc
            Circle()
                .trim(from: 0.0, to: CGFloat(min(max(value / 100.0, 0.0), 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [tintColor.opacity(0.7), tintColor]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: value)
            
            // Centered Text
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: size * 0.12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}
