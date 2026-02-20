import SwiftUI

@main
struct ClearVueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    @StateObject private var testRunner = TestRunner()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch testRunner.phase {
            case .intro:
                IntroView(onStart: { testRunner.showDeviceInfo() })
            case .deviceInfo:
                DeviceInfoView(runner: testRunner)
            case .testing:
                TestContainerView(runner: testRunner)
            case .results:
                ResultsView(runner: testRunner)
            }
        }
    }
}
