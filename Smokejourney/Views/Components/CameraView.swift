import UIKit
import SwiftUI
import AVFoundation
import os.log

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?
    private let logger = Logger(subsystem: "com.smokejourney", category: "Camera")
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Basic camera setup
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.mediaTypes = ["public.image"]
        
        // Disable all advanced features
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.cameraFlashMode = .off
        picker.showsCameraControls = true
        
        // Disable video recording
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 0
        
        logger.debug("Camera view controller created")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, 
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Add preview provider for testing in SwiftUI previews
#Preview {
    CameraView(image: .constant(nil))
} 