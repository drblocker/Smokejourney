import UIKit
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Ensure background tasks are configured
        DispatchQueue.main.async {
            BackgroundTaskHandler.shared.setupBackgroundTasks()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Clean up if needed
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // App became active
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // App will resign active
    }
} 