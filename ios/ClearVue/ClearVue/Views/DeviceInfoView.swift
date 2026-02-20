import SwiftUI

struct DeviceInfoView: View {
    @ObservedObject var runner: TestRunner
    @State private var imeiText: String = ""
    @State private var validationError: String?
    @FocusState private var isFieldFocused: Bool

    private var isValid: Bool {
        imeiText.isEmpty || validateIMEI(imeiText)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                // Header
                VStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.textMuted)

                    Text("Device Information")
                        .font(.title2.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    Text("Enter your IMEI for the diagnostic report. This is optional but recommended for resale verification.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .padding(.bottom, 32)

                // Auto-detected info
                VStack(spacing: 12) {
                    DeviceInfoRow(label: "Model", value: DiagnosticReport.currentDeviceModel)
                    DeviceInfoRow(label: "iOS Version", value: DiagnosticReport.currentIOSVersion)

                    if let storage = DiagnosticReport.currentStorageTotal {
                        let gb = Double(storage) / 1_000_000_000
                        let roundedGB: Int = gb > 400 ? 512 : gb > 200 ? 256 : gb > 100 ? 128 : gb > 50 ? 64 : 32
                        DeviceInfoRow(label: "Storage", value: "\(roundedGB) GB")
                    }

                    if let battery = DiagnosticReport.currentBatteryLevel {
                        DeviceInfoRow(label: "Battery", value: "\(battery)%")
                    }
                }
                .padding(16)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // IMEI input
                VStack(alignment: .leading, spacing: 8) {
                    Text("IMEI")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary)

                    TextField("", text: $imeiText, prompt: Text("Enter or paste IMEI").foregroundColor(Theme.textDim))
                        .keyboardType(.numberPad)
                        .font(.body.monospacedDigit())
                        .foregroundColor(Theme.textPrimary)
                        .padding(14)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(validationError != nil ? Theme.fail : Color.clear, lineWidth: 1)
                        )
                        .focused($isFieldFocused)
                        .onChange(of: imeiText) { newValue in
                            // Strip non-digits
                            let digits = newValue.filter { $0.isNumber }
                            if digits != newValue {
                                imeiText = digits
                            }
                            // Clear error on edit
                            validationError = nil
                        }

                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(Theme.fail)
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to find your IMEI:")
                            .font(.caption.weight(.medium))
                            .foregroundColor(Theme.textMuted)

                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                            Text("Go to **Settings > General > About**")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                            Text("Long-press the **IMEI** to copy it")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                            Text("Come back here and paste")
                                .font(.caption)
                                .foregroundColor(Theme.textDim)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Buttons
                VStack(spacing: 12) {
                    Button(action: continueWithIMEI) {
                        Text("Continue")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Color(hex: 0x0A0A0A))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }

                    Button(action: skipIMEI) {
                        Text("Skip")
                            .font(.body.weight(.medium))
                            .foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onTapGesture { isFieldFocused = false }
    }

    private func continueWithIMEI() {
        let trimmed = imeiText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            skipIMEI()
            return
        }
        if !validateIMEI(trimmed) {
            validationError = "Invalid IMEI — must be 15 digits"
            return
        }
        runner.imei = trimmed
        runner.start()
    }

    private func skipIMEI() {
        runner.imei = nil
        runner.start()
    }

    private func validateIMEI(_ imei: String) -> Bool {
        // IMEI must be exactly 15 digits
        guard imei.count == 15, imei.allSatisfy({ $0.isNumber }) else { return false }
        // Luhn check
        let digits = imei.compactMap { $0.wholeNumberValue }
        var sum = 0
        for (index, digit) in digits.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }
}

private struct DeviceInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(Theme.textPrimary)
        }
    }
}
