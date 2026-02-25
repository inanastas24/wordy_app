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
import UserNotifications

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var cameraAuthorized = false
    @Published var microphoneAuthorized = false
    @Published var speechAuthorized = false
    @Published var trackingAuthorized = false
    @Published var notificationAuthorized = false
    @Published var trackingStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private let localizationManager = LocalizationManager.shared
    
    private init() {}
    
    // MARK: - Request All Permissions (викликати при першому вході)
    func requestAllPermissions(completion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        
        // Camera
        group.enter()
        requestCameraPermission {
            group.leave()
        }
        
        // Microphone
        group.enter()
        requestMicrophonePermission {
            group.leave()
        }
        
        // Speech
        group.enter()
        requestSpeechPermission {
            group.leave()
        }
        
        // Notifications
        group.enter()
        requestNotificationPermission {
            group.leave()
        }
        
        // Tracking (з затримкою як у тебе було)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            group.enter()
            self.requestTrackingPermission {
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion?()
        }
    }
    
    // MARK: - Camera Permission
    func requestCameraPermission(completion: (() -> Void)? = nil) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAuthorized = granted
                    completion?()
                }
            }
        case .authorized:
            self.cameraAuthorized = true
            completion?()
        case .denied, .restricted:
            self.cameraAuthorized = false
            completion?()
        @unknown default:
            completion?()
        }
    }
    
    // MARK: - Microphone Permission
    func requestMicrophonePermission(completion: (() -> Void)? = nil) {
        let status = AVAudioApplication.shared.recordPermission
        switch status {
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphoneAuthorized = granted
                    completion?()
                }
            }
        case .granted:
            self.microphoneAuthorized = true
            completion?()
        case .denied:
            self.microphoneAuthorized = false
            completion?()
        @unknown default:
            completion?()
        }
    }
    
    // MARK: - Speech Recognition Permission
    func requestSpeechPermission(completion: (() -> Void)? = nil) {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    self.speechAuthorized = authStatus == .authorized
                    completion?()
                }
            }
        case .authorized:
            self.speechAuthorized = true
            completion?()
        case .denied, .restricted:
            self.speechAuthorized = false
            completion?()
        @unknown default:
            completion?()
        }
    }
    
    // MARK: - Notification Permission
    func requestNotificationPermission(completion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationAuthorized = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                completion?()
            }
        }
    }
    
    // MARK: - App Tracking Transparency Permission
    func requestTrackingPermission(completion: (() -> Void)? = nil) {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            self.trackingStatus = status
            
            switch status {
            case .notDetermined:
                ATTrackingManager.requestTrackingAuthorization { [weak self] authStatus in
                    DispatchQueue.main.async {
                        self?.trackingStatus = authStatus
                        self?.trackingAuthorized = authStatus == .authorized
                        completion?()
                    }
                }
            case .authorized:
                self.trackingAuthorized = true
                self.trackingStatus = .authorized
                completion?()
            case .denied, .restricted:
                self.trackingAuthorized = false
                self.trackingStatus = status
                completion?()
            @unknown default:
                completion?()
            }
        } else {
            self.trackingAuthorized = true
            completion?()
        }
    }
    
    // MARK: - Check All Permissions Status
    func checkAllPermissions() {
        cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        microphoneAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationAuthorized = settings.authorizationStatus == .authorized
            }
        }
        
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
