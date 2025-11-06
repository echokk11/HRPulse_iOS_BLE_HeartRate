import SwiftUI

struct AerobicZoneView: View {
    let bpm: Int
    let age: Int
    let isConnected: Bool
    
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
        }
        .frame(height: 48)
    }
    
    private func indicatorOffset(width: CGFloat) -> CGFloat {
        guard maxHeartRate > 0, bpm > 0 else { return 0 }
        let pointerWidth: CGFloat = 36
        let normalized = Double(bpm) / maxHeartRate
        let clamped = max(0, min(1, normalized))
        let travel = width - pointerWidth
        return CGFloat(clamped) * travel
    }
    
    private var zoneStartRatio: CGFloat {
        guard maxHeartRate > 0 else { return 0 }
        return CGFloat(zoneRange.lowerBound / maxHeartRate)
    }
    
    private var zoneWidthRatio: CGFloat {
        guard maxHeartRate > 0 else { return 0 }
        let span = zoneRange.upperBound - zoneRange.lowerBound
        return CGFloat(span / maxHeartRate)
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
}

#Preview {
    VStack(spacing: 20) {
        AerobicZoneView(bpm: 95, age: 32, isConnected: true)
        AerobicZoneView(bpm: 140, age: 32, isConnected: true)
        AerobicZoneView(bpm: 0, age: 32, isConnected: false)
    }
    .padding()
}
