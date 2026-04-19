//  ContactFormBubbleView.swift
//  Wordy
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions 

struct ContactFormBubbleView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var messageText = ""
    @State private var isSent = false
    @State private var showError = false
    @State private var isLoading = false
    @State private var errorMessage = "Не вдалося відправити повідомлення."
    @State private var debugInfo: String = ""
    
    // Firestore референс
    private let db = Firestore.firestore()
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 38, height: 5)
                    .padding(.top, 12)

                if !debugInfo.isEmpty {
                    Text(debugInfo)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                
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
                        .frame(minHeight: 140, maxHeight: 220)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
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
                .padding(.horizontal, 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSent)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: 380)
        .frame(maxHeight: 430)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(hex: "#FFFDF5").opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
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
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
        )
        .dismissKeyboardOnTap()
        .alert("Помилка", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Message Sending
    private func sendMessage() async {
        isLoading = true
        debugInfo = localizationManager.string(.sendingStart)
        
        do {
            guard let currentUser = Auth.auth().currentUser else {
                debugInfo = localizationManager.string(.authError)
                throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: localizationManager.string(.notAuthenticated)])
            }
            
            debugInfo = "✅ \(localizationManager.string(.authenticated)): \(currentUser.uid.prefix(8))..."
            
            // Зберігаємо в Firestore
            do {
                try await saveToFirestore(message: messageText, userId: currentUser.uid)
                debugInfo = "✅ Firestore OK"
            } catch {
                debugInfo = "❌ Firestore: \(error.localizedDescription)"
                
                // Перевірка ліміту з локалізацією
                let errorText = error.localizedDescription.lowercased()
                if errorText.contains("ліміт") || errorText.contains("limit") || errorText.contains("resource-exhausted") || errorText.contains("10") {
                    await MainActor.run {
                        errorMessage = localizationManager.string(.messageLimitMessage)
                        showError = true
                        isLoading = false
                    }
                    return
                }
                throw error
            }
            
            // Відправляємо в Telegram
            do {
                let deviceInfo = await getDeviceInfo()
                let formattedMessage = formatMessage(messageText, deviceInfo: deviceInfo)
                try await sendToTelegram(message: formattedMessage)
                debugInfo = "✅ Telegram OK"
            } catch {
                debugInfo += "\n❌ Telegram: \(error.localizedDescription)"
            }
            
            await handleSuccess()
            
        } catch {
            await handleError("\(localizationManager.string(.error)): \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Firestore Saving
    private func saveToFirestore(message: String, userId: String) async throws {
        debugInfo = "📝 Викликаємо Cloud Function..."
        
        let functions = Functions.functions()
        
        do {
            let result = try await functions.httpsCallable("saveContactMessage").call([
                "message": message
            ])
            
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool,
               success {
                debugInfo = "✅ Збережено! ID: \(data["id"] ?? "unknown")"
            } else {
                debugInfo = "⚠️ Невідповідна відповідь"
            }
            
        } catch {
            debugInfo = "❌ Cloud Function: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Telegram API
    private func sendToTelegram(message: String) async throws {
        guard ConfigService.shared.isTelegramConfigured,
              let botToken = ConfigService.shared.telegramBotToken,
              let chatId = ConfigService.shared.telegramChatID else {
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
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw NSError(domain: "HTTP", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
        }
        
        print("✅ Telegram OK")
    }
    
    // MARK: - Helpers
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
