import SwiftUI

public struct MemorySegment: Identifiable {
    public let id = UUID()
    public let name: String
    public let bytes: UInt64
    public let color: Color
    
    public init(name: String, bytes: UInt64, color: Color) {
        self.name = name
        self.bytes = bytes
        self.color = color
    }
}

public struct SegmentedProgressBar: View {
    public let segments: [MemorySegment]
    public let totalBytes: UInt64
    public let height: CGFloat
    
    public init(segments: [MemorySegment], totalBytes: UInt64, height: CGFloat = 10) {
        self.segments = segments
        self.totalBytes = max(totalBytes, 1)
        self.height = height
    }
    
    public var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    let fraction = CGFloat(segment.bytes) / CGFloat(totalBytes)
                    let width = max(0, fraction * geometry.size.width)
                    
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(segment.color)
                        .frame(width: width, height: height)
                }
            }
        }
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(nsColor: .separatorColor).opacity(0.3))
        )
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
