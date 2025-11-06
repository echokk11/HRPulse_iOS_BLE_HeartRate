import SwiftUI

struct ChargingWaveView: View {
    let isActive: Bool
    
    private let waveCount = 4
    
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    guard isActive else { return }
                    context.addFilter(.blur(radius: 6))
                    context.addFilter(.colorMultiply(Color.green.opacity(0.8)))
                    let totalTravel = size.height + 240
                    for index in 0..<waveCount {
                        let phase = Double(index) * 0.35
                        let speed = 0.18 + 0.08 * Double(index)
                        let amplitude = 20 + CGFloat(index) * 6
                        let frequency = 2.0 + Double(index)
                        let progress = fmod(time * speed + phase, 1.0)
                        let baseline = size.height - CGFloat(progress) * totalTravel
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: baseline))
                        let step = max(4, size.width / 160)
                        var x: CGFloat = 0
                        while x <= size.width {
                            let normalized = Double(x / size.width)
                            let noise = sin(normalized * frequency * .pi * 2 + time * speed * 4)
                            let secondary = sin(normalized * 3 * .pi + time * 0.8)
                            let y = baseline - CGFloat(noise + secondary * 0.3) * amplitude
                            path.addLine(to: CGPoint(x: x, y: y))
                            x += step
                        }
                        let gradient = Gradient(colors: [
                            Color.green.opacity(0.0),
                            Color.green.opacity(0.35 - Double(index) * 0.05),
                            Color.green.opacity(0.0)
                        ])
                        context.stroke(
                            path,
                            with: .linearGradient(
                                gradient,
                                startPoint: CGPoint(x: 0, y: baseline - 40),
                                endPoint: CGPoint(x: 0, y: baseline + 50)
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
            }
        }
        .opacity(isActive ? 0.9 : 0.0)
        .animation(.easeInOut(duration: 0.5), value: isActive)
        .blendMode(.plusLighter)
    }
}

#Preview {
    ZStack {
        Color.black
        ChargingWaveView(isActive: true)
    }
    .ignoresSafeArea()
}
