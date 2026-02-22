import UIKit

class PDFGenerator {
    private let pageWidth: CGFloat = 612  // US Letter
    private let pageHeight: CGFloat = 792
    private let margin: CGFloat = 50

    func generate(from report: DiagnosticReport) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin

            // Brand header
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.systemGray,
            ]
            "CLEARVUE".draw(at: CGPoint(x: margin, y: y), withAttributes: brandAttrs)
            y += 20

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black,
            ]
            "iPhone Diagnostic Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 35

            // Report ID + timestamp
            let metaAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.systemGray,
            ]
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            "Report: \(report.id)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
            y += 16
            "Date: \(formatter.string(from: report.completedAt))".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
            y += 16
            "Device: \(report.deviceModel) \u{2014} iOS \(report.iosVersion)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
            y += 16
            if let imei = report.imei {
                "IMEI: \(imei)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 16
            }
            if let storage = report.formattedStorage {
                "Storage: \(storage)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 16
            }
            if let health = report.batteryHealth {
                "Battery Health: \(health)%".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 16
            } else if let charge = report.batteryLevel {
                "Battery Charge: \(charge)%".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 16
            }
            y += 14

            // Score
            let scoreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.black,
            ]
            "Score: \(report.passCount) / \(report.testedCount) passed".draw(at: CGPoint(x: margin, y: y), withAttributes: scoreAttrs)
            y += 14

            if report.notTestableCount > 0 {
                "(\(report.notTestableCount) not testable)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 14
            }
            if report.skippedCount > 0 {
                "(\(report.skippedCount) skipped)".draw(at: CGPoint(x: margin, y: y), withAttributes: metaAttrs)
                y += 14
            }
            y += 16

            // Separator line
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: margin, y: y))
            linePath.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            UIColor.systemGray4.setStroke()
            linePath.lineWidth = 0.5
            linePath.stroke()
            y += 16

            // Column headers
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.systemGray,
            ]
            "TEST".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
            "RESULT".draw(at: CGPoint(x: 320, y: y), withAttributes: headerAttrs)
            "VERIFICATION".draw(at: CGPoint(x: 410, y: y), withAttributes: headerAttrs)
            y += 20

            // Test results
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.black,
            ]

            let tests = TestDefinition.allTests
            for test in tests {
                guard let result = report.results.first(where: { $0.testID == test.id }) else { continue }

                // Check if we need a new page
                if y > pageHeight - margin - 40 {
                    context.beginPage()
                    y = margin
                }

                // Test name
                test.name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)

                // Result badge
                let resultColor: UIColor
                let resultText: String
                switch result.status {
                case .pass: resultColor = UIColor(red: 0x30/255, green: 0xD1/255, blue: 0x58/255, alpha: 1); resultText = "PASS"
                case .fail: resultColor = UIColor(red: 0xFF/255, green: 0x45/255, blue: 0x3A/255, alpha: 1); resultText = "FAIL"
                case .skipped: resultColor = .systemGray; resultText = "SKIPPED"
                case .notTestable: resultColor = .systemGray3; resultText = "N/A"
                }

                let resultAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
                    .foregroundColor: resultColor,
                ]
                resultText.draw(at: CGPoint(x: 320, y: y), withAttributes: resultAttrs)

                // Verification label
                let verifyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.italicSystemFont(ofSize: 10),
                    .foregroundColor: UIColor.systemGray,
                ]
                result.verification.rawValue.draw(at: CGPoint(x: 410, y: y), withAttributes: verifyAttrs)

                y += 24

                // Row separator
                let rowLine = UIBezierPath()
                rowLine.move(to: CGPoint(x: margin, y: y - 4))
                rowLine.addLine(to: CGPoint(x: pageWidth - margin, y: y - 4))
                UIColor.systemGray5.setStroke()
                rowLine.lineWidth = 0.5
                rowLine.stroke()
            }

            // Footer
            y = pageHeight - margin
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor.systemGray3,
            ]
            "Generated by ClearVue \u{2014} clearvue.rhex.app".draw(at: CGPoint(x: margin, y: y), withAttributes: footerAttrs)
        }
    }
}
