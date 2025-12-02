import SwiftUI

@main
struct PhoneApp: App {
    // Pas besoin de @StateObject, on utilise directement le singleton
    @State var modeVM = ModeViewModel()
    var body: some Scene {
        WindowGroup {
            HomeKitView()
                .environmentObject(HomeKitManager.shared)
                .environmentObject(modeVM)
            
        }
    }
}
