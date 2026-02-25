import SwiftUI

struct ResultsView: View {
    @ObservedObject var runner: TestRunner
    @State private var pdfURL: URL?
    @State private var showShareSheet = false
    @State private var imeiText: String = ""
    @State private var validationError: String?
    @State private var isValidating = false
    @FocusState private var isFieldFocused: Bool

    private var report: DiagnosticReport {
        runner.buildReport()
    }

    private var hasValidIMEI: Bool {
        runner.imei != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("CLEARVUE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(2)
                        .foregroundColor(Theme.textDim)

                    Text("Diagnostic Complete")
                        .font(.title.weight(.bold))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(report.passCount) / \(report.testedCount) tests passed")
                        .font(.body)
                        .foregroundColor(Theme.textSecondary)

                    if report.notTestableCount > 0 {
                        Text("(\(report.notTestableCount) not testable)")
                            .font(.caption)
                            .foregroundColor(Theme.textDim)
                    }

                    Text(report.completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(Theme.textDim)
                        .monospacedDigit()
                }
                .padding(.top, 32)
                .padding(.bottom, 24)

                // Device info
                VStack(spacing: 6) {
                    HStack {
                        Label(report.deviceModel, systemImage: "iphone")
                        Spacer()
                        Text("iOS \(report.iosVersion)")
                    }

                    if let imei = report.imei {
                        HStack {
                            Label(imei, systemImage: "number")
                                .monospacedDigit()
                            Spacer()
                            Text("IMEI")
                        }
                    }

                    if let tacLabel = report.tacResult?.deviceLabel {
                        HStack {
                            Label(tacLabel, systemImage: "cpu")
                            Spacer()
                            Text("TAC")
                        }
                    }

                    HStack {
                        if let storage = report.formattedStorage {
                            Label(storage, systemImage: "internaldrive")
                        }
                        Spacer()
                        if let health = report.batteryHealth {
                            Label("\(health)%", systemImage: "battery.100percent")
                        } else if let charge = report.batteryLevel {
                            Label("\(charge)%", systemImage: "battery.100percent")
                        }
                    }
                }
                .font(.caption)
                .foregroundColor(Theme.textMuted)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Results list
                VStack(spacing: 0) {
                    ForEach(runner.tests) { test in
                        if let result = runner.results[test.id] {
                            ResultRow(test: test, result: result)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // IMEI input (required before sharing PDF)
                if !hasValidIMEI {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("IMEI Required")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.textPrimary)

                        Text("Enter your IMEI to include it in the PDF report.")
                            .font(.caption)
                            .foregroundColor(Theme.textSecondary)

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
                                let digits = newValue.filter { $0.isNumber }
                                if digits != newValue {
                                    imeiText = digits
                                }
                                validationError = nil
                            }

                        if let error = validationError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(Theme.fail)
                        }

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

                        Button(action: submitIMEI) {
                            HStack(spacing: 8) {
                                if isValidating {
                                    ProgressView()
                                        .tint(Color(hex: 0x0A0A0A))
                                }
                                Text(isValidating ? "Validating..." : "Save IMEI")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color(hex: 0x0A0A0A))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                        }
                        .disabled(isValidating)
                        .padding(.top, 4)
                    }
                    .padding(16)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: sharePDFTapped) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Report PDF")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(Color(hex: 0x0A0A0A))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }

                    Button(action: { runner.restart() }) {
                        Text("Run Again")
                            .font(.body.weight(.semibold))
                            .foregroundColor(Theme.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonRadius))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                Text("\u{00A9} 2026 ClearVue \u{2014} clearvue.rhex.app")
                    .font(.caption2)
                    .foregroundColor(Theme.textDim)
                    .padding(.bottom, 24)
            }
        }
        .onTapGesture { isFieldFocused = false }
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func submitIMEI() {
        let trimmed = imeiText.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            validationError = "IMEI is required"
            return
        }
        guard trimmed.count == 15, trimmed.allSatisfy({ $0.isNumber }) else {
            validationError = "Invalid IMEI \u{2014} must be 15 digits"
            return
        }
        isFieldFocused = false
        isValidating = true
        validationError = nil

        Task {
            do {
                let result = try await IMEIService.lookup(trimmed)
                isValidating = false
                if result.valid {
                    runner.tacResult = result
                    runner.imei = trimmed
                } else {
                    validationError = result.error ?? "IMEI not recognized"
                }
            } catch {
                isValidating = false
                // Network error — still accept the IMEI locally
                runner.imei = trimmed
            }
        }
    }

    private func sharePDFTapped() {
        if !hasValidIMEI {
            validationError = "IMEI is required before sharing"
            isFieldFocused = true
            return
        }
        generateAndSharePDF()
    }

    private func generateAndSharePDF() {
        let generator = PDFGenerator()
        let data = generator.generate(from: report)
        let fileName = "ClearVue-Report-\(report.id).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        pdfURL = url
        showShareSheet = true
    }
}

private struct ResultRow: View {
    let test: TestDefinition
    let result: TestResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(test.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                Text(result.verification.rawValue)
                    .font(.caption2)
                    .foregroundColor(Theme.textMuted)
                    .italic()
            }

            Spacer()

            StatusBadgeView(status: result.status)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Theme.separator.frame(height: 1)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
