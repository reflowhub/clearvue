import SwiftUI

struct ResultsView: View {
    @ObservedObject var runner: TestRunner
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private var report: DiagnosticReport {
        runner.buildReport()
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

                    HStack {
                        if let storage = report.formattedStorage {
                            Label(storage, systemImage: "internaldrive")
                        }
                        Spacer()
                        if let battery = report.batteryLevel {
                            Label("\(battery)%", systemImage: "battery.100percent")
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

                // Actions
                VStack(spacing: 12) {
                    Button(action: generateAndSharePDF) {
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
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
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
