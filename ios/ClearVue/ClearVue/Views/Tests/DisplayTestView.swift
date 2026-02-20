import SwiftUI

struct DisplayTestView: View {
    let test: TestDefinition
    let onComplete: (TestStatus, String?) -> Void

    @State private var isShowingColors = false
    @State private var colorIndex = 0
    @State private var colorsDone = false

    private let colors: [(Color, String)] = [
        (.white, "White"),
        (.red, "Red"),
        (.green, "Green"),
        (.blue, "Blue"),
        (.black, "Black"),
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Text(test.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    Text(colorsDone
                         ? "Did you notice any dead pixels, discoloration, or backlight bleed?"
                         : test.description)
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)

                    if !colorsDone {
                        Button(action: { isShowingColors = true }) {
                            Text("Start Color Test")
                                .font(.body.weight(.semibold))
                                .foregroundColor(Color(hex: 0x0A0A0A))
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                if colorsDone {
                    TestActionButtons(
                        onPass: { onComplete(.pass, nil) },
                        onFail: { onComplete(.fail, nil) },
                        onSkip: { onComplete(.skipped, nil) }
                    )
                } else {
                    TestActionButtons(
                        onPass: { onComplete(.pass, nil) },
                        onFail: { onComplete(.fail, nil) },
                        onSkip: { onComplete(.skipped, nil) },
                        passDisabled: true
                    )
                }
            }

            // Full-screen color overlay
            if isShowingColors {
                colors[colorIndex].0
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 4) {
                            Text(colors[colorIndex].1)
                                .font(.subheadline.weight(.semibold))
                            Text("\(colorIndex + 1) of \(colors.count) \u{2014} Tap to continue")
                                .font(.caption)
                        }
                        .foregroundColor(colorIndex == 4 ? .white : .black) // invert for black panel
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 48)
                    }
                    .onTapGesture {
                        if colorIndex < colors.count - 1 {
                            colorIndex += 1
                        } else {
                            isShowingColors = false
                            colorsDone = true
                        }
                    }
            }
        }
    }
}
