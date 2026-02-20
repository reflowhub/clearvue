import CoreNFC
import Combine

enum NFCState {
    case idle
    case scanning
    case found(String)
    case failed(String)
    case unsupported
}

class NFCService: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var state: NFCState = .idle

    private var session: NFCNDEFReaderSession?

    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    func startScan() {
        guard isAvailable else {
            state = .unsupported
            return
        }

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near an NFC tag"
        session?.begin()
        state = .scanning
    }

    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session is active
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            let recordCount = messages.reduce(0) { $0 + $1.records.count }
            self.state = .found("NFC tag detected (\(recordCount) record\(recordCount == 1 ? "" : "s"))")
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            // Code 200 = user cancelled, 201 = session timeout
            if nsError.domain == "NFCError" && nsError.code == 200 {
                // User cancelled - go back to idle
                if case .scanning = self.state {
                    self.state = .idle
                }
            } else if nsError.domain == "NFCError" && nsError.code == 201 {
                self.state = .failed("NFC scan timed out")
            } else {
                self.state = .failed(error.localizedDescription)
            }
        }
    }
}
