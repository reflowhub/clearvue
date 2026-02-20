import CoreBluetooth
import Combine

class BluetoothService: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var state: CBManagerState = .unknown
    @Published var stateDescription: String = "Initializing..."

    private var centralManager: CBCentralManager?

    func check() {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [
            CBCentralManagerOptionShowPowerAlertKey: false,
        ])
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        switch central.state {
        case .poweredOn:
            stateDescription = "Bluetooth is On"
        case .poweredOff:
            stateDescription = "Bluetooth is Off"
        case .unauthorized:
            stateDescription = "Bluetooth permission denied"
        case .unsupported:
            stateDescription = "Bluetooth not supported"
        case .resetting:
            stateDescription = "Bluetooth is resetting..."
        default:
            stateDescription = "Unknown state"
        }
    }

    func stop() {
        centralManager = nil
    }
}
