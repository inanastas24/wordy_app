import Foundation
import FirebaseAnalytics

@MainActor
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    private var sessionStartedAt: Date?
    private var didTrackAppOpen = false
    private var trackedRenewalWindowDateKey: String?

    func trackAppOpen(isPremium: Bool, hasActiveTrial: Bool) {
        guard !didTrackAppOpen else { return }
        didTrackAppOpen = true

        track("app_open", [
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "ios",
            "is_premium": boolInt(isPremium),
            "has_active_trial": boolInt(hasActiveTrial)
        ])
    }

    func startSession(isPremium: Bool, daysToRenewal: Int?) {
        sessionStartedAt = Date()
        track("session_start", [
            "session_id": UUID().uuidString,
            "is_premium": boolInt(isPremium),
            "days_to_renewal": daysToRenewal ?? -1
        ])
    }

    func endSession() {
        let duration = max(0, Int(Date().timeIntervalSince(sessionStartedAt ?? Date())))
        track("session_end", [
            "session_id": UUID().uuidString,
            "duration_sec": duration
        ])
    }

    func trackSearchSubmitted(queryLength: Int, sourceLang: String, targetLang: String, inputMethod: String) {
        track("search_submitted", [
            "query_length": queryLength,
            "source_lang": sourceLang,
            "target_lang": targetLang,
            "input_method": inputMethod
        ])
    }

    func trackTranslationSuccess(sourceLang: String, targetLang: String, inputType: String, latencyMs: Int, hasMeanings: Bool, hasExamples: Bool, hasSynonyms: Bool, hasAntonyms: Bool) {
        track("translation_success", [
            "source_lang": sourceLang,
            "target_lang": targetLang,
            "input_type": inputType,
            "latency_ms": latencyMs,
            "has_meanings": boolInt(hasMeanings),
            "has_examples": boolInt(hasExamples),
            "has_synonyms": boolInt(hasSynonyms),
            "has_antonyms": boolInt(hasAntonyms)
        ])
    }

    func trackTranslationError(sourceLang: String, targetLang: String, errorType: String, statusCode: Int? = nil) {
        track("translation_error", [
            "source_lang": sourceLang,
            "target_lang": targetLang,
            "error_type": errorType,
            "status_code": statusCode ?? -1
        ])
    }

    func trackTranslationEmptyState(sourceLang: String, targetLang: String, reason: String) {
        track("translation_empty_state_shown", [
            "source_lang": sourceLang,
            "target_lang": targetLang,
            "reason": reason
        ])
    }

    func trackTabOpened(_ tabName: String) {
        track("tab_opened", ["tab_name": tabName])
    }

    func trackTTSClicked(section: String) {
        track("tts_clicked", ["section": section])
    }

    func trackCopyClicked(section: String) {
        track("copy_clicked", ["section": section])
    }

    func trackSaveClicked(entityType: String) {
        track("save_clicked", ["entity_type": entityType])
    }

    func trackSaveDictionaryPickerOpened(entityType: String, dictionariesCount: Int) {
        track("save_dictionary_picker_opened", [
            "entity_type": entityType,
            "dictionaries_count": dictionariesCount
        ])
    }

    func trackSaveDictionarySelected(entityType: String, dictionaryId: String, dictionaryName: String) {
        track("save_dictionary_selected", [
            "entity_type": entityType,
            "dictionary_id": dictionaryId,
            "dictionary_name": dictionaryName
        ])
    }

    func trackSaveSuccess(entityType: String, dictionaryId: String) {
        track("save_success", [
            "entity_type": entityType,
            "dictionary_id": dictionaryId
        ])
    }

    func trackSaveFailed(entityType: String, reason: String) {
        track("save_failed", [
            "entity_type": entityType,
            "reason": reason
        ])
    }

    func trackPaywallViewed(sourceScreen: String, placement: String) {
        track("paywall_viewed", [
            "source_screen": sourceScreen,
            "placement": placement,
            "experiment_id": "default"
        ])
    }

    func trackTrialStarted(planId: String, trialDays: Int) {
        track("trial_started", [
            "plan_id": planId,
            "trial_days": trialDays
        ])
    }

    func trackSubscriptionStarted(planId: String, period: String) {
        track("subscription_started", [
            "plan_id": planId,
            "period": period
        ])
    }

    func trackSubscriptionRenewal(planId: String) {
        track("subscription_renewal_detected", ["plan_id": planId])
    }

    func trackSubscriptionCancelled(planId: String, daysBeforeRenewal: Int?) {
        track("subscription_cancelled", [
            "plan_id": planId,
            "days_before_renewal": daysBeforeRenewal ?? -1
        ])
    }

    func trackSubscriptionPaymentFailed(planId: String, errorCode: String) {
        track("subscription_payment_failed", [
            "plan_id": planId,
            "error_code": errorCode
        ])
    }

    func trackRestoreClicked() { track("restore_purchase_clicked") }
    func trackRestoreSuccess() { track("restore_purchase_success") }
    func trackRestoreFailed() { track("restore_purchase_failed") }

    func trackRenewalWindowIfNeeded(planId: String, daysToRenewal: Int, currentStreakDays: Int, last7dSessions: Int, last7dTranslations: Int) {
        guard daysToRenewal == 3 else { return }
        let key = "\(planId)-\(todayKey())"
        guard trackedRenewalWindowDateKey != key else { return }
        trackedRenewalWindowDateKey = key

        track("renewal_window_entered", [
            "plan_id": planId,
            "is_auto_renew_on": 1,
            "current_streak_days": currentStreakDays,
            "last_7d_sessions": last7dSessions,
            "last_7d_translations": last7dTranslations
        ])
    }

    func trackRenewalReminderShown(channel: String, daysToRenewal: Int) {
        track("renewal_reminder_shown", ["channel": channel, "days_to_renewal": daysToRenewal])
    }

    func trackRenewalReminderClicked(channel: String) {
        track("renewal_reminder_clicked", ["channel": channel])
    }

    func trackManageSubscriptionOpened() {
        track("renewal_manage_subscription_opened")
    }

    func trackRenewalRetained(planId: String) {
        track("renewal_retained_after_3d_window", ["plan_id": planId])
    }

    func trackRenewalChurn(planId: String) {
        track("renewal_churn_after_3d_window", ["plan_id": planId])
    }

    func setUserProperties(isPremium: Bool, hasActiveTrial: Bool, sourceLang: String? = nil, targetLang: String? = nil) {
        Analytics.setUserProperty(isPremium ? "paid" : (hasActiveTrial ? "trial" : "free"), forName: "subscription_state")
        if let sourceLang, let targetLang {
            Analytics.setUserProperty("\(sourceLang)-\(targetLang)", forName: "language_pair")
        }
    }

    private func boolInt(_ value: Bool) -> Int { value ? 1 : 0 }

    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func track(_ name: String, _ parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
