import SwiftUI

/// 数字滚动动画修饰符，实现平滑的数字过渡效果
struct AnimatableNumberModifier: AnimatableModifier {
    var number: Double
    var fontSize: CGFloat
    var fontWeight: Font.Weight
    
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(Int(number))")
            .font(.system(size: fontSize, weight: fontWeight, design: .rounded))
    }
}

/// BPM 显示组件，显示心率数值
struct BPMDisplayView: View {
    let bpm: Int
    let isConnected: Bool
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(bpm)")
                .foregroundColor(isConnected ? ColorTheme.bpmText : ColorTheme.disconnectedText)
                .modifier(AnimatableNumberModifier(
                    number: Double(bpm),
                    fontSize: scaledFontSize(base: 100),
                    fontWeight: .heavy
                ))
                .animation(.easeInOut(duration: 0.3), value: bpm)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue("\(bpm) 每分钟心跳")
            
            Text("bpm")
                .font(.system(size: scaledFontSize(base: 20), weight: .medium, design: .rounded))
                .foregroundColor(isConnected ? ColorTheme.secondaryText.opacity(0.6) : ColorTheme.disconnectedText.opacity(0.6))
                .accessibilityHidden(true)
        }
        .drawingGroup() // 优化文本渲染性能
    }
    
    /// 根据动态字体大小调整字体
    private func scaledFontSize(base: CGFloat) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            return base * 0.85
        case .medium:
            return base
        case .large:
            return base * 1.1
        case .xLarge:
            return base * 1.2
        case .xxLarge:
            return base * 1.3
        case .xxxLarge:
            return base * 1.4
        case .accessibility1, .accessibility2:
            return base * 1.5
        case .accessibility3, .accessibility4, .accessibility5:
            return base * 1.6
        @unknown default:
            return base
        }
    }
    
    /// VoiceOver 标签
    private var accessibilityLabel: String {
        if !isConnected {
            return "心率未连接"
        }
        return "当前心率"
    }
}

#Preview("Light Mode") {
    VStack(spacing: 40) {
        BPMDisplayView(bpm: 120, isConnected: true)
        BPMDisplayView(bpm: 0, isConnected: false)
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 40) {
        BPMDisplayView(bpm: 120, isConnected: true)
        BPMDisplayView(bpm: 0, isConnected: false)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
