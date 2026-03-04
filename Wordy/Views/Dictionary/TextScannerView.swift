//
//  TextScannerView.swift
//  Wordy
//

import SwiftUI
import Vision
import AVFoundation

struct TextScannerView: View {
    @Binding var scannedText: String
    @Binding var isRecognizing: Bool
    var onTextRecognized: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    
    @State private var recognizedWords: [RecognizedWord] = []
    @State private var session = AVCaptureSession()
    @State private var isCameraReady = false
    @State private var cameraError: String?
    
    @State private var isFrozen = false
    @State private var capturedImage: UIImage?
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var imageSize: CGSize = .zero
    
    @State private var isConfiguring = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !isFrozen {
                CameraPreview(session: session)
                    .ignoresSafeArea()
                    .opacity(isCameraReady ? 1 : 0)
            }
            
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .background(GeometryReader { geo in
                        Color.clear.onAppear {
                            imageSize = geo.size
                        }
                    })
            }
            
            GeometryReader { geo in
                WordsOverlay(
                    words: recognizedWords,
                    containerSize: geo.size,
                    onWordTap: { word in
                        scannedText = word
                        onTextRecognized?(word)
                        dismiss()
                    }
                )
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        stopCameraSafely()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                    .padding(20)
                }
                Spacer()
            }
            
            if !isFrozen && isCameraReady {
                VStack {
                    Spacer()
                    Button(action: capturePhoto) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 72, height: 72)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            
            if isFrozen {
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        Button(action: retakePhoto) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 24))
                                Text(localizationManager.string(.retakeText))
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        }
                        
                        Button {
                            stopCameraSafely()
                            dismiss()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24))
                                Text(localizationManager.string(.doneText))
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color(hex: "#4ECDC4"))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            
            VStack {
                Spacer()
                Text(isFrozen ? localizationManager.string(.tapWordToTranslate) : localizationManager.string(.tapToCapture))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, isFrozen ? 140 : 40)
            }
            
            if !isCameraReady && cameraError == nil && !isFrozen {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text(localizationManager.string(.startingCameraText))
                        .foregroundColor(.white)
                }
            }
            
            if let error = cameraError {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Button(localizationManager.string(.closeText)) {
                        stopCameraSafely()
                        dismiss()
                    }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#4ECDC4"))
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear { setupCamera() }
        .onDisappear { stopCameraSafely() } // ОНОВЛЕНО
    }
    
    // НОВИЙ МЕТОД: Безпечна зупинка камери
    private func stopCameraSafely() {
        guard !isConfiguring else {
            print("⚠️ Cannot stop camera - currently configuring")
            return
        }
        
        if session.isRunning {
            print("🛑 Stopping camera session")
            session.stopRunning()
        }
    }
    
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        let delegate = PhotoCaptureDelegate { image in
            print("📸 Фото отримано, розмір: \(image.size)")
            DispatchQueue.main.async {
                self.capturedImage = image
                self.isFrozen = true
                self.stopCameraSafely() // ОНОВЛЕНО
                self.imageSize = CGSize(width: image.size.width, height: image.size.height)
                self.recognizeTextInImage(image)
            }
        }
        
        objc_setAssociatedObject(photoOutput, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("❌ Recognition error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            
            let words = results.compactMap { observation -> RecognizedWord? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.count >= 3 else { return nil }
                
                return RecognizedWord(
                    text: text,
                    boundingBox: observation.boundingBox,
                    confidence: candidate.confidence
                )
            }.sorted { $0.confidence > $1.confidence }
            
            DispatchQueue.main.async {
                self.recognizedWords = Array(words.prefix(12))
            }
        }
        
        request.recognitionLevel = .accurate
        let sourceLang = appState.languagePair.source.rawValue
        let targetLang = appState.languagePair.target.rawValue
        request.recognitionLanguages = [sourceLang, targetLang]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch { print("❌ Handler error: \(error)") }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
        recognizedWords = []
        isFrozen = false
        imageSize = .zero
        // ОНОВЛЕНО: Спочатку зупиняємо, потім налаштовуємо
        stopCameraSafely()
        // Невелика затримка перед повторним налаштуванням
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupCamera()
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            // ОНОВЛЕНО: Встановлюємо прапорець конфігурації
            self.isConfiguring = true
            
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            do {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    DispatchQueue.main.async {
                        self.isConfiguring = false
                        self.cameraError = self.localizationManager.string(.cameraNotFoundText)
                    }
                    return
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) { self.session.addInput(input) }
                if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
                
                self.session.commitConfiguration()
                self.isConfiguring = false // ОНОВЛЕНО
                
                self.session.startRunning()
                
                DispatchQueue.main.async { self.isCameraReady = true }
            } catch {
                DispatchQueue.main.async {
                    self.isConfiguring = false // ОНОВЛЕНО
                    self.cameraError = error.localizedDescription
                }
            }
        }
    }
}

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    let completion: (UIImage) -> Void
    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
        super.init()
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error { return }
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        completion(image)
    }
}

struct RecognizedWord: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.frame = uiView.bounds
    }
}

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - Оверлей з вертикальними колонками
struct WordsOverlay: View {
    let words: [RecognizedWord]
    let containerSize: CGSize
    let onWordTap: (String) -> Void
    
    private let columns = 2
    
    var body: some View {
        let layout = calculateLayout()
        
        HStack(alignment: .top, spacing: 20) {
            ForEach(0..<columns, id: \.self) { colIndex in
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(layout[colIndex]) { word in
                        WordButton(word: word, onTap: { onWordTap(word.text) })
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 100)
    }
    
    private func calculateLayout() -> [[RecognizedWord]] {
        var result: [[RecognizedWord]] = Array(repeating: [], count: columns)
        
        for (index, word) in words.enumerated() {
            let col = index % columns
            result[col].append(word)
        }
        
        return result
    }
}

struct WordButton: View {
    let word: RecognizedWord
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(word.text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#FFD93D"))
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                )
        }
    }
}
