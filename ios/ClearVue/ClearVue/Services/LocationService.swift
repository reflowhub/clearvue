import CoreLocation
import Combine

enum LocationState {
    case idle
    case requesting
    case acquired(CLLocation)
    case failed(String)
}

class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var state: LocationState = .idle
    @Published var countdown: Int = 10

    private let manager = CLLocationManager()
    private var timer: Timer?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        state = .requesting
        countdown = 10

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            self.countdown -= 1
            if self.countdown <= 0 {
                t.invalidate()
                if case .requesting = self.state {
                    self.state = .failed("Location request timed out")
                }
            }
        }

        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            timer?.invalidate()
            state = .failed("Location permission denied")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        timer?.invalidate()
        if let location = locations.first {
            state = .acquired(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        timer?.invalidate()
        state = .failed(error.localizedDescription)
    }

    func stop() {
        timer?.invalidate()
        manager.stopUpdatingLocation()
    }
}
