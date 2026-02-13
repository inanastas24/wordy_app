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
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
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
        .welcomeBack: [
            .ukrainian: "З поверненням!",
            .english: "Welcome back!",
            .polish: "Witaj ponownie!"
        ],
        .signInToContinue: [
            .ukrainian: "Увійдіть, щоб продовжити",
            .english: "Sign in to continue",
            .polish: "Zaloguj się, aby kontynuować"
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
            .ukrainian: "Подобається додаток?",
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
        .trackingPermission: [
            .ukrainian: "Відстеження в інших додатках",
            .english: "Tracking in other apps",
            .polish: "Śledzenie w innych aplikacjach"
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
        ]
    ]
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
