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
    @State private var selectedWord: String?
    @State private var session = AVCaptureSession()
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var body: some View {
        ZStack {
            // Камера
            CameraPreview(session: session)
                .ignoresSafeArea()
            
            // Розпізнані слова поверх камери
            OverlayWordsView(
                words: recognizedWords,
                selectedWord: $selectedWord,
                onWordTap: { word in
                    scannedText = word
                    onTextRecognized?(word)
                    dismiss()
                }
            )
            
            // UI елементи
            VStack {
                // Закрити
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                
                Spacer()
                
                // Підказка
                Text(localizationManager.string(.tapWordToTranslate))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            setupCamera()
            startTextRecognition()
        }
        .onDisappear {
            session.stopRunning()
        }
    }
    
    // MARK: - Налаштування камери
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(TextRecognitionDelegate.shared, queue: DispatchQueue(label: "textRecognition"))
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    // MARK: - Почати розпізнавання
    private func startTextRecognition() {
        TextRecognitionDelegate.shared.onWordsRecognized = { words in
            DispatchQueue.main.async {
                self.recognizedWords = words
            }
        }
    }
}

// MARK: - Модель розпізнаного слова
struct RecognizedWord: Identifiable {
    let id = UUID()
    let text: String
    let boundingBox: CGRect  // Нормалізовані координати (0-1)
    let confidence: Float
}

// MARK: - Превью камери
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Оверлей зі словами
struct OverlayWordsView: View {
    let words: [RecognizedWord]
    @Binding var selectedWord: String?
    let onWordTap: (String) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(words) { word in
                    WordButton(
                        word: word,
                        isSelected: selectedWord == word.text,
                        screenSize: geometry.size
                    ) {
                        onWordTap(word.text)
                    }
                }
            }
        }
    }
}

// MARK: - Кнопка слова
struct WordButton: View {
    let word: RecognizedWord
    let isSelected: Bool
    let screenSize: CGSize
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(word.text)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(hex: "#4ECDC4") : Color(hex: "#FFD93D"))
                        .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        .position(
            x: word.boundingBox.midX * screenSize.width,
            y: (1 - word.boundingBox.midY) * screenSize.height  // Інвертуємо Y
        )
    }
}

// MARK: - Делегат розпізнавання тексту
class TextRecognitionDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static let shared = TextRecognitionDelegate()
    
    var onWordsRecognized: (([RecognizedWord]) -> Void)?
    private let request = VNRecognizeTextRequest()
    private var lastRecognitionTime: Date = Date()
    
    private override init() {
        super.init()
        request.recognitionLevel = .fast
        request.recognitionLanguages = ["en", "uk", "de", "fr", "es", "it", "pl"]
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.01  // Мінімальний розмір тексту
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Обмежуємо частоту розпізнавання (кожні 0.3 секунди)
        let now = Date()
        if now.timeIntervalSince(lastRecognitionTime) < 0.3 { return }
        lastRecognitionTime = now
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            
            let words = results.compactMap { observation -> RecognizedWord? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                
                // Розбиваємо на окремі слова
                let text = candidate.string
                let confidence = candidate.confidence
                
                // Фільтруємо короткі слова
                guard text.count >= 2 else { return nil }
                
                return RecognizedWord(
                    text: text,
                    boundingBox: observation.boundingBox,
                    confidence: confidence
                )
            }
            
            // Сортуємо за впевненістю і беремо топ-10
            let topWords = words.sorted { $0.confidence > $1.confidence }.prefix(10)
            
            DispatchQueue.main.async {
                self.onWordsRecognized?(Array(topWords))
            }
            
        } catch {
            print("❌ Recognition error: \(error)")
        }
    }
}
