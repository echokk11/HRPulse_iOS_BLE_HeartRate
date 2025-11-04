import SwiftUI

/// 首次启动引导视图
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    @State private var opacity: Double = 0
    
    private let steps = [
        OnboardingStep(
            icon: "applewatch",
            title: "打开手表的心率广播功能",
            description: "在佳明手表上启用心率广播"
        ),
        OnboardingStep(
            icon: "antenna.radiowaves.left.and.right",
            title: "应用会自动连接最近的设备",
            description: "无需手动配对，自动发现并连接"
        ),
        OnboardingStep(
            icon: "hand.tap",
            title: "轻触屏幕可访问设置",
            description: "随时调整后台运行等选项"
        )
    ]
    
    var body: some View {
        ZStack {
            // 半透明遮罩
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 当前步骤内容
                VStack(spacing: 20) {
                    Image(systemName: steps[currentStep].icon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .accessibilityHidden(true)
                    
                    Text(steps[currentStep].title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text(steps[currentStep].description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("引导步骤 \(currentStep + 1) 共 \(steps.count) 步")
                .accessibilityValue("\(steps[currentStep].title)。\(steps[currentStep].description)")
                .transition(.opacity.combined(with: .scale))
                
                // 步骤指示器
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 20)
                .accessibilityHidden(true)
                
                Spacer()
                
                // 跳过提示
                Text("轻触屏幕跳过")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 40)
                    .accessibilityHidden(true)
            }
            .opacity(opacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissOnboarding()
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("首次使用引导")
        .accessibilityHint("轻触屏幕跳过引导")
        .onAppear {
            // 淡入动画
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            
            // 自动切换步骤
            startAutoAdvance()
        }
    }
    
    // MARK: - Private Methods
    
    /// 自动推进步骤
    private func startAutoAdvance() {
        // 每步显示 1 秒，总共 3 秒
        for step in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step + 1)) {
                if currentStep < steps.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep += 1
                    }
                } else {
                    // 最后一步显示完后自动关闭
                    dismissOnboarding()
                }
            }
        }
    }
    
    /// 关闭引导
    private func dismissOnboarding() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            
            // 标记已显示引导
            var settings = AppSettings.load()
            settings.hasSeenOnboarding = true
            settings.save()
        }
    }
}

// MARK: - Supporting Types

/// 引导步骤数据模型
private struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
