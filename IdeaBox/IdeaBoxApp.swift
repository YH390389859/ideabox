import SwiftUI
import FirebaseCore

@main
struct IdeaBoxApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

