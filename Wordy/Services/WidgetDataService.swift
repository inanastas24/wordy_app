import Foundation
import WidgetKit

final class WidgetDataService {
    static let shared = WidgetDataService()
    private let suiteName = "group.com.inzercreator.wordyapp"
    private let storageKey = "widgetWords"

    struct WidgetWordItem: Codable {
        let id: String
        let original: String
        let translation: String
        let transcription: String?
        let example: String?
        let languagePair: String
    }

    func updateWidgetWords(words: [WidgetWordItem]) {
        do {
            let data = try JSONEncoder().encode(words)

            guard let defaults = UserDefaults(suiteName: suiteName) else {
                print("❌ WidgetDataService: Не вдалося отримати UserDefaults для suite \(suiteName)")
                return
            }

            defaults.set(data, forKey: storageKey)
            defaults.synchronize()

            print("✅ WidgetDataService: Збережено \(words.count) слів у widget storage")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("❌ WidgetDataService: Помилка кодування: \(error)")
        }
    }

    func clearWidgetWords() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: storageKey)
        defaults.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
