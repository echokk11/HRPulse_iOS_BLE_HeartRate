import SwiftUI

struct AerobicZoneView: View {
    let bpm: Int
    let age: Int
    let isConnected: Bool
    
    private let belowSegmentRatio: CGFloat = 0.32
    private let zoneSegmentRatio: CGFloat = 0.44
    private let aboveSegmentRatio: CGFloat = 0.24
    
    private var maxHeartRate: Double {
        let estimate = 208.0 - 0.7 * Double(age)
        return max(120, min(205, estimate))
    }
    
    private var zoneRange: ClosedRange<Double> {
        let lower = maxHeartRate * 0.6
        let upper = maxHeartRate * 0.75
        return lower...upper
    }
    
    private var zoneStatus: ZoneStatus {
        guard bpm > 0 else { return .waiting }
        let value = Double(bpm)
        if value < zoneRange.lowerBound { return .below }
        if value > zoneRange.upperBound { return .above }
        return .inRange
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let capsuleHeight: CGFloat = 36
            let startX = clampedPosition(width * zoneStartRatio, width: width)
            let endX = clampedPosition(width * (zoneStartRatio + zoneWidthRatio), width: width)
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackGradient)
                        .frame(height: capsuleHeight)
                    
                    Capsule()
                        .fill(targetGradient)
                        .frame(width: width * zoneWidthRatio, height: capsuleHeight)
                        .offset(x: width * zoneStartRatio)
                        .opacity(0.85)
                    
                    Text(pointerEmoji)
                        .font(.system(size: 26))
                        .frame(width: 36, height: 36)
                        .background(pointerBackground, in: Circle())
                        .offset(x: indicatorOffset(width: width))
                        .animation(.easeInOut(duration: 0.3), value: bpm)
                }
                .frame(height: capsuleHeight)
                
                if zoneStatus != .waiting {
                    Text(startValueText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.gray.opacity(0.75))
                        .position(x: startX, y: capsuleHeight + 12)
                        .allowsHitTesting(false)
                    Text(endValueText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Color.gray.opacity(0.75))
                        .position(x: endX, y: capsuleHeight + 12)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: 64)
    }
    
    private func indicatorOffset(width: CGFloat) -> CGFloat {
        guard maxHeartRate > 0, bpm > 0 else { return 0 }
        let pointerWidth: CGFloat = 36
        let ratio = positionRatio(for: Double(bpm))
        let clamped = max(0, min(1, ratio))
        let travel = width - pointerWidth
        return clamped * travel
    }
    
    private var zoneStartRatio: CGFloat {
        let total = belowSegmentRatio + zoneSegmentRatio + aboveSegmentRatio
        return total > 0 ? belowSegmentRatio / total : 0.25
    }
    
    private var zoneWidthRatio: CGFloat {
        let total = belowSegmentRatio + zoneSegmentRatio + aboveSegmentRatio
        return total > 0 ? zoneSegmentRatio / total : 0.5
    }
    
    private enum ZoneStatus {
        case waiting
        case below
        case inRange
        case above
    }
    
    private var trackGradient: LinearGradient {
        if zoneStatus == .waiting {
            return LinearGradient(colors: [ColorTheme.secondaryBackground, ColorTheme.secondaryBackground], startPoint: .leading, endPoint: .trailing)
        }
        return LinearGradient(
            colors: [
                Color.blue.opacity(0.18),
                Color.green.opacity(0.35),
                Color.red.opacity(0.35)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var targetGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.3), Color.green.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var pointerEmoji: String {
        switch zoneStatus {
        case .waiting:
            return isConnected ? "⌛️" : "📡"
        case .below:
            return "😴"
        case .inRange:
            return "😄"
        case .above:
            return "😵"
        }
    }
    
    private var pointerBackground: Color {
        switch zoneStatus {
        case .waiting:
            return Color.white.opacity(0.35)
        case .below:
            return Color.blue.opacity(0.25)
        case .inRange:
            return Color.green.opacity(0.25)
        case .above:
            return Color.red.opacity(0.25)
        }
    }
    
    private func positionRatio(for bpm: Double) -> CGFloat {
        guard maxHeartRate > 0, bpm > 0 else { return 0 }
        let lower = zoneRange.lowerBound
        let upper = zoneRange.upperBound
        let total = belowSegmentRatio + zoneSegmentRatio + aboveSegmentRatio
        let belowWidth = total > 0 ? belowSegmentRatio / total : 0.25
        let zoneWidth = total > 0 ? zoneSegmentRatio / total : 0.5
        let zoneEnd = belowWidth + zoneWidth
        if bpm <= lower {
            guard lower > 0 else { return 0 }
            let relative = bpm / lower
            return CGFloat(min(max(relative, 0), 1)) * belowWidth
        } else if bpm <= upper {
            let span = upper - lower
            let relative = span > 0 ? (bpm - lower) / span : 0
            return belowWidth + CGFloat(min(max(relative, 0), 1)) * zoneWidth
        } else {
            let remaining = maxHeartRate - upper
            guard remaining > 0 else { return min(1, zoneEnd) }
            let relative = min(1, (bpm - upper) / remaining)
            let aboveWidth = 1 - zoneEnd
            return zoneEnd + CGFloat(relative) * aboveWidth
        }
    }
    
    private var startValueText: String {
        let value = Int(zoneRange.lowerBound.rounded())
        return "\(value)"
    }
    
    private var endValueText: String {
        let value = Int(zoneRange.upperBound.rounded())
        return "\(value)"
    }
    
    private func clampedPosition(_ x: CGFloat, width: CGFloat) -> CGFloat {
        return max(0, min(width, x))
    }
}

#Preview {
    VStack(spacing: 20) {
        AerobicZoneView(bpm: 95, age: 32, isConnected: true)
        AerobicZoneView(bpm: 140, age: 32, isConnected: true)
        AerobicZoneView(bpm: 0, age: 32, isConnected: false)
    }
    .padding()
}
