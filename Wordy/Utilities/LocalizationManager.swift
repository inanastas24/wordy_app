//1
//  LocalizationManager.swift
//  Wordy
//
//  Created by Anastasiia Inzer on 28.01.2026.
//

import SwiftUI
import Combine
import WidgetKit

enum Language: String, CaseIterable, Identifiable {
    case ukrainian = "uk"
    case english = "en"
    case polish = "pl"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ukrainian: return "Українська"
        case .english: return "English"
        case .polish: return "Polski"
        }
    }
    
    var flag: String {
        switch self {
        case .ukrainian: return "🇺🇦"
        case .english: return "🇬🇧"
        case .polish: return "🇵🇱"
        }
    }
}

enum LocalizableKey: String {
    // Основні
    case appName, search, dictionary, profile, settings
    case searchPlaceholder, myDictionary, learning, learned, totalWords
    case darkTheme, appLanguage, notifications
    case selectAppLanguage, `continue`, error, success, backup
    case recent, clear, enterWord, scan, scanText, voice, holdToSpeak
    case selectLearningLanguage, canChangeLater, startLearning
    case allLearned, noWordsForReview, learnNewWords, backToDictionary
    case again, hard, medium, good, perfect, howWellKnown
    case showAnswer, tapToFlip
    case tapOrSwipe
    case supportChat
    
    // Settings
    case shareWordy, exportDictionary, importDictionary, rateInAppStore
    case enterAccount, login, register, createAccount, alreadyHaveAccount
    case selectAvatar, changeName, yourName, saveChanges
    case signOut, logOut
    
    // Flashcards & Reviewing
    case averageQuality, nextReview, cardsWaiting
    
    // Auth
    case welcomeBack, signInToContinue, forgotPassword, resetPassword, signIn
    case password, confirmPassword, invalidEmail, weakPassword
    case accountCreated, checkEmail
    case user
    
    // Profile & Stats
    case streakDays, record, achievements, yourProgress
    case editProfile, changePhoto, deletePhoto
    
    // SRS
    case reviewing, learnedToday, againCount
    case save
    
    // Appearance - НОВІ
    case lightMode, darkMode, appearance  // <-- ДОДАНО appearance
    
    // Statistics
    case statistics, wordsLearned, minutesSpent, accuracy, progress
    case dailyGoal, weeklyProgress, monthlyProgress
    
    // Time
    case today, yesterday, thisWeek, thisMonth, allTime
    
    // Guest mode & Account
    case guestMode, saveProgress, tapToSave, progressSaved

    // Achievements
    case firstWord, tenWords, sevenDays, hundredWords

    // Rate App Popup
    case enjoyingApp, rateUs, notNow, never

    // Permissions
    case cameraPermission, microphonePermission, speechPermission, trackingPermission
    case permissionRequired, permissionMessage, openSettings
    case recentActivity, cancel
    
    // New keys
    case saveProgressDescription
    case emailPassword
    case continueWithoutRegistration
    case wordsMayBeLost
    case enterDetailsForRegistration
    case enterEmailAndPassword
    case noAccountCreate
    case enterYourEmail
    case sendResetLink
    case learnWordsEasily
    
    // Telegram
    case messageLimitTitle
    case messageLimitMessage
    case sendingStart
    case authError
    case authenticated
    case notAuthenticated
    case messageSent

    case tapWordToTranslate

    // PermissionType
    case permissionCameraTitle
    case permissionCameraMessage
    case permissionMicrophoneTitle
    case permissionMicrophoneMessage
    case permissionSpeechTitle
    case permissionSpeechMessage
    case permissionTrackingTitle
    case permissionTrackingMessage
    case permissionAllow
    case permissionDeny
    case permissionSettings
    case freeTrial, daysLeft, upgrade
    case termsOfService
    case privacyPolicy
    case upgradeToPremium, trialExplanation, noPaymentNow, trialWelcomeTitle, trialWelcomeBody, trialReminderBody, trialEndedBody, subscriptionConfirmed, subscription
    
    // MARK: - Subscription Keys
    case subscriptionExpired
    case subscriptionActive
    case renewSubscription
    case noSubscription
    case subscriptionStatus
    case manageSubscription
    case restorePurchases
    case permissionNotificationTitle, permissionNotificationMessage
    
    case try3DaysFree, trialAppliesToBoth, feature1, feature2, feature3, feature4, feature5, feature6
    case startFreeTrial, howTrialWorks
    case trialPriceInfo
    case byContinuing
    case selectLanguageToSpeak
    case listeningIn
    case recognitionError
    case tapToCapture, tapWordToTranslateText, retakeText, doneText, startingCameraText, cameraNotFoundText, closeText
    
    // MARK: - Language Pair Selection (NEW)
    case selectLanguagesForTranslation
    case translationWorksBothWays
    case tapFlagToChangeLanguage
    case searchInLanguage
    case translatesTo
    case language1
    case language2
    case popularLanguages
    case otherLanguages
    
    case originalWord, enterTranslation, transcription, optional, example, enterExample, preview, translationVariant, loading, backTitle, statusLearned, deleteButton
    case wordAdded, wordUpdated, wordAddedMessage, wordUpdatedMessage, addAnother, done
    case selectLanguagePair, sourceLanguage, targetLanguage, changesSaved, unknownError
    case languagePair, translation, permissionPermissionNotificationTitle
    
    case wordSets
    case wordSetsSubtitle
    case sets // для таб-бару
    case words, saved, saving
    case wordsInCategory

    // MARK: - Category Keys
    case categoryBasics
    case categoryTravel
    case categoryFood
    case categoryWork
    case categoryEmotions
    case categoryFamily
    case categoryShopping
    case categoryHealth
    case categoryTechnology
    case categoryNature
    case categoryEducation
    case categoryBusiness
    case categoryHobbies
    case categorySocial
    case categoryHome
    case categoryVerbs
    case categoryIrregularVerbs
    case filterBy
    case verbForms
    case wordAlreadyExists
    case wordAlreadyInDictionary
    case ok
    case searchSets
    case searchInSet
    case addAll
    case addAllWords
    case addAllWordsMessage
    case sortBy
    case addedToDictionary
    case addToDictionary
    case synonyms
    case generatingWords
    case aiGenerating
    case regenerate
    case useLocal
    case aiError
    
    // Filters
    case filterAll
    case filterBeginner
    case filterIntermediate
    case filterAdvanced
    case filterPremium
    case filterFree
    
    // Sort
    case sortOriginal
    case sortTranslation
    case sortAlphabetical
    
    // Tips
    case tipLearning
    case tipExamples
    case tipRepetition
    case tipContext
    
    // Word Set Titles (AI-generated categories)
    case wordsetBasicWords
    case wordsetVerbs
    case wordsetNouns
    case wordsetAdjectives
    case wordsetTravel
    case wordsetFood
    case wordsetWork
    case wordsetHobbies
    case wordsetEmotions
    case wordsetFamily
    case wordsetTime
    case wordsetShopping
    case wordsetHealth
    case wordsetTechnology
    case wordsetNature
    case wordsetEducation
    case wordsetBusiness
    case wordsetScience
    case wordsetArt
    case wordsetSports
    case wordsetCulture
    
    case createCustomSet
    case createYourOwnSet
    case aiWillGenerate
    case setTitle
    case titlePlaceholder
    case whatTopic
    case describeTopic
    case difficultyLevel
    case wordCount
    case focusAreas
    case advancedOptions
    case customPrompt
    case promptTips
    case generateSet
    case generating
    case createSet
    case pleaseLogin
    case howIsThisTranslation
    case howCanBeBetter
    case submitRating
    case thankYou
    case feedbackReceived
    case exchangeSets
    case export
    case importTitle
    case community
    case selectSetToExport
    case importFromFile
    case importJSONDescription
    case scanQRCode
    case scanQRDescription
    case pasteFromClipboard
    case pasteJSONDescription
    case popular
    case recentWord
    case trending
    case following
    case invalidFileFormat
    case unsupportedFormat, tipSpecific, tipLevel
    case seeAll
    
    case textTooLong
    case voiceInputTooLong
    case warning
    case audioPermissionMessage
}

public class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language
    @Published var isDarkMode: Bool
    
    init() {
        let systemLang = Locale.current.language.languageCode?.identifier
        let initialLanguage: Language
        
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = Language(rawValue: saved) {
            initialLanguage = lang
        } else {
            if systemLang == "uk" {
                initialLanguage = .ukrainian
            } else if systemLang == "pl" {
                initialLanguage = .polish
            } else {
                initialLanguage = .english
            }
            UserDefaults.standard.set(initialLanguage.rawValue, forKey: "appLanguage")
        }
        
        self.currentLanguage = initialLanguage
        
        // 🆕 Світла тема за замовчуванням, темна тільки якщо явно встановлено
        if UserDefaults.standard.object(forKey: "isDarkMode") == nil {
            // Перший запуск - світла тема
            self.isDarkMode = false
            UserDefaults.standard.set(false, forKey: "isDarkMode")
        } else {
            self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        }
        
        applyAppearance()
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
   
    // Метод toggleDarkMode:

    func toggleDarkMode(_ value: Bool) {
        isDarkMode = value
        UserDefaults.standard.set(value, forKey: "isDarkMode")
        applyAppearance()
        
        // Оновлюємо віджет при зміні теми
        WidgetCenter.shared.reloadAllTimelines()
        print("🎨 Theme changed to \(value ? "dark" : "light"), widget reloaded")
    }
    
    private func applyAppearance() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.forEach { window in
                    window.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
                }
            }
        }
    }
    
    func string(_ key: LocalizableKey) -> String {
        translations[key]?[currentLanguage] ?? key.rawValue
    }
    
    // Допоміжний метод для теми
    func currentThemeName() -> String {
        return isDarkMode ? string(.darkMode) : string(.lightMode)
    }
    
    private let translations: [LocalizableKey: [Language: String]] = [
        .appName: [.ukrainian: "Wordy", .english: "Wordy", .polish: "Wordy"],
        .search: [.ukrainian: "Пошук", .english: "Search", .polish: "Szukaj"],
        .dictionary: [.ukrainian: "Словник", .english: "Dictionary", .polish: "Słownik"],
        .profile: [.ukrainian: "Прогрес", .english: "Progress", .polish: "Postęp"],
        .settings: [.ukrainian: "Налаштування", .english: "Settings", .polish: "Ustawienia"],
        
        .searchPlaceholder: [.ukrainian: "Введіть слово...", .english: "Enter word...", .polish: "Wpisz słowo..."],
        .enterWord: [.ukrainian: "Введіть слово...", .english: "Enter word...", .polish: "Wpisz słowo..."],
        
        .myDictionary: [.ukrainian: "Мій словник", .english: "My Dictionary", .polish: "Mój słownik"],
        .learning: [.ukrainian: "На вивченні", .english: "Learning", .polish: "Do nauki"],
        .learned: [.ukrainian: "Вивчено", .english: "Learned", .polish: "Nauczone"],
        // .delete: [.ukrainian: "Видалити", .english: "Delete", .polish: "Usunąć"],
        .totalWords: [.ukrainian: "Всього слів", .english: "Total words", .polish: "Wszystkie słowa"],
        .darkTheme: [.ukrainian: "Темна тема", .english: "Dark Theme", .polish: "Ciemny motyw"],
        .appLanguage: [.ukrainian: "Мова додатку", .english: "App Language", .polish: "Język aplikacji"],
        .notifications: [.ukrainian: "Нагадування", .english: "Reminders", .polish: "Przypomnienia"],
        
        .selectAppLanguage: [.ukrainian: "Оберіть мову", .english: "Select language", .polish: "Wybierz język"],
        .continue: [.ukrainian: "Продовжити", .english: "Continue", .polish: "Kontynuuj"],
        
        .error: [.ukrainian: "Помилка", .english: "Error", .polish: "Błąd"],
        .success: [.ukrainian: "Успіх", .english: "Success", .polish: "Sukces"],
        .backup: [.ukrainian: "Резервне копіювання", .english: "Backup", .polish: "Kopia zapasowa"],
        
        .recent: [.ukrainian: "Нещодавно", .english: "Recent", .polish: "Ostatnio"],
        .clear: [.ukrainian: "Очистити", .english: "Clear", .polish: "Wyczyść"],
        
        .scan: [.ukrainian: "Сканувати", .english: "Scan", .polish: "Skanuj"],
        .scanText: [.ukrainian: "текст", .english: "text", .polish: "tekst"],
        
        .voice: [.ukrainian: "Голосом", .english: "Voice", .polish: "Głosem"],
        .holdToSpeak: [.ukrainian: "тримайте", .english: "hold to speak", .polish: "przytrzymaj"],
        
        .selectLearningLanguage: [.ukrainian: "Яку мову хочете вивчати?", .english: "Which language do you want to learn?", .polish: "Którego języka chcesz się nauczyć?"],
        .canChangeLater: [.ukrainian: "Можна змінити пізніше в налаштуваннях", .english: "Can be changed later in settings", .polish: "Można zmienić później w ustawieniach"],
        .startLearning: [.ukrainian: "Почати навчання", .english: "Start learning", .polish: "Zacznij naukę"],
        
        // SRS / Flashcards
        .allLearned: [.ukrainian: "Все вивчено!", .english: "All learned!", .polish: "Wszystko nauczone!"],
        .noWordsForReview: [.ukrainian: "Немає слів для повторення на сьогодні. Додайте нові слова або відпочиньте!", .english: "No words to review today. Add new words or take a break!", .polish: "Brak słów do powtórki na dziś. Dodaj nowe słowa lub odpocznij!"],
        .learnNewWords: [.ukrainian: "Вчити нові слова", .english: "Learn new words", .polish: "Ucz się nowych słów"],
        .backToDictionary: [.ukrainian: "Повернутися до словника", .english: "Back to dictionary", .polish: "Wróć do słownika"],
        
        .again: [.ukrainian: "Знову", .english: "Again", .polish: "Od nowa"],
        .hard: [.ukrainian: "Важко", .english: "Hard", .polish: "Trudne"],
        .medium: [.ukrainian: "Середньо", .english: "Medium", .polish: "Średnio"],
        .good: [.ukrainian: "Добре", .english: "Good", .polish: "Dobrze"],
        .perfect: [.ukrainian: "Ідеально", .english: "Perfect", .polish: "Idealnie"],
        .howWellKnown: [.ukrainian: "Наскільки добре ви знали це слово?", .english: "How well did you know this word?", .polish: "Jak dobrze znałeś to słowo?"],
        
        .showAnswer: [.ukrainian: "Показати відповідь", .english: "Show answer", .polish: "Pokaż odpowiedź"],
        .tapOrSwipe: [.ukrainian: "Тапніть по картці або свайпніть", .english: "Tap card or swipe", .polish: "Dotknij karty lub przesuń"],
        
        // Profile
        .streakDays: [.ukrainian: "Днів поспіль", .english: "Days streak", .polish: "Dni z rzędu"],
        .record: [.ukrainian: "Рекорд", .english: "Record", .polish: "Rekord"],
        .achievements: [.ukrainian: "Досягнення", .english: "Achievements", .polish: "Osiągnięcia"],
        .yourProgress: [.ukrainian: "Ваш прогрес", .english: "Your progress", .polish: "Twój postęp"],
        
        .editProfile: [.ukrainian: "Редагувати профіль", .english: "Edit profile", .polish: "Edytuj profil"],
        .changePhoto: [.ukrainian: "Змінити фото", .english: "Change photo", .polish: "Zmień zdjęcie"],
        .deletePhoto: [.ukrainian: "Видалити фото", .english: "Delete photo", .polish: "Usuń zdjęcie"],
        
        .reviewing: [.ukrainian: "Повторення", .english: "Reviewing", .polish: "Powtórka"],
        .tapToFlip: [.ukrainian: "Тапніть, щоб перевернути", .english: "Tap to flip", .polish: "Dotknij, aby odwrócić"],
        .save: [.ukrainian: "Зберегти", .english: "Save", .polish: "Zapisz"],
        
        // Settings
        .shareWordy: [
            .ukrainian: "Поділитися Wordy",
            .english: "Share Wordy",
            .polish: "Udostępnij Wordy"
        ],
        .supportChat: [
            .ukrainian: "Напиши Wordy ✍️",
            .english: "Message Wordy ✍️",
            .polish: "Napisz do Wordy ✍️"
        ],
        .exportDictionary: [
            .ukrainian: "Експорт словника",
            .english: "Export dictionary",
            .polish: "Eksport słownika"
        ],
        .importDictionary: [
            .ukrainian: "Імпорт словника",
            .english: "Import dictionary",
            .polish: "Import słownika"
        ],
        .rateInAppStore: [
            .ukrainian: "Оцінити в App Store",
            .english: "Rate in App Store",
            .polish: "Oceń w App Store"
        ],
        .signOut: [
            .ukrainian: "Вийти",
            .english: "Log out",
            .polish: "Wyloguj się"
        ],
        
        // Auth
        .enterAccount: [
            .ukrainian: "Увійдіть у свій обліковий запис",
            .english: "Sign in to your account",
            .polish: "Zaloguj się na swoje konto"
        ],
        .login: [
            .ukrainian: "Вийти",
            .english: "Log out",
            .polish: "Zaloguj się"
        ],
        .logOut:[
            .ukrainian: "Вийти",
            .english: "Log out",
            .polish: "Wyloguj"
        ],
        .register: [
            .ukrainian: "Зареєструватися",
            .english: "Sign Up",
            .polish: "Zarejestruj się"
        ],
        .createAccount: [
            .ukrainian: "Створити акаунт",
            .english: "Create account",
            .polish: "Utwórz konto"
        ],
        .alreadyHaveAccount: [
            .ukrainian: "Вже є акаунт? Увійти",
            .english: "Already have an account? Sign In",
            .polish: "Masz już konto? Zaloguj się"
        ],
        .signIn: [
            .ukrainian: "Увійти",
            .english: "Sign in",
            .polish: "Zaloguj"
        ],
        .forgotPassword: [
            .ukrainian: "Забули пароль?",
            .english: "Forgot password?",
            .polish: "Zapomniałeś hasła?"
        ],
        .password: [
            .ukrainian: "Пароль",
            .english: "Password",
            .polish: "Hasło"
        ],
        .confirmPassword: [
            .ukrainian: "Підтвердіть пароль",
            .english: "Confirm password",
            .polish: "Potwierdź hasło"
        ],
        
        // Profile/Avatar
        .user: [
            .ukrainian: "Користувач",
            .english: "User",
            .polish: "Użytkownik"
        ],
        .selectAvatar: [
            .ukrainian: "Обрати аватар",
            .english: "Select avatar",
            .polish: "Wybierz awatar"
        ],
        .changeName: [
            .ukrainian: "Змінити ім'я",
            .english: "Change name",
            .polish: "Zmień imię"
        ],
        .yourName: [
            .ukrainian: "Ваше ім'я",
            .english: "Your name",
            .polish: "Twoje imię"
        ],
        .saveChanges: [
            .ukrainian: "Зберегти зміни",
            .english: "Save changes",
            .polish: "Zapisz zmiany"
        ],
        
        // Flashcards/Reviewing
        .averageQuality: [
            .ukrainian: "Середня якість",
            .english: "Average quality",
            .polish: "Średnia jakość"
        ],
        .nextReview: [
            .ukrainian: "Наступне повторення",
            .english: "Next review",
            .polish: "Następna powtórka"
        ],
        .cardsWaiting: [
            .ukrainian: "карток чекає",
            .english: "cards waiting",
            .polish: "kart czeka"
        ],
        
        // Appearance - НОВІ (додано appearance)
        .lightMode: [
            .ukrainian: "Світлий режим",
            .english: "Light Mode",
            .polish: "Tryb jasny"
        ],
        .darkMode: [
            .ukrainian: "Темний режим",
            .english: "Dark Mode",
            .polish: "Tryb ciemny"
        ],
        .appearance: [  // <-- ДОДАНО
            .ukrainian: "Зовнішній вигляд",
            .english: "Appearance",
            .polish: "Wygląd"
        ],
        
        // Statistics - НОВІ
        .statistics: [
            .ukrainian: "Статистика",
            .english: "Statistics",
            .polish: "Statystyki"
        ],
        .wordsLearned: [
            .ukrainian: "Вивчено слів",
            .english: "Words learned",
            .polish: "Nauczone słowa"
        ],
        .minutesSpent: [
            .ukrainian: "Хвилин витрачено",
            .english: "Minutes spent",
            .polish: "Minut spędzonych"
        ],
        .accuracy: [
            .ukrainian: "Точність",
            .english: "Accuracy",
            .polish: "Dokładność"
        ],
        .progress: [
            .ukrainian: "Прогрес",
            .english: "Progress",
            .polish: "Postęp"
        ],
        .dailyGoal: [
            .ukrainian: "Денна ціль",
            .english: "Daily goal",
            .polish: "Cel dzienny"
        ],
        .weeklyProgress: [
            .ukrainian: "Тижневий прогрес",
            .english: "Weekly progress",
            .polish: "Postęp tygodniowy"
        ],
        .monthlyProgress: [
            .ukrainian: "Місячний прогрес",
            .english: "Monthly progress",
            .polish: "Postęp miesięczny"
        ],
        
        // Time - НОВІ
        .today: [
            .ukrainian: "Сьогодні",
            .english: "Today",
            .polish: "Dziś"
        ],
        .yesterday: [
            .ukrainian: "Вчора",
            .english: "Yesterday",
            .polish: "Wczoraj"
        ],
        .thisWeek: [
            .ukrainian: "Цього тижня",
            .english: "This week",
            .polish: "W tym tygodniu"
        ],
        .thisMonth: [
            .ukrainian: "Цього місяця",
            .english: "This month",
            .polish: "W tym miesiącu"
        ],
        .allTime: [
            .ukrainian: "За весь час",
            .english: "All time",
            .polish: "Od zawsze"
        ],
        // Guest mode & Account
        .guestMode: [
            .ukrainian: "Гостьовий режим",
            .english: "Guest Mode",
            .polish: "Tryb gościa"
        ],
        .saveProgress: [
            .ukrainian: "Збережіть свій прогрес",
            .english: "Save your progress",
            .polish: "Zapisz swój postęp"
        ],
        .tapToSave: [
            .ukrainian: "Натисніть, щоб зберегти прогрес",
            .english: "Tap to save your progress",
            .polish: "Dotknij, aby zapisać postęp"
        ],
        .progressSaved: [
            .ukrainian: "Прогрес збережено",
            .english: "Progress saved",
            .polish: "Postęp zapisany"
        ],

        // Achievements
        .firstWord: [
            .ukrainian: "Перше слово",
            .english: "First word",
            .polish: "Pierwsze słowo"
        ],
        .tenWords: [
            .ukrainian: "10 слів",
            .english: "10 words",
            .polish: "10 słów"
        ],
        .sevenDays: [
            .ukrainian: "7 днів",
            .english: "7 days",
            .polish: "7 dni"
        ],
        .hundredWords: [
            .ukrainian: "100 слів",
            .english: "100 words",
            .polish: "100 słów"
        ],

        // Rate App Popup
        .enjoyingApp: [
            .ukrainian: "Подobaється додаток?",
            .english: "Enjoying the app?",
            .polish: "Podoba Ci się aplikacja?"
        ],
        .rateUs: [
            .ukrainian: "Оцініть нас в App Store",
            .english: "Rate us on the App Store",
            .polish: "Oceń nas w App Store"
        ],
        .notNow: [
            .ukrainian: "Не зараз",
            .english: "Not now",
            .polish: "Nie teraz"
        ],
        .never: [
            .ukrainian: "Ніколи",
            .english: "Never",
            .polish: "Nigdy"
        ],

        // Permissions
        .cameraPermission: [
            .ukrainian: "Доступ до камери",
            .english: "Camera Access",
            .polish: "Dostęp do kamery"
        ],
        .microphonePermission: [
            .ukrainian: "Доступ до мікрофона",
            .english: "Microphone Access",
            .polish: "Dostęp do mikrofonu"
        ],
        .speechPermission: [
            .ukrainian: "Розпізнавання мови",
            .english: "Speech Recognition",
            .polish: "Rozpoznawanie mowy"
        ],
        .permissionRequired: [
            .ukrainian: "Потрібен дозвіл",
            .english: "Permission Required",
            .polish: "Wymagane uprawnienie"
        ],
        .permissionMessage: [
            .ukrainian: "Ця функція потребує доступу. Будь ласка, надайте дозвіл в налаштуваннях.",
            .english: "This feature requires access. Please grant permission in settings.",
            .polish: "Ta funkcja wymaga dostępu. Proszę udzielić uprawnienia w ustawieniach."
        ],
        .openSettings: [
            .ukrainian: "Відкрити налаштування",
            .english: "Open Settings",
            .polish: "Otwórz ustawienia"
        ],
        .recentActivity: [
            .ukrainian: "Остання активність",
            .english: "Recent activity",
            .polish: "Ostatnia aktywność"
        ],
        .cancel: [
            .ukrainian: "Скасувати",
            .english: "Cancel",
            .polish: "Anuluj"
        ],
        .saveProgressDescription: [
            .ukrainian: "Увійдіть або зареєструйтесь, щоб зберегти ваші слова в хмарі",
            .english: "Sign in or register to save your words to the cloud",
            .polish: "Zaloguj się lub zarejestruj, aby zapisać słowa w chmurze"
        ],
        .emailPassword: [
            .ukrainian: "Email та пароль",
            .english: "Email & Password",
            .polish: "Email i hasło"
        ],
        .continueWithoutRegistration: [
            .ukrainian: "Продовжити без реєстрації",
            .english: "Continue without registration",
            .polish: "Kontynuuj bez rejestracji"
        ],
        .wordsMayBeLost: [
            .ukrainian: "Ваші слова можуть загубитися",
            .english: "Your words may be lost",
            .polish: "Twoje słowa mogą zginąć"
        ],
        .enterDetailsForRegistration: [
            .ukrainian: "Введіть дані для реєстрації",
            .english: "Enter details for registration",
            .polish: "Wprowadź dane do rejestracji"
        ],
        .enterEmailAndPassword: [
            .ukrainian: "Введіть email та пароль",
            .english: "Enter email and password",
            .polish: "Wprowadź email i hasło"
        ],
        .noAccountCreate: [
            .ukrainian: "Ще не зареєстровані? Створіть акаунт",
            .english: "Not registered yet? Create account",
            .polish: "Nie masz konta? Utwórz je"
        ],
        .enterYourEmail: [
            .ukrainian: "Введіть ваш email",
            .english: "Enter your email",
            .polish: "Wprowadź swój email"
        ],
        .sendResetLink: [
            .ukrainian: "Надіслати посилання",
            .english: "Send link",
            .polish: "Wyślij link"
        ],
        .resetPassword: [
            .ukrainian: "Скидання пароля",
            .english: "Reset password",
            .polish: "Resetowanie hasła"
        ],
        .learnWordsEasily: [
            .ukrainian: "Вивчайте слова легко",
            .english: "Learn words easily",
            .polish: "Ucz się słów łatwo"
        ],
        // Ліміт повідомлень
        .messageLimitTitle: [
            .ukrainian: "Ліміт повідомлень вичерпано",
            .english: "Daily limit reached",
            .polish: "Dzienny limit wyczerpany"
        ],
        .messageLimitMessage: [
            .ukrainian: "Можна відправляти не більше 10 повідомлень на добу. Спробуйте завтра.",
            .english: "You can send up to 10 messages per day. Try again tomorrow.",
            .polish: "Możesz wysłać do 10 wiadomości dziennie. Spróbuj jutro."
        ],
        // Статуси відправки
        .sendingStart: [
            .ukrainian: "Початок відправки...",
            .english: "Sending...",
            .polish: "Wysyłanie..."
        ],
        .authError: [
            .ukrainian: "❌ Не авторизовано",
            .english: "❌ Not authenticated",
            .polish: "❌ Nie uwierzytelniono"
        ],
        .authenticated: [
            .ukrainian: "Авторизовано",
            .english: "Authenticated",
            .polish: "Uwierzytelniono"
        ],
        .notAuthenticated: [
            .ukrainian: "Користувач не авторизований",
            .english: "User not authenticated",
            .polish: "Użytkownik nieuwierzytelniony"
        ],
        .messageSent: [
            .ukrainian: "Повідомлення відправлено",
            .english: "Message sent",
            .polish: "Wiadomość wysłana"
        ],
        .permissionCameraTitle: [
            .ukrainian: "Доступ до камери",
            .english: "Camera Access",
            .polish: "Dostęp do kamery"
        ],
        .permissionCameraMessage: [
            .ukrainian: "Wordy використовує камеру для сканування тексту з книг та документів",
            .english: "Wordy uses camera to scan text from books and documents",
            .polish: "Wordy używa kamery do skanowania tekstu z książek i dokumentów"
        ],

        .permissionMicrophoneTitle: [
            .ukrainian: "Доступ до мікрофона",
            .english: "Microphone Access",
            .polish: "Dostęp do mikrofonu"
        ],
        .permissionMicrophoneMessage: [
            .ukrainian: "Потрібен для голосового пошуку слів",
            .english: "Needed for voice search of words",
            .polish: "Potrzebny do wyszukiwania głosowego słów"
        ],

        .permissionSpeechTitle: [
            .ukrainian: "Розпізнавання мови",
            .english: "Speech Recognition",
            .polish: "Rozpoznawanie mowy"
        ],
        .permissionSpeechMessage: [
            .ukrainian: "Дозволяє перетворювати вашу мову на текст",
            .english: "Allows converting your speech to text",
            .polish: "Pozwala na zamianę mowy na tekst"
        ],
        .permissionAllow: [
            .ukrainian: "Дозволити",
            .english: "Allow",
            .polish: "Zezwól"
        ],
        .permissionDeny: [
            .ukrainian: "Відхилити",
            .english: "Deny",
            .polish: "Odmów"
        ],
        .permissionSettings: [
            .ukrainian: "Відкрити налаштування",
            .english: "Open Settings",
            .polish: "Otwórz ustawienia"
        ],
        .tapWordToTranslate: [
            .ukrainian: "Тапніть слово для перекладу",
            .english: "Tap word to translate",
            .polish: "Dotknij słowo, aby przetłumaczyć"
        ],
        .freeTrial: [
            .ukrainian: "Безкоштовний період",
            .english: "Free Trial",
            .polish: "Darmowy okres próbny"
        ],
        .daysLeft: [
            .ukrainian: "Залишилось %d днів",
            .english: "%d days left",
            .polish: "Pozostało %d dni"
        ],
        .upgrade: [
            .ukrainian: "Оновити",
            .english: "Upgrade",
            .polish: "Ulepsz"
        ],
        .welcomeBack: [
            .ukrainian: "Ласкаво просимо!",
            .english: "Welcome back!",
            .polish: "Witaj ponownie!"
        ],
        .signInToContinue: [
            .ukrainian: "Збережіть свій прогрес та вивчайте мови ефективно",
            .english: "Save your progress and learn languages effectively",
            .polish: "Zapisz swój postęp i ucz się języków efektywnie"
        ],
        .termsOfService: [
            .ukrainian: "Умови використання",
            .english: "Terms of Service",
            .polish: "Warunki użytkowania"
        ],
        .privacyPolicy: [
            .ukrainian: "Політика конфіденційності",
            .english: "Privacy Policy",
            .polish: "Polityka prywatności"
        ],
        .upgradeToPremium: [
            .ukrainian: "Premium",
            .english: "Premium",
            .polish: "Premium"
        ],
        .trialExplanation: [
            .ukrainian: "3 дні безкоштовно, потім підписка активується автоматично. Скасувати можна будь-коли.",
            .english: "3 days free, then subscription activates automatically. Cancel anytime.",
            .polish: "3 dni za darmo, potem subskrypcja aktywuje się automatycznie. Anuluj w dowolnym momencie."
        ],
        .trialWelcomeTitle: [
            .ukrainian: "🎉 Пробний період активовано!",
            .english: "🎉 Trial period activated!",
            .polish: "🎉 Okres próbny aktywowany!"
        ],
        .trialWelcomeBody: [
            .ukrainian: "У вас є 3 дні безкоштовного користування. Насолоджуйтесь!",
            .english: "You have 3 days of free usage. Enjoy!",
            .polish: "Masz 3 dni bezpłatnego użytkowania. Korzystaj!"
        ],
        .trialReminderBody: [
            .ukrainian: "Залишився 1 день. Підписка почнеться автоматично завтра. Можна скасувати в налаштуваннях.",
            .english: "1 day left. Subscription starts automatically tomorrow. Cancel in settings.",
            .polish: "Pozostał 1 dzień. Subskrypcja rozpocznie się automatycznie jutro. Anuluj w ustawieniach."
        ],
        .trialEndedBody: [
            .ukrainian: "Ваша підписка активована! Дякуємо. Можна скасувати будь-коли.",
            .english: "Your subscription is active! Thank you. Cancel anytime.",
            .polish: "Twoja subskrypcja jest aktywna! Dziękujemy. Anuluj w dowolnym momencie."
        ],
        .subscription: [
            .ukrainian: "Підписка",
            .english: "Subscription",
            .polish: "Subskrypcja"
        ],
        .subscriptionConfirmed: [
            .ukrainian: "✅ Підписку оформлено",
            .english: "✅ Subscribed successfully",
            .polish: "✅ Subskrypcja aktywowana"
        ],
        .subscriptionExpired: [
            .ukrainian: "Підписка закінчилась",
            .english: "Subscription Expired",
            .polish: "Subskrypcja wygasła"
        ],
        .subscriptionActive: [
            .ukrainian: "Підписка активна",
            .english: "Subscription Active",
            .polish: "Subskrypcja aktywna"
        ],
        .trialPriceInfo: [
            .ukrainian: "3 дні безкоштовно, потім обраний тариф",
            .english: "3 days free, then selected plan",
            .polish: "3 dni za darmo, potem wybrany plan"
        ],
        .renewSubscription: [
            .ukrainian: "Поновити підписку",
            .english: "Renew Subscription",
            .polish: "Odnów subskrypcję"
        ],
        .noSubscription: [
            .ukrainian: "Немає підписки",
            .english: "No Subscription",
            .polish: "Brak subskrypcji"
        ],
        .subscriptionStatus: [
            .ukrainian: "Статус підписки",
            .english: "Subscription Status",
            .polish: "Status subskrypcji"
        ],
        .manageSubscription: [
            .ukrainian: "Керувати підпискою",
            .english: "Manage Subscription",
            .polish: "Zarządzaj subskrypcją"
        ],
        .restorePurchases: [
            .ukrainian: "Відновити покупки",
            .english: "Restore Purchases",
            .polish: "Przywróć zakupy"
        ],
        .permissionNotificationTitle: [
            .ukrainian: "Дозвіл на сповіщення",
            .english: "Notification Permission",
            .polish: "Zezwolenie na powiadomienia"
        ],
        .permissionNotificationMessage: [
            .ukrainian: "Додаток надсилатиме нагадування про навчання та повторення слів",
            .english: "The app will send reminders for learning and word reviews",
            .polish: "Aplikacja będzie wysyłać przypomnienia o nauce i powtórkach słów"
        ],
        .permissionPermissionNotificationTitle: [
            .ukrainian: "Дозвіл на відправку повідомлень",
            .english: "Permission to send messages",
            .polish: "Zgoda na wysyłanie wiadomości"
        ],
        .try3DaysFree: [
            .ukrainian: "3 дні безкоштовно!",
            .english: "Try 3 Days Free!",
            .polish: "3 dni za darmo!"
        ],
        .trialAppliesToBoth: [
            .ukrainian: "Пробний період діє для будь-якого тарифу",
            .english: "Free trial available for both plans",
            .polish: "Okres próbny dostępny dla obu planów"
        ],
        .feature1: [
            .ukrainian: "Покращуйте англійську з тисячами нових слів",
            .english: "Improve your English with thousands of new words",
            .polish: "Ulepszaj angielski z tysiącami nowych słów"
        ],
        .feature2: [
            .ukrainian: "Використовуйте речення від ChatGPT, колокації та переклади",
            .english: "Use ChatGPT-generated sentences, collocations and translations",
            .polish: "Używaj zdań od ChatGPT, kolokacji i tłumaczeń"
        ],
        .feature3: [
            .ukrainian: "Створюйте власний словник з Oxford Dictionary",
            .english: "Create your own vocabulary with Oxford Dictionary",
            .polish: "Twórz własny słownik z Oxford Dictionary"
        ],
        .feature4: [
            .ukrainian: "Групуйте слова, створюйте списки та колекції",
            .english: "Group words, craft lists, and tailor your collections",
            .polish: "Grupuj słowa, twórz listy i kolekcje"
        ],
        .feature5: [
            .ukrainian: "Необмежені вправи для запам'ятовування слів",
            .english: "Do unlimited practice exercises and make words stick",
            .polish: "Nieograniczone ćwiczenia do zapamiętywania słów"
        ],
        .feature6: [
            .ukrainian: "Приєднуйтесь до глобальних викликів та тестів",
            .english: "Join global challenges: take themed tests",
            .polish: "Dołącz do globalnych wyzwań i testów"
        ],
        .startFreeTrial: [
            .ukrainian: "Почати безкоштовно",
            .english: "Start Free Trial",
            .polish: "Rozpocznij za darmo"
        ],
        .noPaymentNow: [
            .ukrainian: "Немає оплати зараз. Скасувати можна в будь-який момент.",
            .english: "No payment due now. Cancel anytime.",
            .polish: "Brak płatności teraz. Anuluj w każdej chwili."
        ],
        .howTrialWorks: [
            .ukrainian: "Як працює пробний період",
            .english: "How your free trial works",
            .polish: "Jak działa okres próbny"
        ],
        .byContinuing: [
            .ukrainian: "Продовжуючи, ви погоджуєтесь з",
            .english: "By continuing, you agree to",
            .polish: "Kontynuując, zgadzasz się na"
        ],
        .selectLanguageToSpeak: [
            .ukrainian: "Оберіть мову для розмови",
            .english: "Select language to speak",
            .polish: "Wybierz język do mówienia"
        ],
        .listeningIn: [
            .ukrainian: "Слухаю:",
            .english: "Listening in:",
            .polish: "Słucham:"
        ],
        .recognitionError: [
            .ukrainian: "Не вдалося розпізнати мову. Спробуйте ще раз.",
            .english: "Could not recognize speech. Please try again.",
            .polish: "Nie udało się rozpoznać mowy. Spróbuj ponownie."
        ],
        .tapToCapture: [
            .ukrainian: "Натисніть кнопку, щоб зробити фото",
            .english: "Tap the button to take a photo",
            .polish: "Naciśnij przycisk, aby zrobić zdjęcie"
        ],
        .tapWordToTranslateText: [
            .ukrainian: "Торкніться слова для перекладу",
            .english: "Tap a word to translate",
            .polish: "Dotknij słowa, aby przetłumaczyć"
        ],
        .retakeText: [
            .ukrainian: "Ще раз",
            .english: "Retake",
            .polish: "Ponów"
        ],
        .doneText: [
            .ukrainian: "Готово",
            .english: "Done",
            .polish: "Gotowe"
        ],
        .startingCameraText: [
            .ukrainian: "Запуск камери...",
            .english: "Starting camera...",
            .polish: "Uruchamianie kamery..."
        ],
        .cameraNotFoundText: [
            .ukrainian: "Камера не знайдена",
            .english: "Camera not found",
            .polish: "Nie znaleziono kamery"
        ],
        .closeText: [
            .ukrainian: "Закрити",
            .english: "Close",
            .polish: "Zamknij"
        ],
        .selectLanguagesForTranslation: [
            .ukrainian: "Оберіть мови для перекладу",
            .english: "Select languages for translation",
            .polish: "Wybierz języki do tłumaczenia"
        ],
        .translationWorksBothWays: [
            .ukrainian: "Переклад працюватиме в обидві сторони",
            .english: "Translation works both ways",
            .polish: "Tłumaczenie działa w obie strony"
        ],
        .tapFlagToChangeLanguage: [
            .ukrainian: "Торкніться прапору, щоб змінити мову",
            .english: "Tap flag to change language",
            .polish: "Dotknij flagi, aby zmienić język"
        ],
        .searchInLanguage: [
            .ukrainian: "Шукаєте слово мовою",
            .english: "Search in",
            .polish: "Szukaj w"
        ],
        .translatesTo: [
            .ukrainian: "→ переклад",
            .english: "→ translates to",
            .polish: "→ tłumaczy się na"
        ],
        .language1: [
            .ukrainian: "Мова 1",
            .english: "Language 1",
            .polish: "Język 1"
        ],
        .language2: [
            .ukrainian: "Мова 2",
            .english: "Language 2",
            .polish: "Język 2"
        ],
        .popularLanguages: [
            .ukrainian: "Популярні мови",
            .english: "Popular languages",
            .polish: "Popularne języki"
        ],
        .otherLanguages: [
            .ukrainian: "Інші мови",
            .english: "Other languages",
            .polish: "Inne języki"
        ],
        .originalWord: [
            .ukrainian: "Слово",
            .polish: "Słowo",
            .english: "Word"
        ],
        .enterTranslation: [
            .ukrainian: "Введіть переклад",
            .polish: "Wpisz tłumaczenie",
            .english: "Enter translation"
        ],
        .transcription: [
            .ukrainian: "Транскрипція",
            .english: "Transcription",
            .polish: "Transkrypcja"
        ],
        .optional: [
            .ukrainian: "необов'язково",
            .english: "opcjonalnie",
            .polish: "optional"
        ],
        .example: [
            .ukrainian: "Приклад",
            .english: "Example",
            .polish: "Przykład"
        ],
        .enterExample: [
            .ukrainian: "Введіть приклад речення",
            .english: "Enter example sentence",
            .polish: "Wpisz przykładowe zdanie"
        ],
        .preview: [
            .ukrainian: "Попередній перегляд",
            .english: "Preview",
            .polish: "Podgląd"
        ],
        .wordAdded: [
            .ukrainian: "Слово додано!",
            .english: "Word added!",
            .polish: "Słowo dodane!"
        ],
        .wordUpdated: [
            .ukrainian: "Слово оновлено!",
            .english: "Word updated!",
            .polish: "Słowo zaktualizowane!"
        ],
        .wordAddedMessage: [
            .ukrainian: "Слово успішно додано до вашого словника",
            .english: "Word successfully added to your dictionary",
            .polish: "Słowo zostało pomyślnie dodane do słownika"
        ],
        .wordUpdatedMessage: [
            .ukrainian: "Зміни успішно збережено",
            .english: "Changes saved successfully",
            .polish: "Zmiany zostały pomyślnie zapisane"
        ],
        .addAnother: [
            .ukrainian: "Додати ще",
            .polish: "Dodaj kolejne",
            .english: "Add another"
        ],
        .done: [
            .ukrainian: "Готово",
            .english: "Done",
            .polish: "Gotowe"
        ],
        .saved: [
            .ukrainian: "Збережено!",
            .english: "Saved!",
            .polish: "Zapisano!"
        ],
        .saving: [
            .ukrainian: "Збереження...",
            .english: "Saving...",
            .polish: "Zapisywanie..."
        ],
        .translationVariant: [
            .ukrainian: "Варіанти перекладу",
            .english: "Translation variants",
            .polish: "Warianty tłumaczenia"
        ],
        .loading: [
            .ukrainian: "Завантаження",
            .english: "Loading",
            .polish: "Ładowanie"
        ],
        .selectLanguagePair: [
            .ukrainian: "Оберіть пару мов",
            .polish: "Wybierz parę języków",
            .english: "Select language pair"
        ],
        .sourceLanguage: [
            .ukrainian: "Мова оригіналу",
            .polish: "Język źródłowy",
            .english: "Source language"
        ],
        .targetLanguage: [
            .ukrainian: "Мова перекладу",
            .polish: "Język docelowy",
            .english: "Target language"
        ],
        .changesSaved: [
            .ukrainian: "Зміни збережено",
            .polish: "Zmiany zapisane",
            .english: "Changes saved"
        ],
        .unknownError: [
            .ukrainian: "Невідома помилка",
            .polish: "Nieznany błąd",
            .english: "Unknown error"
        ],
        .languagePair: [
            .ukrainian: "Мови для перекладу",
            .polish: "Języki tłumaczenia",
            .english: "Languages for translation"
        ],
        .translation: [
            .ukrainian: "Переклад",
            .english: "Translation",
            .polish: "Tłumaczenie"
        ],
        .wordSets: [
                .ukrainian: "Набори слів",
                .english: "Word Sets",
                .polish: "Zestawy słów"
            ],
            .wordSetsSubtitle: [
                .ukrainian: "Вивчайте слова за темами",
                .english: "Learn words by topics",
                .polish: "Ucz się słów według tematów"
            ],
            .sets: [
                .ukrainian: "Набори",
                .english: "Sets",
                .polish: "Zestawy"
            ],
            .words: [
                .ukrainian: "слів",
                .english: "words",
                .polish: "słów"
            ],
            .filterBy: [
                .ukrainian: "Фільтрувати за",
                .english: "Filter by",
                .polish: "Filtruj według"
            ],
            .verbForms: [
                .ukrainian: "Форми дієслова",
                .english: "Verb forms",
                .polish: "Formy czasownika"
            ],
            .wordAlreadyExists: [
                .ukrainian: "Слово вже існує",
                .english: "Word already exists",
                .polish: "Słowo już istnieje"
            ],
            .wordAlreadyInDictionary: [
                .ukrainian: "Це слово вже є у вашому словнику",
                .english: "This word is already in your dictionary",
                .polish: "To słowo jest już w twoim słowniku"
            ],
            .ok: [
                .ukrainian: "OK",
                .english: "OK",
                .polish: "OK"
            ],
            .wordsInCategory: [
                .ukrainian: "Слова в категорії",
                .english: "Words in category",
                .polish: "Słowa w kategorii"
            ],
            // MARK: - Category Translations
            .categoryBasics: [
                .ukrainian: "Основи",
                .english: "Basics",
                .polish: "Podstawy"
            ],
            .categoryTravel: [
                .ukrainian: "Подорожі",
                .english: "Travel",
                .polish: "Podróże"
            ],
            .categoryFood: [
                .ukrainian: "Їжа",
                .english: "Food",
                .polish: "Jedzenie"
            ],
            .categoryWork: [
                .ukrainian: "Робота",
                .english: "Work",
                .polish: "Praca"
            ],
            .categoryEmotions: [
                .ukrainian: "Емоції",
                .english: "Emotions",
                .polish: "Emocje"
            ],
            .categoryFamily: [
                .ukrainian: "Сім'я",
                .english: "Family",
                .polish: "Rodzina"
            ],
            .categoryShopping: [
                .ukrainian: "Шопінг",
                .english: "Shopping",
                .polish: "Zakupy"
            ],
            .categoryHealth: [
                .ukrainian: "Здоров'я",
                .english: "Health",
                .polish: "Zdrowie"
            ],
            .categoryTechnology: [
                .ukrainian: "Технології",
                .english: "Technology",
                .polish: "Technologia"
            ],
            .categoryNature: [
                .ukrainian: "Природа",
                .english: "Nature",
                .polish: "Natura"
            ],
            .categoryEducation: [
                .ukrainian: "Освіта",
                .english: "Education",
                .polish: "Edukacja"
            ],
            .categoryBusiness: [
                .ukrainian: "Бізнес",
                .english: "Business",
                .polish: "Biznes"
            ],
            .categoryHobbies: [
                .ukrainian: "Хобі",
                .english: "Hobbies",
                .polish: "Hobby"
            ],
            .categorySocial: [
                .ukrainian: "Спілкування",
                .english: "Social",
                .polish: "Społeczność"
            ],
            .categoryHome: [
                .ukrainian: "Дім",
                .english: "Home",
                .polish: "Dom"
            ],
            .categoryVerbs: [
                .ukrainian: "Дієслова",
                .english: "Verbs",
                .polish: "Czasowniki"
            ],
            .categoryIrregularVerbs: [
                .ukrainian: "Неправильні дієслова",
                .english: "Irregular Verbs",
                .polish: "Czasowniki Nieregularne"
            ],
            .searchSets: [
                .ukrainian: "Пошук наборів...",
                .english: "Search sets...",
                .polish: "Szukaj zestawów..."
            ],
            .searchInSet: [
                .ukrainian: "Пошук у наборі...",
                .english: "Search in set...",
                .polish: "Szukaj w zestawie..."
            ],
            .addAll: [
                .ukrainian: "Додати всі",
                .english: "Add All",
                .polish: "Dodaj wszystkie"
            ],
            .addAllWords: [
                .ukrainian: "Додати всі слова?",
                .english: "Add all words?",
                .polish: "Dodać wszystkie słowa?"
            ],
            .addAllWordsMessage: [
                .ukrainian: "Всі слова з цього набору будуть додані до вашого словника",
                .english: "All words from this set will be added to your dictionary",
                .polish: "Wszystkie słowa z tego zestawu zostaną dodane do słownika"
            ],
            .sortBy: [
                .ukrainian: "Сортувати:",
                .english: "Sort by:",
                .polish: "Sortuj:"
            ],
            .addedToDictionary: [
                .ukrainian: "Додано до словника",
                .english: "Added to Dictionary",
                .polish: "Dodano do słownika"
            ],
            .addToDictionary: [
                .ukrainian: "Додати до словника",
                .english: "Add to Dictionary",
                .polish: "Dodaj do słownika"
            ],
            .synonyms: [
                .ukrainian: "Синоніми",
                .english: "Synonyms",
                .polish: "Synonimy"
            ],
            .generatingWords: [
                .ukrainian: "Генеруємо слова...",
                .english: "Generating words...",
                .polish: "Generowanie słów..."
            ],
            .aiGenerating: [
                .ukrainian: "ШІ підбирає найкращі слова та приклади для вас",
                .english: "AI is selecting the best words and examples for you",
                .polish: "AI dobiera najlepsze słowa i przykłady dla Ciebie"
            ],
            .regenerate: [
                .ukrainian: "Згенерувати нові",
                .english: "Regenerate",
                .polish: "Wygeneruj nowe"
            ],
            .useLocal: [
                .ukrainian: "Використати офлайн-версію",
                .english: "Use offline version",
                .polish: "Użyj wersji offline"
            ],
            .aiError: [
                .ukrainian: "Не вдалося згенерувати. Спробуємо офлайн-версію?",
                .english: "Failed to generate. Try offline version?",
                .polish: "Nie udało się wygenerować. Spróbować wersji offline?"
            ],
            
            // Filters
            .filterAll: [
                .ukrainian: "Всі",
                .english: "All",
                .polish: "Wszystkie"
            ],
            .filterBeginner: [
                .ukrainian: "Початковий",
                .english: "Beginner",
                .polish: "Początkujący"
            ],
            .filterIntermediate: [
                .ukrainian: "Середній",
                .english: "Intermediate",
                .polish: "Średni"
            ],
            .filterAdvanced: [
                .ukrainian: "Просунутий",
                .english: "Advanced",
                .polish: "Zaawansowany"
            ],
            .filterPremium: [
                .ukrainian: "Premium",
                .english: "Premium",
                .polish: "Premium"
            ],
            .filterFree: [
                .ukrainian: "Безкоштовні",
                .english: "Free",
                .polish: "Darmowe"
            ],
            
            // Sort
            .sortOriginal: [
                .ukrainian: "За замовчуванням",
                .english: "Default",
                .polish: "Domyślnie"
            ],
            .sortTranslation: [
                .ukrainian: "За перекладом",
                .english: "By Translation",
                .polish: "Według tłumaczenia"
            ],
            .sortAlphabetical: [
                .ukrainian: "А-Я",
                .english: "A-Z",
                .polish: "A-Z"
            ],
            
            // Tips
            .tipLearning: [
                .ukrainian: "💡 Порада: Вивчайте 5-10 слів на день",
                .english: "💡 Tip: Learn 5-10 words per day",
                .polish: "💡 Wskazówka: Ucz się 5-10 słów dziennie"
            ],
            .tipExamples: [
                .ukrainian: "💡 Порада: Приклади допомагають зрозуміти контекст",
                .english: "💡 Tip: Examples help understand context",
                .polish: "💡 Wskazówka: Przykłady pomagają zrozumieć kontekst"
            ],
            .tipRepetition: [
                .ukrainian: "💡 Порада: Повторення через інтервали — ключ до пам'яті",
                .english: "💡 Tip: Spaced repetition is key to memory",
                .polish: "💡 Wskazówka: Powtórki w interwałach — klucz do pamięci"
            ],
            .tipContext: [
                .ukrainian: "💡 Порада: Вивчайте слова в контексті",
                .english: "💡 Tip: Learn words in context",
                .polish: "💡 Wskazówka: Ucz się słów w kontekście"
            ],
            
            // Word Set Titles (AI categories)
            .wordsetBasicWords: [
                .ukrainian: "Базові слова",
                .english: "Basic Words",
                .polish: "Podstawowe słowa"
            ],
            .wordsetVerbs: [
                .ukrainian: "Дієслова",
                .english: "Verbs",
                .polish: "Czasowniki"
            ],
            .wordsetNouns: [
                .ukrainian: "Іменники",
                .english: "Nouns",
                .polish: "Rzeczowniki"
            ],
            .wordsetAdjectives: [
                .ukrainian: "Прикметники",
                .english: "Adjectives",
                .polish: "Przymiotniki"
            ],
            .wordsetTravel: [
                .ukrainian: "Для подорожей",
                .english: "Travel",
                .polish: "Podróże"
            ],
            .wordsetFood: [
                .ukrainian: "Їжа та ресторани",
                .english: "Food & Dining",
                .polish: "Jedzenie i restauracje"
            ],
            .wordsetWork: [
                .ukrainian: "Робота та бізнес",
                .english: "Work & Business",
                .polish: "Praca i biznes"
            ],
            .wordsetHobbies: [
                .ukrainian: "Хобі та дозвілля",
                .english: "Hobbies & Leisure",
                .polish: "Hobby i wypoczynek"
            ],
            .wordsetEmotions: [
                .ukrainian: "Емоції та почуття",
                .english: "Emotions & Feelings",
                .polish: "Emocje i uczucia"
            ],
            .wordsetFamily: [
                .ukrainian: "Сім'я та люди",
                .english: "Family & People",
                .polish: "Rodzina i ludzie"
            ],
            .wordsetTime: [
                .ukrainian: "Час та дати",
                .english: "Time & Dates",
                .polish: "Czas i daty"
            ],
            .wordsetShopping: [
                .ukrainian: "Шопінг",
                .english: "Shopping",
                .polish: "Zakupy"
            ],
            .wordsetHealth: [
                .ukrainian: "Здоров'я",
                .english: "Health",
                .polish: "Zdrowie"
            ],
            .wordsetTechnology: [
                .ukrainian: "Технології",
                .english: "Technology",
                .polish: "Technologia"
            ],
            .wordsetNature: [
                .ukrainian: "Природа",
                .english: "Nature",
                .polish: "Natura"
            ],
            .wordsetEducation: [
                .ukrainian: "Навчання",
                .english: "Education",
                .polish: "Edukacja"
            ],
            .wordsetBusiness: [
                .ukrainian: "Бізнес",
                .english: "Business",
                .polish: "Biznes"
            ],
            .wordsetScience: [
                .ukrainian: "Наука",
                .english: "Science",
                .polish: "Nauka"
            ],
            .wordsetArt: [
                .ukrainian: "Мистецтво",
                .english: "Art",
                .polish: "Sztuka"
            ],
            .wordsetSports: [
                .ukrainian: "Спорт",
                .english: "Sports",
                .polish: "Sport"
            ],
            .wordsetCulture: [
                .ukrainian: "Культура",
                .english: "Culture",
                .polish: "Kultura"
            ],
        .createCustomSet: [
                .ukrainian: "Створити набір",
                .english: "Create Set",
                .polish: "Utwórz zestaw"
            ],
            .createYourOwnSet: [
                .ukrainian: "Створіть свій набір слів",
                .english: "Create your own word set",
                .polish: "Utwórz własny zestaw słów"
            ],
            .aiWillGenerate: [
                .ukrainian: "ШІ згенерує слова на основі вашого опису",
                .english: "AI will generate words based on your description",
                .polish: "AI wygeneruje słowa na podstawie Twojego opisu"
            ],
            .setTitle: [
                .ukrainian: "Назва набору",
                .english: "Set title",
                .polish: "Tytuł zestawu"
            ],
            .titlePlaceholder: [
                .ukrainian: "Наприклад: Для подорожі в Париж",
                .english: "E.g., Travel to Paris",
                .polish: "Np. Podróż do Paryża"
            ],
            .whatTopic: [
                .ukrainian: "Яка тема?",
                .english: "What topic?",
                .polish: "Jaki temat?"
            ],
            .describeTopic: [
                .ukrainian: "Опишіть детальніше: що вивчатимемо, в якому контексті...",
                .english: "Describe in detail: what we'll learn, in what context...",
                .polish: "Opisz szczegółowo: czego się nauczymy, w jakim kontekście..."
            ],
            .difficultyLevel: [
                .ukrainian: "Рівень складності",
                .english: "Difficulty level",
                .polish: "Poziom trudności"
            ],
            .wordCount: [
                .ukrainian: "Кількість слів",
                .english: "Word count",
                .polish: "Liczba słów"
            ],
            .focusAreas: [
                .ukrainian: "Фокус теми",
                .english: "Focus areas",
                .polish: "Obszary tematyczne"
            ],
            .advancedOptions: [
                .ukrainian: "Розширені налаштування",
                .english: "Advanced options",
                .polish: "Opcje zaawansowane"
            ],
            .customPrompt: [
                .ukrainian: "Власний промпт для ШІ",
                .english: "Custom AI prompt",
                .polish: "Własny prompt AI"
            ],
            .promptTips: [
                .ukrainian: "Підказка: можете вказати специфічні вимоги, наприклад 'тільки розмовні фрази' або 'бізнес-лексика'",
                .english: "Tip: You can specify requirements, e.g. 'only informal phrases' or 'business vocabulary'",
                .polish: "Wskazówka: możesz określić wymagania, np. 'tylko zwroty potoczne' lub 'słownictwo biznesowe'"
            ],
            .generateSet: [
                .ukrainian: "Згенерувати набір",
                .english: "Generate set",
                .polish: "Generuj zestaw"
            ],
            .generating: [
                .ukrainian: "Генерація...",
                .english: "Generating...",
                .polish: "Generowanie..."
            ],
            .createSet: [
                .ukrainian: "Створити",
                .english: "Create",
                .polish: "Utwórz"
            ],
            .pleaseLogin: [
                .ukrainian: "Будь ласка, увійдіть в акаунт",
                .english: "Please log in to your account",
                .polish: "Proszę zalogować się na konto"
            ],
            
            // MARK: - Word Rating
            .howIsThisTranslation: [
                .ukrainian: "Як вам цей переклад?",
                .english: "How is this translation?",
                .polish: "Co sądzisz o tym tłumaczeniu?"
            ],
            .howCanBeBetter: [
                .ukrainian: "Що можна покращити?",
                .english: "What can be improved?",
                .polish: "Co można poprawić?"
            ],
            .submitRating: [
                .ukrainian: "Надіслати оцінку",
                .english: "Submit rating",
                .polish: "Wyślij ocenę"
            ],
            .thankYou: [
                .ukrainian: "Дякуємо!",
                .english: "Thank you!",
                .polish: "Dziękujemy!"
            ],
            .feedbackReceived: [
                .ukrainian: "Ваш відгук допоможе покращити Wordy для всіх",
                .english: "Your feedback helps improve Wordy for everyone",
                .polish: "Twoja opinia pomoże ulepszyć Wordy dla wszystkich"
            ],
            
            // MARK: - Set Exchange
            .exchangeSets: [
                .ukrainian: "Обмін наборами",
                .english: "Exchange sets",
                .polish: "Wymiana zestawów"
            ],
            .export: [
                .ukrainian: "Експорт",
                .english: "Export",
                .polish: "Eksport"
            ],
            .importTitle: [
                .ukrainian: "Імпорт",
                .english: "Import",
                .polish: "Import"
            ],
            .community: [
                .ukrainian: "Спільнота",
                .english: "Community",
                .polish: "Społeczność"
            ],
            .selectSetToExport: [
                .ukrainian: "Оберіть набір для експорту",
                .english: "Select set to export",
                .polish: "Wybierz zestaw do eksportu"
            ],
            .importFromFile: [
                .ukrainian: "Імпорт з файлу",
                .english: "Import from file",
                .polish: "Import z pliku"
            ],
            .importJSONDescription: [
                .ukrainian: "Завантажте JSON файл з набором слів",
                .english: "Upload a JSON file with word set",
                .polish: "Prześlij plik JSON z zestawem słów"
            ],
            .scanQRCode: [
                .ukrainian: "Сканувати QR-код",
                .english: "Scan QR code",
                .polish: "Skanuj kod QR"
            ],
            .scanQRDescription: [
                .ukrainian: "Імпортуйте набір за допомогою QR-коду",
                .english: "Import a set using QR code",
                .polish: "Zaimportuj zestaw za pomocą kodu QR"
            ],
            .pasteFromClipboard: [
                .ukrainian: "Вставити з буфера",
                .english: "Paste from clipboard",
                .polish: "Wklej ze schowka"
            ],
            .pasteJSONDescription: [
                .ukrainian: "Вставте JSON текст з буфера обміну",
                .english: "Paste JSON text from clipboard",
                .polish: "Wklej tekst JSON ze schowka"
            ],
            .popular: [
                .ukrainian: "Популярні",
                .english: "Popular",
                .polish: "Popularne"
            ],
            .recentWord: [
                .ukrainian: "Нові",
                .english: "Recent",
                .polish: "Nowe"
            ],
            .trending: [
                .ukrainian: "Трендові",
                .english: "Trending",
                .polish: "Trendujące"
            ],
            .following: [
                .ukrainian: "Підписки",
                .english: "Following",
                .polish: "Obserwowane"
            ],
            .invalidFileFormat: [
                .ukrainian: "Невірний формат файлу. Потрібен JSON.",
                .english: "Invalid file format. JSON required.",
                .polish: "Nieprawidłowy format pliku. Wymagany JSON."
            ],
            .unsupportedFormat: [
                .ukrainian: "Цей формат не підтримується",
                .english: "This format is not supported",
                .polish: "Ten format nie jest obsługiwany"
            ],
            
            // MARK: - Tips for generation
            .tipSpecific: [
                .ukrainian: "Будьте конкретними в описі",
                .english: "Be specific in your description",
                .polish: "Bądź konkretny w opisie"
            ],
            .tipLevel: [
                .ukrainian: "Оберіть відповідний рівень",
                .english: "Choose appropriate level",
                .polish: "Wybierz odpowiedni poziom"
            ],
            .seeAll: [
                .ukrainian: "Показати всі",
                .english: "See all",
                .polish: "Zobacz wszystkie"
            ],
            .textTooLong: [
                .ukrainian: "Максимум 254 символи",
                .english: "Maximum 254 characters",
                .polish: "Maksymalnie 254 znaki"
            ],
            .voiceInputTooLong: [
                .ukrainian: "Текст обрізано до 254 символів",
                .english: "Text truncated to 254 characters",
                .polish: "Tekst skrócony do 254 znaków"
            ],
            .warning: [
                .ukrainian: "Увага",
                .english: "Warning",
                .polish: "Ostrzeżenie"
            ],
            .audioPermissionMessage: [
                .ukrainian: "Потрібен доступ до аудіо для програвання вимови",
                .english: "Audio access needed for pronunciation playback",
                .polish: "Potrzebny dostęp do audio do odtwarzania wymowy"
            ],
            .deleteButton: [
                .ukrainian: "Видалити",
                .english: "Delete",
                .polish: "Usunąć"
            ],
            .statusLearned: [
                .ukrainian: "Вивчено",
                .english: "Learned",
                .polish: "Uczony"
            ],
            .backTitle: [
                .ukrainian: "Назад",
                .english: "Back",
                .polish: "Powrót"
            ]
        ]
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
