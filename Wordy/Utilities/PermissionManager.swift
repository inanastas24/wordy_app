//
//  PermissionManager.swift
//  Wordy
//

import SwiftUI
import Combine
import AVFoundation
import Speech
import AppTrackingTransparency
import AdSupport

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var cameraAuthorized = false
    @Published var microphoneAuthorized = false
    @Published var speechAuthorized = false
    @Published var trackingAuthorized = false
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private let localizationManager = LocalizationManager.shared
    
    private init() {}
    
    // MARK: - Request All Permissions
    func requestAllPermissions() {
        requestCameraPermission()
        requestMicrophonePermission()
        requestSpeechPermission()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestTrackingPermission()
        }
    }
    
    // MARK: - Camera Permission
    func requestCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAuthorized = granted
                }
            }
        case .authorized:
            self.cameraAuthorized = true
        case .denied, .restricted:
            self.cameraAuthorized = false
        @unknown default:
            break
        }
    }
    
    // MARK: - Microphone Permission
    func requestMicrophonePermission() {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphoneAuthorized = granted
                }
            }
        case .granted:
            self.microphoneAuthorized = true
        case .denied:
            self.microphoneAuthorized = false
        @unknown default:
            break
        }
    }
    
    // MARK: - Speech Recognition Permission
    func requestSpeechPermission() {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    self.speechAuthorized = authStatus == .authorized
                }
            }
        case .authorized:
            self.speechAuthorized = true
        case .denied, .restricted:
            self.speechAuthorized = false
        @unknown default:
            break
        }
    }
    
    // MARK: - App Tracking Transparency Permission
    func requestTrackingPermission() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            self.trackingStatus = status
            
            switch status {
            case .notDetermined:
                ATTrackingManager.requestTrackingAuthorization { [weak self] authStatus in
                    DispatchQueue.main.async {
                        self?.trackingStatus = authStatus
                        self?.trackingAuthorized = authStatus == .authorized
                        
                        if authStatus == .authorized {
                            print("✅ Tracking authorized")
                        } else {
                            print("❌ Tracking denied: \(authStatus)")
                        }
                    }
                }
            case .authorized:
                self.trackingAuthorized = true
                self.trackingStatus = .authorized
            case .denied, .restricted:
                self.trackingAuthorized = false
                self.trackingStatus = status
            @unknown default:
                break
            }
        } else {
            self.trackingAuthorized = true
        }
    }
    
    // MARK: - Check All Permissions Status
    func checkAllPermissions() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        if #available(iOS 14, *) {
            trackingStatus = ATTrackingManager.trackingAuthorizationStatus
            trackingAuthorized = trackingStatus == .authorized
        } else {
            trackingAuthorized = true
        }
    }
    
    // MARK: - Individual Checkers
    func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }
    
    func checkSpeechPermission() -> SFSpeechRecognizerAuthorizationStatus {
        return SFSpeechRecognizer.authorizationStatus()
    }
    
    @available(iOS 14, *)
    func checkTrackingPermission() -> ATTrackingManager.AuthorizationStatus {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    
    // MARK: - Custom Pre-Permission Alert (локалізований)
    func showPrePermissionAlert(
        for type: PermissionType,
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        let titleKey: LocalizableKey
        let messageKey: LocalizableKey
        
        switch type {
        case .camera:
            titleKey = .permissionCameraTitle
            messageKey = .permissionCameraMessage
        case .microphone:
            titleKey = .permissionMicrophoneTitle
            messageKey = .permissionMicrophoneMessage
        case .speech:
            titleKey = .permissionSpeechTitle
            messageKey = .permissionSpeechMessage
        case .tracking:
            titleKey = .permissionTrackingTitle
            messageKey = .permissionTrackingMessage
        }
        
        let alert = UIAlertController(
            title: localizationManager.string(titleKey),
            message: localizationManager.string(messageKey),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: localizationManager.string(.permissionAllow),
            style: .default
        ) { _ in
            completion(true)
        })
        
        alert.addAction(UIAlertAction(
            title: localizationManager.string(.permissionDeny),
            style: .cancel
        ) { _ in
            completion(false)
        })
        
        viewController.present(alert, animated: true)
    }
    
    // MARK: - Settings Alert when denied (локалізований)
    func showSettingsAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: localizationManager.string(.permissionRequired),
            message: localizationManager.string(.permissionMessage),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: localizationManager.string(.permissionSettings),
            style: .default
        ) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(
            title: localizationManager.string(.cancel),
            style: .cancel
        ))
        
        viewController.present(alert, animated: true)
    }
}
