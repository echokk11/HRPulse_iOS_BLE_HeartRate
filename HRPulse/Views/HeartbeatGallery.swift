import SwiftUI

/// 左右滑动切换的心跳动画集合，使用 beatPhase 来同步节拍
struct HeartbeatGallery: View {
    let bpm: Int
    let rrMs: Double?
    @Binding var beatPhase: Bool
    let hasLiveData: Bool
    @State private var selection = 0
    
    private var beatDuration: Double {
        if let rr = rrMs {
            return max(0.2, min(1.5, rr / 1000.0))
        }
        return bpm > 0 ? max(0.3, min(1.5, 60.0 / Double(bpm))) : 1.0
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ScaleBeatView(beatPhase: $beatPhase, duration: beatDuration, color: primaryColor)
                .tag(0)
            RippleBeatView(beatPhase: $beatPhase, duration: beatDuration, color: primaryColor)
                .tag(1)
            NeonBeatView(beatPhase: $beatPhase, duration: beatDuration, color: primaryColor, hasLiveData: hasLiveData)
                .tag(2)
            EKGBeatView(beatPhase: $beatPhase, duration: beatDuration, color: primaryColor)
                .tag(3)
            BarsBeatView(beatPhase: $beatPhase, duration: beatDuration, color: primaryColor)
                .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.vertical, 32)
        .padding(.horizontal, 12)
    }
    
    private var primaryColor: Color {
        hasLiveData ? ColorTheme.accent : ColorTheme.heartDisconnected
    }
}

struct ScaleBeatView: View {
    @Binding var beatPhase: Bool
    let duration: Double
    let color: Color
    
    var body: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 210, height: 210)
            .foregroundStyle(color)
            .scaleEffect(beatPhase ? 1.12 : 0.92)
            .animation(.easeInOut(duration: duration), value: beatPhase)
            .shadow(color: color.opacity(0.5), radius: beatPhase ? 18 : 6)
}
}

struct RippleBeatView: View {
    @Binding var beatPhase: Bool
    let duration: Double
    let color: Color
    
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.35 - Double(index) * 0.1), lineWidth: 6)
                    .frame(
                        width: beatPhase ? CGFloat(300 + index * 28) : CGFloat(110 + index * 28),
                        height: beatPhase ? CGFloat(300 + index * 28) : CGFloat(110 + index * 28)
                    )
                    .animation(
                        .easeOut(duration: duration)
                            .delay(Double(index) * duration * 0.15),
                        value: beatPhase
                    )
            }
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundStyle(color)
                .scaleEffect(beatPhase ? 1.08 : 0.95)
                .animation(.easeInOut(duration: duration * 0.9), value: beatPhase)
        }
        .frame(height: 320)
    }
}

struct NeonBeatView: View {
    @Binding var beatPhase: Bool
    let duration: Double
    let color: Color
    let hasLiveData: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(color.opacity(0.12))
                .frame(width: 300, height: 300)
                .shadow(
                    color: color.opacity(beatPhase ? 0.75 : 0.3),
                    radius: beatPhase ? 40 : 12,
                    x: 0,
                    y: 0
                )
                .animation(.easeInOut(duration: duration), value: beatPhase)
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .foregroundStyle(color)
                .overlay(
                    Image(systemName: "heart")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 170, height: 170)
                        .foregroundStyle(Color.white.opacity(hasLiveData ? 0.65 : 0.25))
                        .blur(radius: beatPhase ? 2 : 4)
                        .opacity(beatPhase ? 0.9 : 0.6)
                        .animation(.easeInOut(duration: duration), value: beatPhase)
                )
                .shadow(color: color.opacity(beatPhase ? 0.8 : 0.3), radius: beatPhase ? 30 : 8)
        }
    }
}

struct EKGBeatView: View {
    @Binding var beatPhase: Bool
    let duration: Double
    @State private var phase: CGFloat = 0
    let color: Color
    
    var body: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 190, height: 190)
                .foregroundStyle(color.opacity(0.2))
            EKGWave(phase: phase)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 300, height: 140)
                .scaleEffect(beatPhase ? 1.03 : 0.97)
                .animation(.easeInOut(duration: duration * 0.6), value: beatPhase)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                phase = -1.0
            }
        }
    }
}

struct EKGWave: Shape {
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.midY
        let width = rect.width
        
        func x(_ t: CGFloat) -> CGFloat { rect.minX + t * width }
        
        path.move(to: CGPoint(x: x(0 + phase), y: baseline))
        path.addLine(to: CGPoint(x: x(0.15 + phase), y: baseline - 6))
        path.addLine(to: CGPoint(x: x(0.25 + phase), y: baseline))
        path.addLine(to: CGPoint(x: x(0.35 + phase), y: baseline + 12))
        path.addLine(to: CGPoint(x: x(0.42 + phase), y: baseline - 28))
        path.addLine(to: CGPoint(x: x(0.50 + phase), y: baseline + 18))
        path.addLine(to: CGPoint(x: x(0.70 + phase), y: baseline + 4))
        path.addLine(to: CGPoint(x: x(0.95 + phase), y: baseline))
        return path
    }
}

struct BarsBeatView: View {
    @Binding var beatPhase: Bool
    let duration: Double
    private let barCount = 9
    let color: Color
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<barCount, id: \.self) { _ in
                Capsule()
                    .fill(color)
                    .frame(
                        width: 14,
                        height: beatPhase ? CGFloat.random(in: 60...180) : CGFloat.random(in: 28...100)
                    )
                    .animation(
                        .spring(response: duration * 0.7, dampingFraction: 0.55),
                        value: beatPhase
                    )
                    .opacity(0.85)
            }
        }
        .frame(height: 220)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview("Heartbeat Gallery") {
    HeartbeatGallery(bpm: 78, rrMs: 780, beatPhase: .constant(true), hasLiveData: true)
        .background(Color.black.opacity(0.05))
}
