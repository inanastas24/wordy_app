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
    
    @State private var recognizedWords: [RecognizedWord] = []
    @State private var session = AVCaptureSession()
    @State private var isCameraReady = false
    @State private var cameraError: String?
    
    var body: some View {
        ZStack {
            // Чорний фон
            Color.black.ignoresSafeArea()
            
            // Камера
            CameraPreview(session: session)
                .ignoresSafeArea()
                .opacity(isCameraReady ? 1 : 0)
            
            // Розпізнані слова поверх камери
            if isCameraReady {
                WordsOverlay(
                    words: recognizedWords,
                    onWordTap: { word in
                        scannedText = word
                        onTextRecognized?(word)
                        dismiss()
                    }
                )
            }
            
            // Кнопка закриття
            VStack {
                HStack {
                    Spacer()
                    Button {
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
            
            // Підказка знизу
            VStack {
                Spacer()
                Text(localizationManager.string(.tapWordToTranslate))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 40)
            }
            
            // Індикатор завантаження
            if !isCameraReady && cameraError == nil {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Запуск камери...")
                        .foregroundColor(.white)
                }
            }
            
            // Помилка камери
            if let error = cameraError {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Button("Закрити") { dismiss() }
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
        .onDisappear { session.stopRunning() }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                    DispatchQueue.main.async { self.cameraError = "Камера не знайдена" }
                    return
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                let output = AVCaptureVideoDataOutput()
                output.setSampleBufferDelegate(TextRecognitionHandler.shared, queue: DispatchQueue(label: "textRecognition"))
                output.alwaysDiscardsLateVideoFrames = true
                
                self.session.beginConfiguration()
                
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }
                
                if self.session.canAddOutput(output) {
                    self.session.addOutput(output)
                }
                
                self.session.commitConfiguration()
                
                TextRecognitionHandler.shared.onWordsRecognized = { words in
                    DispatchQueue.main.async {
                        self.recognizedWords = words
                    }
                }
                
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.cameraError = "Помилка камери: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Розпізнане слово
struct RecognizedWord: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

// MARK: - Превью камери
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
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// MARK: - Оверлей зі словами (просто кнопки без рамок)
struct WordsOverlay: View {
    let words: [RecognizedWord]
    let onWordTap: (String) -> Void
    
    // Фільтруємо дублікати та слова, що перекриваються
    private var filteredWords: [RecognizedWord] {
        var unique: [RecognizedWord] = []
        var seenTexts: Set<String> = []
        
        for word in words {
            let lowerText = word.text.lowercased()
            
            // Пропускаємо дублікати за текстом
            guard !seenTexts.contains(lowerText) else { continue }
            
            // Пропускаємо слова, що занадто близько до вже доданих (перекриття)
            let isOverlapping = unique.contains { existing in
                let dx = abs(existing.boundingBox.midX - word.boundingBox.midX)
                let dy = abs(existing.boundingBox.midY - word.boundingBox.midY)
                return dx < 0.15 && dy < 0.08 // Мінімальна відстань
            }
            
            guard !isOverlapping else { continue }
            
            seenTexts.insert(lowerText)
            unique.append(word)
        }
        
        return unique.prefix(8).sorted { $0.boundingBox.minY > $1.boundingBox.minY } // Зверху вниз
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(filteredWords) { word in
                    WordButton(
                        word: word,
                        screenSize: geometry.size,
                        onTap: { onWordTap(word.text) }
                    )
                }
            }
        }
    }
}

// MARK: - Кнопка слова (з покращеним стилем)
// MARK: - Кнопка слова (з обмеженням позицій)
struct WordButton: View {
    let word: RecognizedWord
    let screenSize: CGSize
    let onTap: () -> Void
    
    // Обмежуємо позицію в межах екрану з відступами
    private var position: CGPoint {
        let padding: CGFloat = 60 // Відступ від країв
        
        let rawX = word.boundingBox.midX * screenSize.width
        let rawY = (1 - word.boundingBox.midY) * screenSize.height
        
        let clampedX = max(padding, min(screenSize.width - padding, rawX))
        let clampedY = max(100, min(screenSize.height - 150, rawY)) // Відступ зверху/знизу
        
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    // Розмір пропорційний до bounding box
    private var fontSize: CGFloat {
        let height = word.boundingBox.height * screenSize.height
        return max(12, min(18, height * 0.5)) // Менший розмір
    }
    
    // Максимальна ширина бабла
    private var maxWidth: CGFloat {
        screenSize.width * 0.7
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(word.text)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: maxWidth)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#FFD93D"))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                )
        }
        .position(position)
    }
}

// MARK: - Обробник розпізнавання тексту
class TextRecognitionHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = TextRecognitionHandler()
    
    var onWordsRecognized: (([RecognizedWord]) -> Void)?
    private var lastRecognitionTime: Date = Date()
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Обмеження: максимум 2 рази на секунду
        let now = Date()
        guard now.timeIntervalSince(lastRecognitionTime) >= 0.5 else { return }
        lastRecognitionTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Recognition error: \(error)")
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            
            let words = results.compactMap { observation -> RecognizedWord? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.count >= 2 else { return nil } // Мінімум 2 символи
                
                return RecognizedWord(
                    text: text,
                    boundingBox: observation.boundingBox,
                    confidence: candidate.confidence
                )
            }
            
            // Топ-15 за впевненістю
            let topWords = Array(words.sorted { $0.confidence > $1.confidence }.prefix(15))
            
            DispatchQueue.main.async {
                self.onWordsRecognized?(topWords)
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en", "uk", "de", "fr", "es", "it", "pl"]
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ Handler error: \(error)")
        }
    }
}
