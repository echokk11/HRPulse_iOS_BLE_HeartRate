import SwiftUI

/// 心脏动画视图，包含缩放动画和脉冲波纹效果
struct HeartAnimationView: View {
    let isConnected: Bool
    let isBeating: Bool
    let beatDuration: Double
    let showPulseEffect: Bool
    let isLowPowerMode: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // 脉冲波纹效果（3 层）- 后台、低电量模式或减少动画时禁用
            if isConnected && showPulseEffect && !isLowPowerMode && !reduceMotion {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(ColorTheme.pulseColor(for: colorScheme), lineWidth: 3)
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .animation(
                            .easeOut(duration: beatDuration)
                                .delay(Double(index) * 0.1),
                            value: pulseScale
                        )
                }
                .drawingGroup() // 优化渲染性能
            }
            
            // 心脏图标 - 使用固定大小，确保不被裁切
            Image(systemName: "heart.fill")
                .font(.system(size: 200))
                .scaleEffect(heartScale)
                .animation(heartAnimation, value: isBeating)
                .foregroundColor(isConnected ? ColorTheme.heartConnected(for: colorScheme) : ColorTheme.heartDisconnected)
                .animation(.easeInOut(duration: 0.5), value: isConnected)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(accessibilityValue)
        }
        .onChange(of: isBeating) { beating in
            if beating && isConnected {
                // 触发脉冲波纹
                triggerPulse()
            }
        }
    }
    
    /// 心脏缩放比例（根据减少动画设置调整）
    private var heartScale: CGFloat {
        if reduceMotion {
            // 减少动画模式：使用简单的淡入淡出，不缩放
            return 1.0
        } else if isConnected && isBeating {
            return isLowPowerMode ? 1.06 : 1.10
        } else if isConnected {
            return isLowPowerMode ? 0.94 : 0.90
        } else {
            return 1.0
        }
    }
    
    /// 心脏动画（根据减少动画设置调整）
    private var heartAnimation: Animation? {
        if reduceMotion {
            // 减少动画模式：使用简单的线性动画
            return .linear(duration: 0.2)
        } else if isConnected {
            return isLowPowerMode ? 
                .easeInOut(duration: beatDuration * 0.4) : 
                .spring(
                    response: beatDuration * 0.4,
                    dampingFraction: 0.6,
                    blendDuration: 0
                )
        } else {
            return .easeInOut(duration: 0.3)
        }
    }
    
    /// VoiceOver 标签
    private var accessibilityLabel: String {
        return "心跳动画"
    }
    
    /// VoiceOver 值
    private var accessibilityValue: String {
        if !isConnected {
            return "未连接"
        }
        return isBeating ? "跳动中" : "静止"
    }
    
    /// 触发脉冲波纹动画
    private func triggerPulse() {
        // 后台或低电量模式时不触发波纹
        guard showPulseEffect && !isLowPowerMode else { return }
        
        // 重置波纹状态
        pulseScale = 1.0
        pulseOpacity = 0.6
        
        // 启动扩散动画
        withAnimation(.easeOut(duration: beatDuration)) {
            pulseScale = 2.5
            pulseOpacity = 0.0
        }
    }
}

#Preview("Light Mode") {
    VStack(spacing: 60) {
        HeartAnimationView(
            isConnected: true,
            isBeating: true,
            beatDuration: 0.8,
            showPulseEffect: true,
            isLowPowerMode: false
        )
        
        HeartAnimationView(
            isConnected: false,
            isBeating: false,
            beatDuration: 1.0,
            showPulseEffect: true,
            isLowPowerMode: false
        )
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 60) {
        HeartAnimationView(
            isConnected: true,
            isBeating: true,
            beatDuration: 0.8,
            showPulseEffect: true,
            isLowPowerMode: false
        )
        
        HeartAnimationView(
            isConnected: false,
            isBeating: false,
            beatDuration: 1.0,
            showPulseEffect: true,
            isLowPowerMode: false
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("Low Power Mode") {
    VStack(spacing: 60) {
        HeartAnimationView(
            isConnected: true,
            isBeating: true,
            beatDuration: 0.8,
            showPulseEffect: true,
            isLowPowerMode: true
        )
        .overlay(
            Text("低电量模式")
                .font(.caption)
                .padding(8)
                .background(Color.yellow.opacity(0.3))
                .cornerRadius(8)
                .offset(y: 100)
        )
    }
    .padding()
    .preferredColorScheme(.light)
}
