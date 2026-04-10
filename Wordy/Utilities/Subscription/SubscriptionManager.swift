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
    case expired(expiryDate: Date?)
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

    var isSubscriptionExpired: Bool {
        if case .expired = status { return true }
        return false
    }

    var canUseApp: Bool {
        status.canUseApp
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

        await checkFirebaseSubscription()

        if isPremium || isTrialActive {
            print("✅ Found active subscription in Firebase")
        }

        await loadProductsWithRetry()
        syncCurrentProductFromStatus()

        if !isPremium && !isTrialActive {
            print("📦 No active Firebase subscription, checking StoreKit...")
            await checkStoreKitEntitlements()

            if isPremium || isTrialActive {
                await syncCurrentSubscriptionToFirebase()
            }
        }

        if transactionListener == nil {
            transactionListener = listenForTransactions()
        }

        print("✅ SubscriptionManager.loadSubscriptionData() completed: \(status)")
    }

    func refreshStatus() async {
        await checkStoreKitEntitlements()
    }

    // MARK: - Firebase Methods

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

            let now = Date()
            if expiry > now {
                let isInGracePeriod = data["isInGracePeriod"] as? Bool ?? false

                status = .premium(expiryDate: expiry, isInGracePeriod: isInGracePeriod)
                currentProduct = products.first { $0.id == productId }
                trialEndDate = expiry

                print("✅ Found active Firebase subscription: \(productId), expires: \(expiry)")
            } else {
                print("⚠️ Firebase subscription expired on: \(expiry)")
                status = .expired(expiryDate: expiry)

                try? await db.collection("subscriptions").document(userId).updateData([
                    "isActive": false,
                    "updatedAt": Timestamp(date: Date())
                ])
            }

        } catch {
            print("❌ Error fetching Firebase subscription: \(error.localizedDescription)")
        }
    }

    private func syncCurrentSubscriptionToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard let userEmail = Auth.auth().currentUser?.email else { return }

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
                    "restoredAt": Timestamp(date: Date())
                ]

                try await db.collection("subscriptions").document(userId).setData(data, merge: true)
                print("🔄 Synced StoreKit subscription to Firebase")
                return

            } catch {
                continue
            }
        }
    }

    // MARK: - StoreKit Methods

    func purchase(product: Product) async -> Bool {
        print("🛒 SubscriptionManager.purchase() started for \(product.id)")

        do {
            let result = try await product.purchase()
            print("🛒 product.purchase() returned: \(result)")

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                print("🛒 Transaction verified: \(transaction.id)")

                await handleVerifiedTransaction(transaction)
                await saveSubscriptionToFirestore(product: product, transaction: transaction)
                await scheduleNotificationsIfNeeded(transaction)
                await transaction.finish()

                print("✅ Purchase fully completed")
                return true

            case .pending:
                print("⏳ Purchase pending")
                self.errorMessage = "Purchase pending approval from parent/guardian"
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
            self.errorMessage = "Purchase verification failed. Please try again."
            return false
        } catch {
            print("❌ Purchase error: \(error.localizedDescription)")
            self.errorMessage = "Purchase failed: \(error.localizedDescription)"
            return false
        }
    }

    func restorePurchases() async -> Bool {
        print("🔄 Restoring purchases...")

        do {
            try await AppStore.sync()

            await checkStoreKitEntitlements()

            if isPremium || isTrialActive {
                await syncCurrentSubscriptionToFirebase()
                syncCurrentProductFromStatus()
                return true
            }

            await checkFirebaseSubscription()
            syncCurrentProductFromStatus()

            return isPremium

        } catch {
            self.errorMessage = "Restore failed: \(error.localizedDescription)"
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

                if transaction.revocationDate != nil {
                    print("⚠️ Subscription revoked")
                    continue
                }

                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        await handleVerifiedTransaction(transaction)
                        foundActiveSubscription = true
                    } else {
                        lastExpiredTransaction = transaction
                        print("ℹ️ Found expired subscription: \(expirationDate)")
                    }
                } else {
                    await handleVerifiedTransaction(transaction)
                    foundActiveSubscription = true
                }

            } catch {
                print("⚠️ Failed to verify transaction: \(error)")
            }
        }

        if !foundActiveSubscription {
            if let expired = lastExpiredTransaction {
                self.status = .expired(expiryDate: expired.expirationDate)
                self.lastKnownProductID = expired.productID
                self.syncCurrentProductFromStatus()
                print("❌ Subscription expired on: \(expired.expirationDate ?? Date())")
            } else {
                self.status = .unknown
                self.currentProduct = nil
                print("ℹ️ No subscription history found")
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
                let maybeTrialDaysLeft = calculateTrialDaysLeft(
                    purchaseDate: transaction.purchaseDate,
                    expiryDate: expirationDate
                )

                if let daysLeft = maybeTrialDaysLeft {
                    status = .trial(daysLeft: daysLeft)
                    trialStartDate = transaction.purchaseDate
                    trialEndDate = expirationDate
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("✅ Active trial until: \(expirationDate), daysLeft: \(daysLeft)")
                } else {
                    status = .premium(expiryDate: expirationDate, isInGracePeriod: false)
                    trialEndDate = expirationDate
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("✅ Active premium subscription until: \(expirationDate)")
                }

            } else {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.day], from: expirationDate, to: now)
                let daysSinceExpiry = components.day ?? 0

                if daysSinceExpiry <= gracePeriodDays {
                    status = .billingRetry
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("⚠️ Billing retry / grace period")
                } else {
                    status = .expired(expiryDate: expirationDate)
                    currentProduct = products.first { $0.id == transaction.productID }
                    print("❌ Subscription expired")
                }
            }
        } else {
            status = .premium(expiryDate: nil, isInGracePeriod: false)
            syncCurrentProduct(for: transaction.productID)
            print("✅ Lifetime subscription")
        }
    }

    private func scheduleNotificationsIfNeeded(_ transaction: StoreKit.Transaction) async {
        guard let expirationDate = transaction.expirationDate else { return }

        guard isTrialTransaction(
            purchaseDate: transaction.purchaseDate,
            expiryDate: expirationDate
        ) else {
            print("ℹ️ Notifications are scheduled only for trial subscriptions")
            return
        }

        NotificationManager.shared.scheduleSubscriptionNotifications(
            purchaseDate: transaction.purchaseDate,
            expiryDate: expirationDate,
            originalTransactionId: transaction.originalID
        )
    }

    private func isTrialTransaction(purchaseDate: Date, expiryDate: Date) -> Bool {
        let interval = expiryDate.timeIntervalSince(purchaseDate)
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        let tolerance: TimeInterval = 10 * 60
        return abs(interval - threeDays) <= tolerance
    }

    private func calculateTrialDaysLeft(purchaseDate: Date, expiryDate: Date) -> Int? {
        guard isTrialTransaction(purchaseDate: purchaseDate, expiryDate: expiryDate) else {
            return nil
        }

        let now = Date()
        guard expiryDate > now else { return 0 }

        let secondsLeft = expiryDate.timeIntervalSince(now)
        let daysLeft = Int(ceil(secondsLeft / (24 * 60 * 60)))
        return max(daysLeft, 0)
    }

    // MARK: - Firestore

    private func saveSubscriptionToFirestore(product: Product, transaction: StoreKit.Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let userEmail = Auth.auth().currentUser?.email ?? ""
        let expirationDate = transaction.expirationDate ?? Date().addingTimeInterval(365 * 24 * 60 * 60)

        lastKnownProductID = product.id

        let data: [String: Any] = [
            "userId": userId,
            "email": userEmail,
            "productId": product.id,
            "expiryDate": Timestamp(date: expirationDate),
            "isActive": true,
            "purchaseDate": Timestamp(date: transaction.purchaseDate),
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

                self.products = result.sorted { $0.id.contains("year") && !$1.id.contains("year") }
                print("✅ Products loaded: \(self.products.count)")

                if self.products.isEmpty {
                    print("⚠️ Products array is empty after load")
                } else {
                    print("✅ Loaded product ids: \(self.products.map { $0.id })")
                }

                return
            } catch {
                print("❌ Failed to load products on attempt \(attempt): \(error.localizedDescription)")

                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }

        self.errorMessage = "Failed to load products."
        print("❌ All retries failed. Products not loaded.")
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
}

enum StoreError: Error {
    case failedVerification
    case noActiveSubscription
}
