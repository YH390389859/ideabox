import SwiftUI
import FirebaseCore

@main
struct IdeaBoxApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    Task { @MainActor in
                        appState.checkAuthStatus()
                    }
                }
        }
    }
}

