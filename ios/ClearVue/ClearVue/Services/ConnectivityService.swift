import Network
import CoreTelephony
import Combine

class ConnectivityService: ObservableObject {
    @Published var wifiStatus: ConnectionStatus = .checking
    @Published var cellularStatus: ConnectionStatus = .checking
    @Published var carrierName: String = ""
    @Published var radioTechnology: String = ""

    private var wifiMonitor: NWPathMonitor?
    private var cellularMonitor: NWPathMonitor?

    enum ConnectionStatus {
        case checking
        case connected
        case disconnected
        case error(String)
    }

    func checkWifi() {
        let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.wifiStatus = path.status == .satisfied ? .connected : .disconnected
            }
        }
        monitor.start(queue: DispatchQueue(label: "wifi-monitor"))
        wifiMonitor = monitor

        // Cancel after 3s to avoid indefinite monitoring
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if case .checking = self?.wifiStatus {
                self?.wifiStatus = .disconnected
            }
        }
    }

    func checkCellular() {
        let monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.cellularStatus = path.status == .satisfied ? .connected : .disconnected
            }
        }
        monitor.start(queue: DispatchQueue(label: "cellular-monitor"))
        cellularMonitor = monitor

        // Get carrier info
        let networkInfo = CTTelephonyNetworkInfo()
        if let providers = networkInfo.serviceSubscriberCellularProviders,
           let carrier = providers.values.first {
            carrierName = carrier.carrierName ?? "Unknown"
        }

        if let radioAccess = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            radioTechnology = mapRadioTech(radioAccess)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if case .checking = self?.cellularStatus {
                self?.cellularStatus = .disconnected
            }
        }
    }

    func stop() {
        wifiMonitor?.cancel()
        cellularMonitor?.cancel()
    }

    private func mapRadioTech(_ tech: String) -> String {
        switch tech {
        case CTRadioAccessTechnologyLTE: return "LTE"
        case CTRadioAccessTechnologyeHRPD: return "eHRPD"
        case CTRadioAccessTechnologyHSDPA: return "HSDPA"
        case CTRadioAccessTechnologyWCDMA: return "WCDMA"
        case CTRadioAccessTechnologyEdge: return "EDGE"
        case CTRadioAccessTechnologyGPRS: return "GPRS"
        case "CTRadioAccessTechnologyNRNSA": return "5G NSA"
        case "CTRadioAccessTechnologyNR": return "5G"
        default: return tech
        }
    }
}
