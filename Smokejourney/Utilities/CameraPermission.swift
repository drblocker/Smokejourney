import UIKit
import AVFoundation
import os.log

class CameraPermission {
    private static let logger = Logger(subsystem: "com.smokejourney", category: "CameraPermission")
    
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        // First check if camera hardware is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            logger.error("Camera hardware not available")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        // Then check/request permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("Camera permission already granted")
            completion(true)
            
        case .notDetermined:
            logger.debug("Requesting camera permission")
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        logger.debug("Camera permission granted")
                    } else {
                        logger.error("Camera permission denied")
                    }
                    completion(granted)
                }
            }
            
        case .denied, .restricted:
            logger.error("Camera permission denied or restricted")
            DispatchQueue.main.async {
                completion(false)
            }
            
        @unknown default:
            logger.error("Unknown camera permission status")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    static func checkCameraPermission() -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            logger.error("Camera hardware not available")
            return false
        }
        
        let authorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        logger.debug("Camera permission status: \(authorized ? "authorized" : "not authorized")")
        return authorized
    }
} 