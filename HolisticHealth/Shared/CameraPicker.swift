import SwiftUI
import UIKit
import AVFoundation

/// Camera authorization helpers.
enum CameraPermission {
    static var status: AVAuthorizationStatus { AVCaptureDevice.authorizationStatus(for: .video) }
    static var isAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    static func request() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

/// Presents the system camera and returns a captured JPEG. Used for meal and
/// acne flare photos. Requires NSCameraUsageDescription (set in project.yml).
struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                parent.onImage(data)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
