import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use the shared instance
        _ = BackgroundTaskHandler.shared
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Clean up if needed
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Handle scene activation
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Handle scene deactivation
    }
} 