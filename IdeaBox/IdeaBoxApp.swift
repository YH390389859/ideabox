import SwiftUI
import FirebaseCore
import UIKit

// MARK: - AppDelegate

/// 应用委托 - 用于控制设备方向
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // 判断设备类型
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone: 只支持竖屏
            return .portrait
        } else {
            // iPad: 支持所有方向
            return .all
        }
    }
}

// MARK: - App

@main
struct IdeaBoxApp: App {
    @StateObject private var appState = AppState()
    
    // 集成 AppDelegate 以控制设备方向
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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

