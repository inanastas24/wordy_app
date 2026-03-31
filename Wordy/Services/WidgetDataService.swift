import Foundation
import WidgetKit

final class WidgetDataService {
    static let shared = WidgetDataService()

    private let suiteName = "group.com.inzercreator.wordyapp"
    private let storageKey = "widgetWords"
    private let rotationIndexKey = "widgetRotationIndex"

    struct WidgetWord: Codable, Equatable {
        let id: String
        let original: String
        let translation: String
        let transcription: String?
        let example: String?
        let languagePair: String
    }

    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func updateWidgetWords(words: [WidgetWord]) {
        guard let defaults = sharedDefaults else {
            print("❌ WidgetDataService: No shared defaults")
            return
        }

        do {
            let normalizedWords = Array(words.prefix(50))
            print("📥 WidgetDataService received: \(words.count), using: \(normalizedWords.count)")
            print("📥 Words: \(normalizedWords.map { $0.original })")
            
            let data = try JSONEncoder().encode(normalizedWords)
            
            let currentIndex = defaults.integer(forKey: rotationIndexKey)
            let nextIndex = normalizedWords.isEmpty ? 0 :
                           (currentIndex + 1) % max(normalizedWords.count, 1)
            
            defaults.set(data, forKey: storageKey)
            defaults.set(nextIndex, forKey: rotationIndexKey)

            print("✅ Saved to UserDefaults: \(normalizedWords.count) words")
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("❌ WidgetDataService encoding error: \(error)")
        }
    }

    func clearWidgetWords() {
        guard let defaults = sharedDefaults else { return }

        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: rotationIndexKey)

        print("✅ WidgetDataService: Дані віджета очищено")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func loadWidgetWords() -> [WidgetWord] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WidgetWord].self, from: data)
        } catch {
            print("❌ WidgetDataService: Помилка декодування: \(error)")
            return []
        }
    }

    func loadRotationIndex() -> Int {
        guard let defaults = sharedDefaults else { return 0 }
        return defaults.integer(forKey: rotationIndexKey)
    }
}
