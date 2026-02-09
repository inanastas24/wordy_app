//1
//  TextScannerView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import SwiftUI
import Vision
import UIKit

struct TextScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: TextScannerView
        
        init(_ parent: TextScannerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                recognizeText(in: image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        func recognizeText(in image: UIImage) {
            guard let cgImage = image.cgImage else { return }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                
                DispatchQueue.main.async {
                    self.parent.scannedText = text
                }
            }
            
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["en", "uk", "de", "fr", "es", "it", "pl"]
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("❌ Помилка розпізнавання: \(error)")
            }
        }
    }
}
