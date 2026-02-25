import SwiftUI

struct MotionTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @StateObject private var service = MotionService()
    @State private var autoCompleted = false
    @State private var verified = false

    // Dot position offset based on acceleration
    private var dotOffset: CGSize {
        let clampedX = max(-1, min(1, service.roll))
        let clampedY = max(-1, min(1, service.pitch))
        let maxOffset: CGFloat = 40
        return CGSize(width: clampedX * maxOffset, height: clampedY * maxOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(test.name)
                    .font(.title2.weight(.bold))
                    .foregroundColor(Theme.textPrimary)

                Text(test.description)
                    .font(.body)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                if !service.isAvailable {
                    Text("Motion sensors not available on this device")
                        .font(.subheadline)
                        .foregroundColor(Theme.fail)
                } else {
                    // Motion visualization circle
                    Circle()
                        .fill(Theme.surface)
                        .frame(width: 128, height: 128)
                        .overlay {
                            Circle()
                                .fill(Theme.pass)
                                .frame(width: 24, height: 24)
                                .offset(dotOffset)
                                .animation(.easeOut(duration: 0.1), value: dotOffset.width)
                                .animation(.easeOut(duration: 0.1), value: dotOffset.height)
                        }

                    if verified {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Verified")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.pass)
                        .transition(.opacity)
                    } else if service.isReceivingData {
                        Text("Sensor data detected")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.pass)
                    }

                    // Raw data
                    VStack(spacing: 2) {
                        Text("Pitch: \(String(format: "%+.2f", service.pitch))")
                        Text("Roll:  \(String(format: "%+.2f", service.roll))")
                        Text("Accel: \(String(format: "%.2f, %.2f, %.2f", service.accelX, service.accelY, service.accelZ))")
                    }
                    .font(.caption.monospaced())
                    .foregroundColor(Theme.textMuted)
                    .monospacedDigit()
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if !service.isAvailable {
                TestActionButtons(
                    onPass: { onComplete(.pass, nil) },
                    onFail: { onComplete(.fail, nil) },
                    onNotSupported: { onComplete(.notTestable, "Motion sensors unavailable") }
                )
            } else {
                TestActionButtons(
                    onPass: { onComplete(.pass, "Motion sensors functional, \(service.sampleCount) samples") },
                    onFail: { onComplete(.fail, nil) },
                    onSkip: { onComplete(.skipped, nil) },
                    passDisabled: !service.isReceivingData
                )
            }
        }
        .onAppear {
            service.start()
        }
        .onDisappear {
            service.stop()
        }
        .onChange(of: service.isReceivingData) { receiving in
            if receiving && !autoCompleted {
                autoCompleted = true
                withAnimation { verified = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete(.pass, "Motion sensors functional, \(service.sampleCount) samples")
                }
            }
        }
    }
}
