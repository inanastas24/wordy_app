import Foundation
import Combine
import StoreKit
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum SubscriptionStatus: Equatable {
    case trial(daysLeft: Int)
    case trialExpired
    case premium(expiryDate: Date?, isInGracePeriod: Bool)
    case expired(expiryDate: Date?)  // 🆕 Додаємо дату експайрі
    case billingRetry
    case unknown
    
    var canUseApp: Bool {
        switch self {
        case .trial:
            return true
        case .premium(_, let isInGracePeriod):
            return !isInGracePeriod
        case .billingRetry, .trialExpired, .expired, .unknown:
            return false
        }
    }
}

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var status: SubscriptionStatus = .unknown
    @Published private(set) var currentProduct: Product?
    @Published private(set) var trialStartDate: Date?
    @Published private(set) var trialEndDate: Date?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false
    
    @Published var products: [Product] = []

    private let monthlyProductID = "com.wordy.monthly"
    private let yearlyProductID = "com.wordy.yearly"
    
    private let gracePeriodDays = 3
    
    private let db = Firestore.firestore()
    
    private var transactionListener: Task<Void, Never>?
    private var lastKnownProductID: String?

    // MARK: - Helper Properties
    
    var isPremium: Bool {
        if case .premium = status { return true }
        return false
    }
    
    var isTrialActive: Bool {
        if case .trial = status { return true }
        return false
    }
    
    var isTrialExpired: Bool {
        if case .trialExpired = status { return true }
        return false
    }
    
    /// 🆕 Чи закінчилась підписка (показуємо "оновити")
    var isSubscriptionExpired: Bool {
        if case .expired = status { return true }
        return false
    }
    
    /// 🆕 Користувач може використовувати додаток
    var canUseApp: Bool {
        return status.canUseApp
    }
    
    var trialDaysLeft: Int {
        if case .trial(let daysLeft) = status { return daysLeft }
        return 0
    }
    
    var shouldShowBillingIssue: Bool {
        if case .billingRetry = status { return true }
        if case .premium(_, let isInGracePeriod) = status, isInGracePeriod { return true }
        return false
    }
    
    /// 🆕 Дата закінчення підписки для відображення
    var expiryDate: Date? {
        switch status {
        case .premium(let date, _), .expired(let date):
            return date
        default:
            return nil
        }
    }

    init() {}

    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Public Methods
    
    func loadSubscriptionData() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        print("⏳ SubscriptionManager.loadSubscriptionData() started")
        
        // 🆕 Крок 0: Спочатку перевіряємо Firebase (для відновлених/перевстановлених додатків)
        await checkFirebaseSubscription()
        
        if isPremium || isTrialActive {
            print("✅ Found active subscription in Firebase")
        }
        
        // ✅ Завжди завантажуємо продукти, навіть якщо Firebase вже знайшов підписку
        await loadProductsWithRetry()
        
        // ✅ Після завантаження продуктів підв’язуємо currentProduct з Firebase / попереднього стану
        syncCurrentProductFromStatus()
        
        // Якщо в Firebase не знайшли активну підписку — перевіряємо StoreKit
        if !isPremium && !isTrialActive {
            print("📦 No active Firebase subscription, checking StoreKit...")
            await checkStoreKitEntitlements()
            
            // 🆕 Якщо знайшли в StoreKit — синхронізуємо в Firebase
            if isPremium || isTrialActive {
                await syncCurrentSubscriptionToFirebase()
            }
        }
        
        // Крок 2: Запускаємо слухач транзакцій
        if transactionListener == nil {
            transactionListener = listenForTransactions()
        }
        
        print("✅ SubscriptionManager.loadSubscriptionData() completed: \(status)")
    }

    // MARK: - 🆕 Firebase Methods (НОВІ)

    /// Перевіряє підписку в Firebase (для користувачів, які перевстановили додаток)
    private func checkFirebaseSubscription() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No user ID, skipping Firebase check")
            return
        }
        
        print("🔥 Checking Firebase subscription for user: \(userId)")
        
        do {
            let doc = try await db.collection("subscriptions").document(userId).getDocument()
            
            guard let data = doc.data() else {
                print("ℹ️ No subscription document in Firebase")
                return
            }
            
            // Перевіряємо чи підписка активна
            let isActive = data["isActive"] as? Bool ?? false
            let expiryTimestamp = data["expiryDate"] as? Timestamp
            let productId = data["productId"] as? String ?? ""
            
            if !productId.isEmpty {
                lastKnownProductID = productId
            }
            
            guard isActive, let expiry = expiryTimestamp?.dateValue() else {
                print("ℹ️ Firebase subscription inactive or no expiry")
                return
            }
            
            // Перевіряємо чи не протермінована
            let now = Date()
            if expiry > now {
                // 🆕 Активна підписка в Firebase!
                let isInGracePeriod = data["isInGracePeriod"] as? Bool ?? false
                
                status = .premium(expiryDate: expiry, isInGracePeriod: isInGracePeriod)
                currentProduct = products.first { $0.id == productId }
                
                // Зберігаємо дати для UI
                trialEndDate = expiry
                
                print("✅ Found active Firebase subscription: \(productId), expires: \(expiry)")
            } else {
                // Підписка протермінована — оновлюємо статус
                print("⚠️ Firebase subscription expired on: \(expiry)")
                status = .expired(expiryDate: expiry)
                
                // Оновлюємо Firebase що підписка неактивна
                try? await db.collection("subscriptions").document(userId).updateData([
                    "isActive": false,
                    "updatedAt": Timestamp(date: Date())
                ])
            }
            
        } catch {
            print("❌ Error fetching Firebase subscription: \(error.localizedDescription)")
            // Не змінюємо статус — продовжимо з StoreKit
        }
    }

    /// Синхронізує поточну StoreKit підписку в Firebase
    private func syncCurrentSubscriptionToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        // Шукаємо активну транзакцію
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                guard transaction.productType == .autoRenewable,
                      transaction.revocationDate == nil,
                      let expirationDate = transaction.expirationDate,
                      expirationDate > Date() else { continue }
                
                lastKnownProductID = transaction.productID
                
                let data: [String: Any] = [
                    "userId": userId,
                    "email": userEmail,
                    "productId": transaction.productID,
                    "expiryDate": Timestamp(date: expirationDate),
                    "isActive": true,
                    "purchaseDate": Timestamp(date: transaction.purchaseDate),
                    "updatedAt": Timestamp(date: Date()),
                    "transactionId": String(transaction.id),
                    "environment": transaction.environment.rawValue,
                    "originalTransactionId": transaction.originalID,
                    "restoredAt": Timestamp(date: Date())  // 🆕 Позначаємо що відновлено
                ]
                
                try await db.collection("subscriptions").document(userId).setData(data, merge: true)
                print("🔄 Synced StoreKit subscription to Firebase")
                return  // Беремо першу знайдену
                
            } catch {
                continue
            }
        }
    }
    
    func refreshStatus() async {
        await checkStoreKitEntitlements()
    }
    
    // MARK: - StoreKit Methods
    
    func purchase(product: Product) async -> Bool {
        print("🛒 SubscriptionManager.purchase() started for \(product.id)")
        
        do {
            print("🛒 Calling product.purchase()...")
            let result = try await product.purchase()
            print("🛒 product.purchase() returned: \(result)")
            
            switch result {
            case .success(let verification):
                print("🛒 Purchase success, verifying...")
                let transaction = try checkVerified(verification)
                print("🛒 Transaction verified: \(transaction.id)")
                
                await handleVerifiedTransaction(transaction)
                await saveSubscriptionToFirestore(product: product, transaction: transaction)
                await transaction.finish()
                
                print("✅ Purchase fully completed")
                return true
                
            case .pending:
                print("⏳ Purchase pending")
                await MainActor.run {
                    self.errorMessage = "Purchase pending approval from parent/guardian"
                }
                return false
                
            case .userCancelled:
                print("❌ User cancelled")
                return false
                
            @unknown default:
                print("❌ Unknown result")
                return false
            }
        } catch StoreError.failedVerification {
            print("❌ Failed verification")
            await MainActor.run {
                self.errorMessage = "Purchase verification failed. Please try again."
            }
            return false
        } catch {
            print("❌ Purchase error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            return false
        }
    }

    func restorePurchases() async -> Bool {
        print("🔄 Restoring purchases...")
        
        do {
            try await AppStore.sync()
            
            // 🆕 Спочатку перевіряємо StoreKit
            await checkStoreKitEntitlements()
            
            // 🆕 Якщо знайшли — синхронізуємо в Firebase
            if isPremium || isTrialActive {
                await syncCurrentSubscriptionToFirebase()
                syncCurrentProductFromStatus()
                return true
            }
            
            // 🆕 Якщо в StoreKit немає — перевіряємо Firebase (можливо підписка з іншого пристрою)
            await checkFirebaseSubscription()
            
            // ✅ Після restore ще раз підв’язуємо currentProduct
            syncCurrentProductFromStatus()
            
            return isPremium
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func checkStoreKitEntitlements() async {
        print("⏳ Checking StoreKit entitlements...")
        
        var foundActiveSubscription = false
        var lastExpiredTransaction: StoreKit.Transaction?
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                guard transaction.productType == .autoRenewable else { continue }
                
                // Перевіряємо чи не revoked
                if transaction.revocationDate != nil {
                    print("⚠️ Subscription revoked")
                    continue
                }
                
                // Перевіряємо expiration
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        // Активна підписка
                        await handleVerifiedTransaction(transaction)
                        foundActiveSubscription = true
                    } else {
                        // Закінчилась - зберігаємо для можливого відображення
                        lastExpiredTransaction = transaction
                        print("ℹ️ Found expired subscription: \(expirationDate)")
                    }
                } else {
                    // Lifetime підписка
                    await handleVerifiedTransaction(transaction)
                    foundActiveSubscription = true
                }
                
            } catch {
                print("⚠️ Failed to verify transaction: \(error)")
            }
        }
        
        if !foundActiveSubscription {
            if let expired = lastExpiredTransaction {
                // 🆕 Показуємо що підписка закінчилась, а не "невідомо"
                await MainActor.run {
                    self.status = .expired(expiryDate: expired.expirationDate)
                    self.lastKnownProductID = expired.productID
                    self.syncCurrentProductFromStatus()
                    print("❌ Subscription expired on: \(expired.expirationDate ?? Date())")
                }
            } else {
                // Справді немає підписки (ніколи не купували)
                await MainActor.run {
                    self.status = .unknown
                    self.currentProduct = nil
                    print("ℹ️ No subscription history found")
                }
            }
        }
    }
    
    private func handleVerifiedTransaction(_ transaction: StoreKit.Transaction) async {
        lastKnownProductID = transaction.productID
        
        if let revocationDate = transaction.revocationDate {
            print("⚠️ Subscription revoked on: \(revocationDate)")
            status = .expired(expiryDate: transaction.expirationDate)
            syncCurrentProduct(for: transaction.productID)
            return
        }
        
        if let expirationDate = transaction.expirationDate {
            let now = Date()
            
            if expirationDate > now {
                // Активна підписка
                status = .premium(expiryDate: expirationDate, isInGracePeriod: false)
                currentProduct = products.first { $0.id == transaction.productID }
                print("✅ Active subscription until: \(expirationDate)")
                
                // 🆕 Плануємо нотифікації тільки якщо це новий trial (перші 3 дні)
                // Перевіряємо чи це перша підписка (purchaseDate близько до now)
                let isNewTrial = isNewTrialPurchase(transaction)
                if isNewTrial {
                    NotificationManager.shared.scheduleTrialNotifications(trialStartDate: expirationDate)
                }
                
            } else {
                // Grace period перевірка
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: expirationDate, to: now)
                let daysSinceExpiry = components.day ?? 0
                
                if daysSinceExpiry <= gracePeriodDays {
                    status = .billingRetry
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("⚠️ Billing retry / grace period")
                } else {
                    // 🆕 Підписка закінчилась
                    status = .expired(expiryDate: expirationDate)
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("❌ Subscription expired")
                }
            }
        } else {
            // Lifetime
            status = .premium(expiryDate: nil, isInGracePeriod: false)
            syncCurrentProduct(for: transaction.productID)
            print("✅ Lifetime subscription")
        }
    }
    
    private func isNewTrialPurchase(_ transaction: StoreKit.Transaction) -> Bool {
        // Якщо покупка зроблена менше ніж годину тому - це нова
        let purchaseDate = transaction.purchaseDate
        let timeSincePurchase = Date().timeIntervalSince(purchaseDate)
        return timeSincePurchase < 3600 // 1 година
    }
    
    // MARK: - Firestore

    private func saveSubscriptionToFirestore(product: Product, transaction: StoreKit.Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 🆕 Додаємо email користувача
        let userEmail = Auth.auth().currentUser?.email ?? ""
        
        let expirationDate = transaction.expirationDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60)
        
        lastKnownProductID = product.id
        
        let data: [String: Any] = [
            "userId": userId,
            "email": userEmail,  // 🆕 Додаємо email
            "productId": product.id,
            "expiryDate": Timestamp(date: expirationDate),
            "isActive": true,
            "purchaseDate": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "transactionId": String(transaction.id),
            "environment": transaction.environment.rawValue,
            "originalTransactionId": transaction.originalID
        ]
        
        do {
            try await db.collection("subscriptions").document(userId).setData(data, merge: true)
            print("✅ Subscription saved to Firestore with email: \(userEmail)")
        } catch {
            print("⚠️ Failed to save to Firestore: \(error)")
        }
    }

    // Оновлення при відновленні покупок
    private func updateFirestoreFromCurrentEntitlements(userId: String) async {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productType == .autoRenewable else { continue }
            
            let data: [String: Any] = [
                "restoredAt": Timestamp(date: Date()),
                "updatedAt": Timestamp(date: Date()),
                "isActive": true,
                "email": userEmail  // 🆕 Оновлюємо email
            ]
            
            try? await db.collection("subscriptions").document(userId).setData(data, merge: true)
        }
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self = self else { return }
                
                do {
                    let transaction = try self.checkVerified(update)
                    
                    Task { @MainActor in
                        await self.handleVerifiedTransaction(transaction)
                        await transaction.finish()
                    }
                } catch {
                    print("⚠️ Transaction update verification failed: \(error)")
                }
            }
        }
    }

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let transaction):
            return transaction
        }
    }
    
    private func loadProductsWithRetry() async {
        print("⏳ Loading products...")
        
        let ids = [monthlyProductID, yearlyProductID]
        
        for attempt in 1...3 {
            do {
                let result = try await Product.products(for: ids)
                
                await MainActor.run {
                    self.products = result.sorted { $0.id.contains("year") && !$1.id.contains("year") }
                    print("✅ Products loaded: \(self.products.count)")
                    
                    if self.products.isEmpty {
                        print("⚠️ Products array is empty after load")
                    } else {
                        print("✅ Loaded product ids: \(self.products.map { $0.id })")
                    }
                }
                
                return
            } catch {
                print("❌ Failed to load products on attempt \(attempt): \(error.localizedDescription)")
                
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        
        await MainActor.run {
            self.errorMessage = "Failed to load products."
            print("❌ All retries failed. Products not loaded.")
        }
    }
    
    private func syncCurrentProduct(for productID: String) {
        currentProduct = products.first { $0.id == productID }
        if currentProduct == nil {
            print("⚠️ Could not find currentProduct for id: \(productID)")
        }
    }
    
    private func syncCurrentProductFromStatus() {
        guard !products.isEmpty else {
            print("⚠️ Cannot sync currentProduct because products are empty")
            return
        }
        
        if let knownID = lastKnownProductID {
            currentProduct = products.first { $0.id == knownID }
            
            if currentProduct != nil {
                print("✅ Synced currentProduct from lastKnownProductID: \(knownID)")
            } else {
                print("⚠️ Could not sync currentProduct from lastKnownProductID: \(knownID)")
            }
            
            return
        }
        
        if let current = currentProduct?.id {
            currentProduct = products.first { $0.id == current }
            
            if currentProduct != nil {
                print("✅ Synced currentProduct from existing currentProduct id: \(current)")
            } else {
                print("⚠️ Could not sync currentProduct from existing id: \(current)")
            }
        }
    }
    
    private func getDeviceId() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}

enum StoreError: Error {
    case failedVerification
    case noActiveSubscription
}
