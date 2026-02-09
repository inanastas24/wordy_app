//1
//  ContactFormBubbleView.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 01.02.2026.
//

import SwiftUI
import FirebaseAuth

struct ContactFormBubbleView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var messageText = ""
    @State private var isSent = false
    @State private var showError = false
    @State private var isLoading = false
    @State private var errorMessage = "Не вдалося відправити повідомлення."
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text("Зв'язок з розробником")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#7F8C8D"))
                        .padding(8)
                        .background(Color.white.opacity(0.6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // MARK: - Text Editor
            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $messageText)
                    .font(.system(size: 16))
                    .foregroundColor(localizationManager.isDarkMode ? .white : Color(hex: "#2C3E50"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(localizationManager.isDarkMode ? Color(hex: "#2C2C2E").opacity(0.6) : Color.white.opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#E0E0E0").opacity(0.5), lineWidth: 1)
                    )
                    .frame(height: 140)
                    .disabled(isSent || isLoading)
                
                Text("\(messageText.count)/500")
                    .font(.system(size: 12))
                    .foregroundColor(messageText.count > 450 ? Color(hex: "#F38BA8") : Color(hex: "#7F8C8D"))
                    .padding(10)
            }
            .padding(.horizontal, 20)
            .onChange(of: messageText) { _, newValue in
                if newValue.count > 500 {
                    withAnimation {
                        messageText = String(newValue.prefix(500))
                    }
                }
            }
            
            if messageText.count < 10 && !isSent {
                Text("Мінімум 10 символів")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#7F8C8D"))
                    .padding(.top, 8)
            }
            
            // MARK: - Send Button
            Button(action: {
                Task {
                    await sendMessage()
                }
            }) {
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isSent ? "checkmark.circle.fill" : "paperplane.fill")
                            .font(.system(size: 18))
                            .contentTransition(.symbolEffect(.replace))
                    }
                    
                    Text(isSent ? "Готово!" : (isLoading ? "Відправка..." : "Надіслати"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    Capsule()
                        .fill(isSent ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4"))
                        .shadow(
                            color: (isSent ? Color(hex: "#2ECC71") : Color(hex: "#4ECDC4")).opacity(0.4),
                            radius: isSent ? 20 : 15,
                            x: 0,
                            y: isSent ? 10 : 8
                        )
                )
                .scaleEffect(isSent ? 1.02 : 1.0)
                .opacity(isLoading ? 0.7 : 1.0)
            }
            .disabled(messageText.count < 10 || isSent || isLoading)
            .opacity(messageText.count < 10 ? 0.6 : 1.0)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSent)
        }
        .frame(width: min(UIScreen.main.bounds.width - 60, 340))
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(hex: "#FFFDF5").opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.ultraThinMaterial)
                )
                .shadow(
                    color: Color(hex: "#4ECDC4").opacity(0.15),
                    radius: 40,
                    x: 0,
                    y: 20
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        )
        .alert("Помилка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Message Sending
    private func sendMessage() async {
        isLoading = true
        
        do {
            // Перевіряємо авторизацію
            guard Auth.auth().currentUser != nil else {
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Користувач не авторизований"])
            }
            
            let deviceInfo = await getDeviceInfo()
            let formattedMessage = formatMessage(messageText, deviceInfo: deviceInfo)
            
            // Відправляємо в Telegram через API
            try await sendToTelegram(message: formattedMessage)
            
            await handleSuccess()
            
        } catch {
            await handleError("Помилка відправки: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Telegram API
    private func sendToTelegram(message: String) async throws {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) as? [String: Any],
              let botToken = config["TelegramBotToken"] as? String,
              let chatId = config["TelegramChatID"] as? String,
              !botToken.isEmpty, !chatId.isEmpty else {
            throw NSError(domain: "Config", code: 500, userInfo: [NSLocalizedDescriptionKey: "Telegram not configured"])
        }
        let urlString = "https://api.telegram.org/bot\(botToken)/sendMessage"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "URL", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "chat_id": chatId,
            "text": message,
            "parse_mode": "HTML"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "HTTP", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil)
        }
        
        // Перевіряємо відповідь
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let ok = json["ok"] as? Bool, !ok {
            throw NSError(domain: "Telegram", code: 500, userInfo: [NSLocalizedDescriptionKey: "Telegram API error"])
        }
    }
    
    private func formatMessage(_ text: String, deviceInfo: String) -> String {
        let date = formatDate()
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        return """
        <b>📩 Нове повідомлення з Wordy</b>
        
        <b>🕐 Дата:</b> \(date)
        <b>👤 Користувач:</b> \(userId.prefix(8))...
        <b>📱 Пристрій:</b> \(deviceInfo)
        
        <b>💬 Повідомлення:</b>
        \(text)
        """
    }
    
    // MARK: - Helpers
    private func getDeviceInfo() async -> String {
        return "\(UIDevice.current.model) iOS \(UIDevice.current.systemVersion)"
    }
    
    private func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        formatter.locale = Locale(identifier: "uk_UA")
        formatter.timeZone = TimeZone(identifier: "Europe/Kyiv")
        return formatter.string(from: Date())
    }
    
    private func handleSuccess() async {
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isSent = true
                isLoading = false
            }
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
    
    private func handleError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
            isLoading = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
