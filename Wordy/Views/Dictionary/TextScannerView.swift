//
//  TextScannerView.swift
//  Wordy
//

import SwiftUI
import Vision
import AVFoundation
import Speech
import UIKit

struct TextScannerView: View {
    @Binding var scannedText: String
    @Binding var isRecognizing: Bool
    var onTextRecognized: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var recognizedWords: [RecognizedWord] = []
    @State private var session = AVCaptureSession()
    @State private var isCameraReady = false
    @State private var cameraError: String?
    
    @State private var isFrozen = false
    @State private var capturedImage: UIImage?
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var imageSize: CGSize = .zero
    @State private var cameraDevice: AVCaptureDevice?
    @State private var zoomFactor: CGFloat = 1.0
    @State private var pinchBaseZoomFactor: CGFloat = 1.0
    @State private var maxZoomFactor: CGFloat = 4.0
    @State private var focusIndicatorPosition: CGPoint?
    @State private var isRecognizingText = false
    
    @State private var isConfiguring = false
    
    // Permission states
    @State private var showPermissionAlert = false
    @State private var permissionType: ScannerPermissionType = .camera
    @State private var showVoiceError = false
    @State private var voiceErrorMessage = ""
    
    var onShowPaywall: (() -> Void)?
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !isFrozen {
                CameraPreview(
                    session: session,
                    onTapFocus: { viewPoint, devicePoint in
                        handleTapToFocus(at: viewPoint, devicePoint: devicePoint)
                    },
                    onPinchZoom: { scale, state in
                        handlePinchZoom(scale: scale, state: state)
                    }
                )
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

            if isRecognizingText {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)

                    Text(localizationManager.string(.startingCameraText))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            
            GeometryReader { geo in
                ZStack {
                    ScannerGuideOverlay(isFrozen: isFrozen)

                    WordsOverlay(
                        words: recognizedWords,
                        containerSize: geo.size,
                        onWordTap: { word in
                            scannedText = word
                            onTextRecognized?(word)
                            dismiss()
                        }
                    )

                    if let focusIndicatorPosition {
                        FocusIndicator()
                            .position(focusIndicatorPosition)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
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
                    HStack {
                        zoomControlButton(systemName: "minus.magnifyingglass") {
                            adjustZoom(by: -0.5)
                        }

                        Text(String(format: "%.1fx", zoomFactor))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 62)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Capsule())

                        zoomControlButton(systemName: "plus.magnifyingglass") {
                            adjustZoom(by: 0.5)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 88)

                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            scannerHintChip(icon: "camera.aperture", text: localizationManager.string(.tapToCapture))
                            scannerHintChip(icon: "hand.tap", text: localizationManager.string(.tapWordToTranslate))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()
                    HStack(spacing: 40) {
                        // Capture button
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
                    }
                    .padding(.bottom, 110)
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
        .onAppear {
               // 🆕 БЛОКУВАННЯ на вході
               if subscriptionManager.isSubscriptionExpired || !subscriptionManager.canUseApp {
                   dismiss()
                   onShowPaywall?()
                   return
               }
               setupCamera()
           }
        .onDisappear { stopCameraSafely() }
        .alert(localizationManager.string(.permissionRequired), isPresented: $showPermissionAlert) {
            Button(localizationManager.string(.openSettings)) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(localizationManager.string(.cancel), role: .cancel) {}
        } message: {
            switch permissionType {
            case .camera:
                Text(localizationManager.string(.permissionCameraMessage))
            case .microphone:
                Text(localizationManager.string(.permissionMicrophoneMessage))
            case .speech:
                Text(localizationManager.string(.permissionSpeechMessage))
            default:
                Text(localizationManager.string(.permissionMessage))
            }
        }
        .alert(localizationManager.string(.error), isPresented: $showVoiceError) {
            Button(localizationManager.string(.ok), role: .cancel) {}
        } message: {
            Text(voiceErrorMessage)
        }
    }

    private func zoomControlButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 42, height: 42)
                .background(Color.black.opacity(0.42))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        }
    }

    private func scannerHintChip(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))

            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.black.opacity(0.34))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
    
    private func startVoiceSearchWithPermissionCheck() {
        let micStatus = AVAudioApplication.shared.recordPermission
        guard micStatus == .granted else {
            if micStatus == .denied {
                permissionType = .microphone
                showPermissionAlert = true
            } else {
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.checkSpeechPermissionAndStart()
                        } else {
                            self.permissionType = .microphone
                            self.showPermissionAlert = true
                        }
                    }
                }
            }
            return
        }
        
        checkSpeechPermissionAndStart()
    }
    
    private func checkSpeechPermissionAndStart() {
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        
        guard speechStatus == .authorized else {
            if speechStatus == .denied || speechStatus == .restricted {
                permissionType = .speech
                showPermissionAlert = true
            } else {
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        if status == .authorized {
                            self.startVoiceSearch()
                        } else {
                            self.permissionType = .speech
                            self.showPermissionAlert = true
                        }
                    }
                }
            }
            return
        }
        
        startVoiceSearch()
    }
    
    private func startVoiceSearch() {
        print("🎤 Starting voice search from scanner...")
        
        // Stop camera before starting voice search
        stopCameraSafely()
        
        // Here you would typically present a voice search overlay or sheet
        // For now, we'll just show a placeholder implementation
        // You can integrate with your existing VoiceSearchView here
        
        // Example error handling:
        // voiceErrorMessage = localizationManager.string(.recognitionError)
        // showVoiceError = true
    }
    
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
        isRecognizing = true
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        let delegate = PhotoCaptureDelegate { image in
            print("📸 Фото отримано, розмір: \(image.size)")
            DispatchQueue.main.async {
                self.capturedImage = image
                self.isFrozen = true
                self.stopCameraSafely()
                self.imageSize = CGSize(width: image.size.width, height: image.size.height)
                self.recognizeTextInImage(image)
            }
        }
        
        objc_setAssociatedObject(photoOutput, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        isRecognizingText = true
        isRecognizing = true
        
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                print("❌ Recognition error: \(error)")
                DispatchQueue.main.async {
                    self.isRecognizingText = false
                    self.isRecognizing = false
                }
                return
            }
            
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            
            let words = buildRecognizedWords(from: results)
            
            DispatchQueue.main.async {
                self.recognizedWords = Array(words.prefix(16))
                self.isRecognizingText = false
                self.isRecognizing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = recognitionLanguages()
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.02
        if #available(iOS 16.0, *) {
            request.automaticallyDetectsLanguage = true
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImagePropertyOrientation)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do { try handler.perform([request]) }
            catch { print("❌ Handler error: \(error)") }
        }
    }
    
    private func retakePhoto() {
        capturedImage = nil
        recognizedWords = []
        isFrozen = false
        isRecognizing = false
        imageSize = .zero
        focusIndicatorPosition = nil
        stopCameraSafely()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupCamera()
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.isConfiguring = true
            
            // Check permission first
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            guard status == .authorized else {
                DispatchQueue.main.async {
                    self.isConfiguring = false
                    if status == .denied || status == .restricted {
                        self.permissionType = .camera
                        self.showPermissionAlert = true
                    }
                }
                return
            }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            do {
                guard let device = self.bestCameraDevice() else {
                    DispatchQueue.main.async {
                        self.isConfiguring = false
                        self.cameraError = self.localizationManager.string(.cameraNotFoundText)
                    }
                    return
                }
                
                let input = try AVCaptureDeviceInput(device: device)
                if self.session.canAddInput(input) { self.session.addInput(input) }
                if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }
                self.configure(device: device)
                
                self.session.commitConfiguration()
                self.isConfiguring = false
                
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.cameraDevice = device
                    self.maxZoomFactor = min(max(device.activeFormat.videoMaxZoomFactor, 1), 6)
                    self.zoomFactor = 1
                    self.pinchBaseZoomFactor = 1
                    self.isCameraReady = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isConfiguring = false
                    self.cameraError = error.localizedDescription
                }
            }
        }
    }

    private func recognitionLanguages() -> [String] {
        let sourceLang = appState.languagePair.source.rawValue
        let targetLang = appState.languagePair.target.rawValue
        return Array(NSOrderedSet(array: [sourceLang, targetLang, "en-US", "uk-UA", "pl-PL"])) as? [String] ?? [sourceLang, targetLang]
    }

    private func buildRecognizedWords(from observations: [VNRecognizedTextObservation]) -> [RecognizedWord] {
        var seen = Set<String>()
        var collected: [RecognizedWord] = []

        for observation in observations {
            for candidate in observation.topCandidates(2) {
                for token in tokenize(candidate.string) {
                    let normalized = token.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    guard !seen.contains(normalized) else { continue }
                    seen.insert(normalized)

                    collected.append(
                        RecognizedWord(
                            text: token,
                            boundingBox: observation.boundingBox,
                            confidence: candidate.confidence
                        )
                    )
                }
            }
        }

        return collected
            .sorted { lhs, rhs in
                if lhs.confidence == rhs.confidence {
                    return lhs.text.count > rhs.text.count
                }
                return lhs.confidence > rhs.confidence
            }
    }

    private func tokenize(_ text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters.subtracting(CharacterSet(charactersIn: "'-"))))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { token in
                let lettersOnly = token.unicodeScalars.contains { CharacterSet.letters.contains($0) }
                return token.count >= 2 && lettersOnly
            }
    }

    private func bestCameraDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) ??
        AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) ??
        AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private func configure(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.isSubjectAreaChangeMonitoringEnabled = true
            device.videoZoomFactor = 1
            device.unlockForConfiguration()
        } catch {
            print("❌ Failed to configure camera device: \(error)")
        }
    }

    private func handlePinchZoom(scale: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            pinchBaseZoomFactor = zoomFactor
        case .changed, .ended:
            applyZoom(pinchBaseZoomFactor * scale)
        default:
            break
        }
    }

    private func adjustZoom(by delta: CGFloat) {
        applyZoom(zoomFactor + delta)
    }

    private func applyZoom(_ requestedZoom: CGFloat) {
        guard let device = cameraDevice else { return }
        let clamped = min(max(requestedZoom, 1), maxZoomFactor)

        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            zoomFactor = clamped
        } catch {
            print("❌ Failed to set zoom: \(error)")
        }
    }

    private func handleTapToFocus(at viewPoint: CGPoint, devicePoint: CGPoint) {
        guard let device = cameraDevice, !isFrozen else { return }
        focusIndicatorPosition = viewPoint

        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = devicePoint
            }
            if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = devicePoint
            }
            if device.isExposureModeSupported(.autoExpose) {
                device.exposureMode = .autoExpose
            }
            device.unlockForConfiguration()
        } catch {
            print("❌ Failed to focus camera: \(error)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                focusIndicatorPosition = nil
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
        if error != nil { return }
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
    var onTapFocus: ((CGPoint, CGPoint) -> Void)?
    var onPinchZoom: ((CGFloat, UIGestureRecognizer.State) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let pinchRecognizer = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(tapRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
        return view
    }
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.videoPreviewLayer.frame = uiView.bounds
        context.coordinator.parent = self
    }

    class Coordinator: NSObject {
        var parent: CameraPreview

        init(parent: CameraPreview) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view as? VideoPreviewView else { return }
            let viewPoint = recognizer.location(in: view)
            let devicePoint = view.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            parent.onTapFocus?(viewPoint, devicePoint)
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            parent.onPinchZoom?(recognizer.scale, recognizer.state)
        }
    }
}

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

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
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .truncationMode(.tail)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.6),
                                    Color(hex: "#1F2D33").opacity(0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.24), radius: 8, x: 0, y: 4)
                )
        }
    }
}

private struct ScannerGuideOverlay: View {
    let isFrozen: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isFrozen ? 0.12 : 0.18),
                        Color(hex: "#4ECDC4").opacity(isFrozen ? 0.08 : 0.26),
                        Color(hex: "#FFD93D").opacity(isFrozen ? 0.06 : 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 1.5, dash: [10, 8])
            )
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isFrozen ? 0.015 : 0.03),
                                Color(hex: "#4ECDC4").opacity(isFrozen ? 0.015 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 26)
            .padding(.vertical, 150)
            .allowsHitTesting(false)
    }
}

private struct FocusIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color(hex: "#FFD93D"), lineWidth: 2)
            .frame(width: 68, height: 68)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.clear)
            )
    }
}

enum ScannerPermissionType {
    case camera, microphone, speech, tracking, notification
}

private extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
