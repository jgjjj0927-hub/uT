import SwiftUI
import CoreMotion

class MagnetometerManager: ObservableObject {
    private let motionManager = CMMotionManager()

    @Published var magnitude: Double = 0.0
    @Published var x: Double = 0.0
    @Published var y: Double = 0.0
    @Published var z: Double = 0.0
    @Published var isAvailable: Bool = true

    init() {
        guard motionManager.isMagnetometerAvailable else {
            isAvailable = false
            return
        }
        motionManager.magnetometerUpdateInterval = 0.05
        startUpdates()
    }

    func startUpdates() {
        guard motionManager.isMagnetometerAvailable else { return }
        motionManager.startMagnetometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            let field = data.magneticField
            self?.x = field.x
            self?.y = field.y
            self?.z = field.z
            self?.magnitude = sqrt(field.x * field.x + field.y * field.y + field.z * field.z)
        }
    }

    func stopUpdates() {
        motionManager.stopMagnetometerUpdates()
    }

    deinit {
        motionManager.stopMagnetometerUpdates()
    }
}

struct ContentView: View {
    @StateObject private var mag = MagnetometerManager()

    let lowThreshold: Double = 30.0
    let highThreshold: Double = 120.0

    var arrowPosition: CGFloat {
        let clamped = min(max(mag.magnitude, lowThreshold), highThreshold)
        let normalized = (clamped - lowThreshold) / (highThreshold - lowThreshold)
        return CGFloat(normalized)
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.15, blue: 0.35)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text(String(format: "%.1f μT", mag.magnitude))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.top, 60)

                if !mag.isAvailable {
                    Text("Магнитометр недоступен")
                        .font(.footnote)
                        .foregroundColor(.red)
                }

                HStack(spacing: 20) {
                    Text(String(format: "X: %.1f", mag.x))
                    Text(String(format: "Y: %.1f", mag.y))
                    Text(String(format: "Z: %.1f", mag.z))
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

                Spacer()

                GeometryReader { geo in
                    let trackInset: CGFloat = 40
                    let trackWidth = max(geo.size.width - trackInset * 2, 1)
                    let rawX = trackInset + trackWidth * arrowPosition
                    let arrowX = min(max(rawX, trackInset), geo.size.width - trackInset)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 8)
                            .padding(.horizontal, trackInset)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .green, .yellow, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(arrowX - trackInset, 0), height: 8)
                            .padding(.leading, trackInset)

                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(90))
                            .position(x: arrowX, y: 20)
                    }
                }
                .frame(height: 60)
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            if mag.isAvailable {
                mag.startUpdates()
            }
        }
        .onDisappear {
            mag.stopUpdates()
        }
    }
}
