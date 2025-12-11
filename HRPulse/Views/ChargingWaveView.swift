import SwiftUI

struct ChargingWaveView: View {
    let isActive: Bool
    
    private let waveCount = 6
    
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    guard isActive else { return }
                    
                    context.addFilter(.blur(radius: 10))
                    
                    // Adjust color filter based on scheme for better visibility
                    let filterColor = colorScheme == .dark ? 
                        Color(red: 0.4, green: 1.0, blue: 0.6) : // Brighter neon green for dark mode
                        Color.green.opacity(0.8)
                    
                    context.addFilter(.colorMultiply(filterColor))
                    
                    let totalTravel = size.height + 240
                    for index in 0..<waveCount {
                        let dIndex = Double(index)
                        // Phase with fixed random offset per wave (not time varying)
                        let phase = dIndex * 0.35 + sin(dIndex * 100.0) * 0.2 
                        // Slower and simpler speed, without time-dependent randomness
                        let speed = 0.10 + 0.06 * dIndex 
                        let amplitude = 20 + CGFloat(index) * 6
                        let frequency = 2.0 + dIndex
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
                            Color.green.opacity(0.75 - dIndex * 0.1),
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
        .blendMode(colorScheme == .dark ? .screen : .plusLighter)
    }
}

#Preview {
    ZStack {
        Color.black
        ChargingWaveView(isActive: true)
    }
    .ignoresSafeArea()
}
