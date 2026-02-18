//  TextScannerView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 26.01.2026.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation

struct TextScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Binding var isRecognizing: Bool
    var onTextRecognized: ((String) -> Void)?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onTextRecognized = { [weak controller] text in
            self.scannedText = text
            self.onTextRecognized?(text)
            controller?.dismiss(animated: true)
        }
        controller.onCancel = {
            self.dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

// MARK: - Scanner View Controller
class ScannerViewController: UIViewController {
    
    var onTextRecognized: ((String) -> Void)?
    var onCancel: (() -> Void)?
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDevice: AVCaptureDevice?
    
    // UI елементи
    private var cropView: CropFrameView!
    private var widthConstraint: NSLayoutConstraint!
    private var heightConstraint: NSLayoutConstraint!
    
    // Розміри рамки
    private let defaultWidth: CGFloat = 280
    private let defaultHeight: CGFloat = 100
    private let minSize: CGFloat = 60
    private let maxSize: CGFloat = 350
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showError("Не вдалося отримати доступ до камери")
            return
        }
        
        self.videoDevice = device
        
        let output = AVCapturePhotoOutput()
        output.isHighResolutionCaptureEnabled = true
        
        if session.canAddInput(input) && session.canAddOutput(output) {
            session.addInput(input)
            session.addOutput(output)
            photoOutput = output
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Кнопка закрити
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 22
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Підказка
        let hintLabel = UILabel()
        hintLabel.text = "Змініть розмір рамки\nPinch для наближення камери"
        hintLabel.numberOfLines = 2
        hintLabel.textAlignment = .center
        hintLabel.font = .systemFont(ofSize: 13, weight: .medium)
        hintLabel.textColor = .white
        hintLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        hintLabel.layer.cornerRadius = 8
        hintLabel.clipsToBounds = true
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 12),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            hintLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Рамка вибору (фіксована по центру, тільки зміна розміру)
        cropView = CropFrameView()
        cropView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cropView)
        
        widthConstraint = cropView.widthAnchor.constraint(equalToConstant: defaultWidth)
        heightConstraint = cropView.heightAnchor.constraint(equalToConstant: defaultHeight)
        
        NSLayoutConstraint.activate([
            cropView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cropView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            widthConstraint,
            heightConstraint
        ])
        
        // Передаємо констрейнти
        cropView.widthConstraint = widthConstraint
        cropView.heightConstraint = heightConstraint
        cropView.minWidth = minSize
        cropView.minHeight = minSize
        cropView.maxWidth = maxSize
        cropView.maxHeight = maxSize
        
        // Pinch для zoom камери
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
        
        // Кнопка сканування
        let scanButton = UIButton(type: .system)
        scanButton.backgroundColor = UIColor(hex: "#4ECDC4")
        scanButton.layer.cornerRadius = 35
        scanButton.layer.borderWidth = 4
        scanButton.layer.borderColor = UIColor.white.cgColor
        scanButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        scanButton.tintColor = .white
        scanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanButton)
        
        NSLayoutConstraint.activate([
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            scanButton.widthAnchor.constraint(equalToConstant: 70),
            scanButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Кнопка скидання розміру
        let resetButton = UIButton(type: .system)
        resetButton.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        resetButton.tintColor = .white
        resetButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        resetButton.layer.cornerRadius = 20
        resetButton.addTarget(self, action: #selector(resetSize), for: .touchUpInside)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resetButton)
        
        NSLayoutConstraint.activate([
            resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            resetButton.widthAnchor.constraint(equalToConstant: 40),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        onCancel?()
    }
    
    @objc private func resetSize() {
        UIView.animate(withDuration: 0.3) {
            self.widthConstraint.constant = self.defaultWidth
            self.heightConstraint.constant = self.defaultHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let device = videoDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            let currentZoom = device.videoZoomFactor
            let newZoom = min(max(currentZoom * gesture.scale, 1.0), device.activeFormat.videoMaxZoomFactor)
            
            device.videoZoomFactor = newZoom
            gesture.scale = 1.0
            
            device.unlockForConfiguration()
        } catch {
            print("⚠️ Помилка zoom: \(error)")
        }
    }
    
    @objc private func scanTapped() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Помилка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Photo Capture Delegate
extension ScannerViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("❌ Помилка: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            return
        }
        
        // Отримуємо координати рамки
        let cropRect = calculateCropRect(in: image)
        print("📸 Сканування області: \(cropRect)")
        
        // Обрізаємо і розпізнаємо
        guard let croppedImage = cropImage(image, to: cropRect) else {
            recognizeText(in: image)
            return
        }
        
        recognizeText(in: croppedImage)
    }
    
    private func calculateCropRect(in image: UIImage) -> CGRect {
        guard let previewLayer = previewLayer else {
            return CGRect(origin: .zero, size: image.size)
        }
        
        let cropFrame = cropView.frame
        let previewBounds = previewLayer.bounds
        let imageSize = image.size
        
        // Масштаб для resizeAspectFill
        let previewAspect = previewBounds.width / previewBounds.height
        let imageAspect = imageSize.width / imageSize.height
        
        var scale: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        
        if imageAspect > previewAspect {
            // Зображення ширше
            scale = imageSize.height / previewBounds.height
            let scaledWidth = previewBounds.width * scale
            offsetX = (scaledWidth - imageSize.width) / 2
        } else {
            // Зображення вище
            scale = imageSize.width / previewBounds.width
            let scaledHeight = previewBounds.height * scale
            offsetY = (scaledHeight - imageSize.height) / 2
        }
        
        // Конвертуємо координати
        let imageX = (cropFrame.minX * scale) - offsetX
        let imageY = (cropFrame.minY * scale) - offsetY
        let imageWidth = cropFrame.width * scale
        let imageHeight = cropFrame.height * scale
        
        // Інвертуємо Y для CGImage
        let cgImageY = imageSize.height - imageY - imageHeight
        
        return CGRect(
            x: max(0, imageX),
            y: max(0, cgImageY),
            width: min(imageWidth, imageSize.width),
            height: min(imageHeight, imageSize.height)
        )
    }
    
    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let boundedRect = CGRect(
            x: max(0, min(rect.minX, CGFloat(cgImage.width))),
            y: max(0, min(rect.minY, CGFloat(cgImage.height))),
            width: min(rect.width, CGFloat(cgImage.width) - rect.minX),
            height: min(rect.height, CGFloat(cgImage.height) - rect.minY)
        )
        
        guard boundedRect.width > 10 && boundedRect.height > 10 else { return nil }
        
        guard let cropped = cgImage.cropping(to: boundedRect) else { return nil }
        
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func recognizeText(in image: UIImage) {
        guard let cgImage = image.cgImage else {
            onTextRecognized?("")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                self.onTextRecognized?("")
                return
            }
            
            let text = observations
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("✅ Розпізнано: '\(text)'")
            self.onTextRecognized?(text)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en", "uk", "de", "fr", "es", "it", "pl"]
        request.usesLanguageCorrection = true
        
        do {
            try handler.perform([request])
        } catch {
            onTextRecognized?("")
        }
    }
}

// MARK: - Crop Frame View (тільки зміна розміру, без перетягування)
class CropFrameView: UIView {
    
    weak var widthConstraint: NSLayoutConstraint?
    weak var heightConstraint: NSLayoutConstraint?
    
    var minWidth: CGFloat = 60
    var minHeight: CGFloat = 60
    var maxWidth: CGFloat = 350
    var maxHeight: CGFloat = 350
    
    private var initialSize: CGSize = .zero
    private var activeHandle: String?
    
    // Розміри ручок
    private let handleTouchSize: CGFloat = 50
    private let handleVisualSize: CGFloat = 24
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // Напівпрозорий фон
        let fillView = UIView()
        fillView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        fillView.isUserInteractionEnabled = false
        fillView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(fillView)
        
        NSLayoutConstraint.activate([
            fillView.topAnchor.constraint(equalTo: topAnchor),
            fillView.leadingAnchor.constraint(equalTo: leadingAnchor),
            fillView.trailingAnchor.constraint(equalTo: trailingAnchor),
            fillView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Рамка
        let borderView = UIView()
        borderView.isUserInteractionEnabled = false
        borderView.layer.borderColor = UIColor(hex: "#4ECDC4").cgColor
        borderView.layer.borderWidth = 3
        borderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(borderView)
        
        NSLayoutConstraint.activate([
            borderView.topAnchor.constraint(equalTo: topAnchor),
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Ручки для зміни розміру (тільки по кутах)
        createHandle(name: "left", h: .leading, v: .centerY, cursor: "arrow.left.and.right")
        createHandle(name: "right", h: .trailing, v: .centerY, cursor: "arrow.left.and.right")
        createHandle(name: "top", h: .centerX, v: .top, cursor: "arrow.up.and.down")
        createHandle(name: "bottom", h: .centerX, v: .bottom, cursor: "arrow.up.and.down")
        
        // Кутові ручки для діагональної зміни
        createHandle(name: "topLeft", h: .leading, v: .top, cursor: "arrow.up.left.and.down.right")
        createHandle(name: "topRight", h: .trailing, v: .top, cursor: "arrow.up.right.and.down.left")
        createHandle(name: "bottomLeft", h: .leading, v: .bottom, cursor: "arrow.up.right.and.down.left")
        createHandle(name: "bottomRight", h: .trailing, v: .bottom, cursor: "arrow.up.left.and.down.right")
    }
    
    private func createHandle(name: String, h: NSLayoutConstraint.Attribute, v: NSLayoutConstraint.Attribute, cursor: String) {
        // Візуальний елемент
        let visual = UIView()
        visual.backgroundColor = UIColor(hex: "#4ECDC4")
        visual.layer.cornerRadius = handleVisualSize / 2
        visual.layer.shadowColor = UIColor.black.cgColor
        visual.layer.shadowOffset = CGSize(width: 0, height: 2)
        visual.layer.shadowRadius = 4
        visual.layer.shadowOpacity = 0.3
        visual.isUserInteractionEnabled = false
        visual.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visual)
        
        // Область дотику (більша)
        let touch = UIView()
        touch.backgroundColor = .clear
        touch.tag = name.hashValue
        touch.isUserInteractionEnabled = true
        touch.translatesAutoresizingMaskIntoConstraints = false
        addSubview(touch)
        
        NSLayoutConstraint.activate([
            visual.widthAnchor.constraint(equalToConstant: handleVisualSize),
            visual.heightAnchor.constraint(equalToConstant: handleVisualSize),
            NSLayoutConstraint(item: visual, attribute: h, relatedBy: .equal, toItem: self, attribute: h, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: visual, attribute: v, relatedBy: .equal, toItem: self, attribute: v, multiplier: 1, constant: 0),
            
            touch.widthAnchor.constraint(equalToConstant: handleTouchSize),
            touch.heightAnchor.constraint(equalToConstant: handleTouchSize),
            touch.centerXAnchor.constraint(equalTo: visual.centerXAnchor),
            touch.centerYAnchor.constraint(equalTo: visual.centerYAnchor)
        ])
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        touch.addGestureRecognizer(pan)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = self.superview,
              let widthConstraint = widthConstraint,
              let heightConstraint = heightConstraint else { return }
        
        let translation = gesture.translation(in: superview)
        
        if gesture.state == .began {
            initialSize = CGSize(width: widthConstraint.constant, height: heightConstraint.constant)
            activeHandle = getHandleName(from: gesture.view?.tag)
        }
        
        if gesture.state == .changed, let handle = activeHandle {
            let deltaX = translation.x
            let deltaY = translation.y
            
            var newWidth = initialSize.width
            var newHeight = initialSize.height
            
            // Зміна ширини
            if handle.contains("left") {
                newWidth = max(minWidth, min(maxWidth, initialSize.width - deltaX))
            } else if handle.contains("right") {
                newWidth = max(minWidth, min(maxWidth, initialSize.width + deltaX))
            }
            
            // Зміна висоти
            if handle.contains("top") {
                newHeight = max(minHeight, min(maxHeight, initialSize.height - deltaY))
            } else if handle.contains("bottom") {
                newHeight = max(minHeight, min(maxHeight, initialSize.height + deltaY))
            }
            
            // Застосовуємо
            widthConstraint.constant = newWidth
            heightConstraint.constant = newHeight
            
            gesture.setTranslation(.zero, in: superview)
            superview.layoutIfNeeded()
        }
        
        if gesture.state == .ended || gesture.state == .cancelled {
            activeHandle = nil
        }
    }
    
    private func getHandleName(from tag: Int?) -> String {
        let handles = ["left", "right", "top", "bottom", "topLeft", "topRight", "bottomLeft", "bottomRight"]
        for handle in handles {
            if handle.hashValue == tag {
                return handle
            }
        }
        return ""
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
