// WordSetModels.swift — оновлений з 1520 готовими словами
import SwiftUI
import Combine

// MARK: - Word Set
struct WordSet: Identifiable, Codable, Hashable {
    let id: String
    let titleKey: String
    let titleLocalized: [String: String]
    let emoji: String
    let gradientColors: [String]
    let difficulty: DifficultyLevel
    let category: WordCategory
    let wordCount: Int
    let words: [Word]
    
    func title(for languageCode: String) -> String {
        titleLocalized[languageCode] ?? titleLocalized["en"] ?? titleKey
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case a1, a2, b1, b2, c1, c2
    
    var displayName: String { rawValue.uppercased() }
    var description: String {
        switch self {
        case .a1: return "Beginner"
        case .a2: return "Elementary"
        case .b1: return "Intermediate"
        case .b2: return "Upper-Intermediate"
        case .c1: return "Advanced"
        case .c2: return "Proficiency"
        }
    }
}

enum WordCategory: String, Codable, CaseIterable {
    case basics = "basics"
    case travel = "travel"
    case food = "food"
    case work = "work"
    case emotions = "emotions"
    case family = "family"
    case shopping = "shopping"
    case health = "health"
    case technology = "technology"
    case nature = "nature"
    case education = "education"
    case business = "business"
    case hobbies = "hobbies"
    case social = "social"
    case home = "home"
    case verbs = "verbs"
    case irregularVerbs = "irregularVerbs"
    
    var icon: String {
        switch self {
        case .basics: return "book.fill"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .work: return "briefcase.fill"
        case .emotions: return "heart.fill"
        case .family: return "person.2.fill"
        case .shopping: return "bag.fill"
        case .health: return "heart.text.square.fill"
        case .technology: return "cpu.fill"
        case .nature: return "leaf.fill"
        case .education: return "graduationcap.fill"
        case .business: return "building.2.fill"
        case .hobbies: return "paintbrush.fill"
        case .social: return "bubble.left.fill"
        case .home: return "house.fill"
        case .verbs: return "textformat.abc"
        case .irregularVerbs: return "exclamationmark.triangle.fill"
        }
    }
    
    var defaultEmoji: String {
        switch self {
        case .basics: return "📚"
        case .travel: return "✈️"
        case .food: return "🍕"
        case .work: return "💼"
        case .emotions: return "❤️"
        case .family: return "👨‍👩‍👧‍👦"
        case .shopping: return "🛍️"
        case .health: return "💊"
        case .technology: return "💻"
        case .nature: return "🌿"
        case .education: return "🎓"
        case .business: return "🏢"
        case .hobbies: return "🎨"
        case .social: return "💬"
        case .home: return "🏠"
        case .verbs: return "🏃"
        case .irregularVerbs: return "⚡"
        }
    }

    var localizationKey: LocalizableKey {
        switch self {
        case .basics: return .categoryBasics
        case .travel: return .categoryTravel
        case .food: return .categoryFood
        case .work: return .categoryWork
        case .emotions: return .categoryEmotions
        case .family: return .categoryFamily
        case .shopping: return .categoryShopping
        case .health: return .categoryHealth
        case .technology: return .categoryTechnology
        case .nature: return .categoryNature
        case .education: return .categoryEducation
        case .business: return .categoryBusiness
        case .hobbies: return .categoryHobbies
        case .social: return .categorySocial
        case .home: return .categoryHome
        case .verbs: return .categoryVerbs
        case .irregularVerbs: return .categoryIrregularVerbs
        }
    }
}

// MARK: - Word
struct Word: Identifiable, Codable, Hashable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let synonyms: [String]
    let difficulty: DifficultyLevel
    let category: WordCategory?
    
    // TTS cache
    var audioUrl: String?
    
    init(id: String, original: String, translation: String, transcription: String? = nil, exampleSentence: String? = nil, exampleTranslation: String? = nil, synonyms: [String] = [], difficulty: DifficultyLevel, category: WordCategory? = nil, audioUrl: String? = nil) {
        self.id = id
        self.original = original
        self.translation = translation
        self.transcription = transcription
        self.exampleSentence = exampleSentence
        self.exampleTranslation = exampleTranslation
        self.synonyms = synonyms
        self.difficulty = difficulty
        self.category = category
        self.audioUrl = audioUrl
    }
}

// MARK: - Predefined Word Sets (1520 слів en-uk)
struct PredefinedWordSets {
    // A1 — 300 слів (основи)
    static let a1Words: [Word] = [
        // Basics (100)
        Word(id: "a1_001", original: "hello", translation: "привіт", transcription: "/həˈloʊ/", exampleSentence: "Hello, how are you?", exampleTranslation: "Привіт, як справи?", synonyms: ["hi", "hey"], difficulty: .a1),
        Word(id: "a1_002", original: "goodbye", translation: "бувай", transcription: "/ˌɡʊdˈbaɪ/", exampleSentence: "Goodbye, see you tomorrow!", exampleTranslation: "Бувай, побачимось завтра!", synonyms: ["bye", "see you"], difficulty: .a1),
        Word(id: "a1_003", original: "please", translation: "будь ласка", transcription: "/pliːz/", exampleSentence: "Please, help me.", exampleTranslation: "Будь ласка, допоможи мені.", synonyms: [], difficulty: .a1),
        Word(id: "a1_004", original: "thank you", translation: "дякую", transcription: "/ˈθæŋk juː/", exampleSentence: "Thank you very much!", exampleTranslation: "Дуже дякую!", synonyms: ["thanks"], difficulty: .a1),
        Word(id: "a1_005", original: "yes", translation: "так", transcription: "/jes/", exampleSentence: "Yes, I understand.", exampleTranslation: "Так, я розумію.", synonyms: ["yeah"], difficulty: .a1),
        Word(id: "a1_006", original: "no", translation: "ні", transcription: "/noʊ/", exampleSentence: "No, I don't know.", exampleTranslation: "Ні, я не знаю.", synonyms: ["nope"], difficulty: .a1),
        Word(id: "a1_007", original: "sorry", translation: "вибач", transcription: "/ˈsɔːri/", exampleSentence: "Sorry, I'm late.", exampleTranslation: "Вибач, я запізнився.", synonyms: ["pardon"], difficulty: .a1),
        Word(id: "a1_008", original: "name", translation: "ім'я", transcription: "/neɪm/", exampleSentence: "My name is John.", exampleTranslation: "Мене звати Джон.", synonyms: [], difficulty: .a1),
        Word(id: "a1_009", original: "friend", translation: "друг", transcription: "/frend/", exampleSentence: "She is my best friend.", exampleTranslation: "Вона моя найкраща подруга.", synonyms: ["buddy", "pal"], difficulty: .a1),
        Word(id: "a1_010", original: "family", translation: "сім'я", transcription: "/ˈfæməli/", exampleSentence: "I love my family.", exampleTranslation: "Я люблю свою сім'ю.", synonyms: ["relatives"], difficulty: .a1),
        Word(id: "a1_011", original: "mother", translation: "мати", transcription: "/ˈmʌðər/", exampleSentence: "My mother is a doctor.", exampleTranslation: "Моя мама лікар.", synonyms: ["mom", "mum"], difficulty: .a1),
        Word(id: "a1_012", original: "father", translation: "батько", transcription: "/ˈfɑːðər/", exampleSentence: "His father works in a bank.", exampleTranslation: "Його батько працює в банку.", synonyms: ["dad"], difficulty: .a1),
        Word(id: "a1_013", original: "brother", translation: "брат", transcription: "/ˈbrʌðər/", exampleSentence: "I have one brother.", exampleTranslation: "У мене один брат.", synonyms: [], difficulty: .a1),
        Word(id: "a1_014", original: "sister", translation: "сестра", transcription: "/ˈsɪstər/", exampleSentence: "My sister is younger.", exampleTranslation: "Моя сестра молодша.", synonyms: [], difficulty: .a1),
        Word(id: "a1_015", original: "man", translation: "чоловік", transcription: "/mæn/", exampleSentence: "That man is my teacher.", exampleTranslation: "Той чоловік — мій вчитель.", synonyms: ["guy"], difficulty: .a1),
        Word(id: "a1_016", original: "woman", translation: "жінка", transcription: "/ˈwʊmən/", exampleSentence: "The woman is reading.", exampleTranslation: "Жінка читає.", synonyms: ["lady"], difficulty: .a1),
        Word(id: "a1_017", original: "child", translation: "дитина", transcription: "/tʃaɪld/", exampleSentence: "The child is playing.", exampleTranslation: "Дитина грається.", synonyms: ["kid"], difficulty: .a1),
        Word(id: "a1_018", original: "boy", translation: "хлопчик", transcription: "/bɔɪ/", exampleSentence: "The boy is running.", exampleTranslation: "Хлопчик біжить.", synonyms: [], difficulty: .a1),
        Word(id: "a1_019", original: "girl", translation: "дівчинка", transcription: "/ɡɜːrl/", exampleSentence: "The girl is singing.", exampleTranslation: "Дівчинка співає.", synonyms: [], difficulty: .a1),
        Word(id: "a1_020", original: "people", translation: "люди", transcription: "/ˈpiːpl/", exampleSentence: "Many people live here.", exampleTranslation: "Тут живе багато людей.", synonyms: [], difficulty: .a1),
        Word(id: "a1_021", original: "water", translation: "вода", transcription: "/ˈwɔːtər/", exampleSentence: "I need some water.", exampleTranslation: "Мені потрібна вода.", synonyms: [], difficulty: .a1),
        Word(id: "a1_022", original: "food", translation: "їжа", transcription: "/fuːd/", exampleSentence: "This food is delicious.", exampleTranslation: "Ця їжа смачна.", synonyms: ["meal"], difficulty: .a1),
        Word(id: "a1_023", original: "bread", translation: "хліб", transcription: "/bred/", exampleSentence: "I eat bread every day.", exampleTranslation: "Я їм хліб щодня.", synonyms: [], difficulty: .a1),
        Word(id: "a1_024", original: "milk", translation: "молоко", transcription: "/mɪlk/", exampleSentence: "I drink milk in the morning.", exampleTranslation: "Я п'ю молоко вранці.", synonyms: [], difficulty: .a1),
        Word(id: "a1_025", original: "coffee", translation: "кава", transcription: "/ˈkɔːfi/", exampleSentence: "I love coffee.", exampleTranslation: "Я люблю каву.", synonyms: [], difficulty: .a1),
        Word(id: "a1_026", original: "tea", translation: "чай", transcription: "/tiː/", exampleSentence: "Would you like some tea?", exampleTranslation: "Хочеш чаю?", synonyms: [], difficulty: .a1),
        Word(id: "a1_027", original: "apple", translation: "яблуко", transcription: "/ˈæpl/", exampleSentence: "An apple a day keeps the doctor away.", exampleTranslation: "Яблуко на день — і не треба лікаря.", synonyms: [], difficulty: .a1),
        Word(id: "a1_028", original: "banana", translation: "банан", transcription: "/bəˈnænə/", exampleSentence: "I eat a banana for breakfast.", exampleTranslation: "Я їм банан на сніданок.", synonyms: [], difficulty: .a1),
        Word(id: "a1_029", original: "orange", translation: "апельсин", transcription: "/ˈɔːrɪndʒ/", exampleSentence: "Orange juice is fresh.", exampleTranslation: "Апельсиновий сік свіжий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_030", original: "meat", translation: "м'ясо", transcription: "/miːt/", exampleSentence: "I don't eat meat.", exampleTranslation: "Я не їм м'яса.", synonyms: [], difficulty: .a1),
        Word(id: "a1_031", original: "fish", translation: "риба", transcription: "/fɪʃ/", exampleSentence: "Fish is healthy.", exampleTranslation: "Риба корисна.", synonyms: [], difficulty: .a1),
        Word(id: "a1_032", original: "egg", translation: "яйце", transcription: "/eɡ/", exampleSentence: "I had eggs for breakfast.", exampleTranslation: "Я з'їв яйця на сніданок.", synonyms: [], difficulty: .a1),
        Word(id: "a1_033", original: "rice", translation: "рис", transcription: "/raɪs/", exampleSentence: "We eat rice with vegetables.", exampleTranslation: "Ми їмо рис з овочами.", synonyms: [], difficulty: .a1),
        Word(id: "a1_034", original: "sugar", translation: "цукор", transcription: "/ˈʃʊɡər/", exampleSentence: "No sugar, please.", exampleTranslation: "Без цукру, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_035", original: "salt", translation: "сіль", transcription: "/sɔːlt/", exampleSentence: "Pass me the salt.", exampleTranslation: "Передай мені сіль.", synonyms: [], difficulty: .a1),
        Word(id: "a1_036", original: "home", translation: "дім", transcription: "/hoʊm/", exampleSentence: "I want to go home.", exampleTranslation: "Я хочу додому.", synonyms: ["house"], difficulty: .a1),
        Word(id: "a1_037", original: "room", translation: "кімната", transcription: "/ruːm/", exampleSentence: "This is my room.", exampleTranslation: "Це моя кімната.", synonyms: [], difficulty: .a1),
        Word(id: "a1_038", original: "bed", translation: "ліжко", transcription: "/bed/", exampleSentence: "I sleep in my bed.", exampleTranslation: "Я сплю у своєму ліжку.", synonyms: [], difficulty: .a1),
        Word(id: "a1_039", original: "table", translation: "стіл", transcription: "/ˈteɪbl/", exampleSentence: "The book is on the table.", exampleTranslation: "Книга на столі.", synonyms: [], difficulty: .a1),
        Word(id: "a1_040", original: "chair", translation: "стілець", transcription: "/tʃer/", exampleSentence: "Sit on the chair.", exampleTranslation: "Сідай на стілець.", synonyms: [], difficulty: .a1),
        Word(id: "a1_041", original: "door", translation: "двері", transcription: "/dɔːr/", exampleSentence: "Close the door, please.", exampleTranslation: "Закрий двері, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_042", original: "window", translation: "вікно", transcription: "/ˈwɪndoʊ/", exampleSentence: "Open the window.", exampleTranslation: "Відкрий вікно.", synonyms: [], difficulty: .a1),
        Word(id: "a1_043", original: "kitchen", translation: "кухня", transcription: "/ˈkɪtʃɪn/", exampleSentence: "Mom is in the kitchen.", exampleTranslation: "Мама на кухні.", synonyms: [], difficulty: .a1),
        Word(id: "a1_044", original: "bathroom", translation: "ванна кімната", transcription: "/ˈbæθruːm/", exampleSentence: "Where is the bathroom?", exampleTranslation: "Де ванна кімната?", synonyms: ["toilet", "restroom"], difficulty: .a1),
        Word(id: "a1_045", original: "school", translation: "школа", transcription: "/skuːl/", exampleSentence: "I go to school every day.", exampleTranslation: "Я ходжу до школи щодня.", synonyms: [], difficulty: .a1),
        Word(id: "a1_046", original: "teacher", translation: "вчитель", transcription: "/ˈtiːtʃər/", exampleSentence: "My teacher is kind.", exampleTranslation: "Мій вчитель добрий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_047", original: "student", translation: "учень", transcription: "/ˈstuːdnt/", exampleSentence: "I am a student.", exampleTranslation: "Я учень.", synonyms: ["pupil"], difficulty: .a1),
        Word(id: "a1_048", original: "book", translation: "книга", transcription: "/bʊk/", exampleSentence: "I read a book.", exampleTranslation: "Я читаю книгу.", synonyms: [], difficulty: .a1),
        Word(id: "a1_049", original: "pen", translation: "ручка", transcription: "/pen/", exampleSentence: "I need a pen.", exampleTranslation: "Мені потрібна ручка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_050", original: "pencil", translation: "олівець", transcription: "/ˈpensl/", exampleSentence: "Write with a pencil.", exampleTranslation: "Пиши олівцем.", synonyms: [], difficulty: .a1),
        Word(id: "a1_051", original: "paper", translation: "папір", transcription: "/ˈpeɪpər/", exampleSentence: "I need some paper.", exampleTranslation: "Мені потрібен папір.", synonyms: [], difficulty: .a1),
        Word(id: "a1_052", original: "phone", translation: "телефон", transcription: "/foʊn/", exampleSentence: "My phone is ringing.", exampleTranslation: "Мій телефон дзвонить.", synonyms: ["mobile", "cell"], difficulty: .a1),
        Word(id: "a1_053", original: "computer", translation: "комп'ютер", transcription: "/kəmˈpjuːtər/", exampleSentence: "I work on a computer.", exampleTranslation: "Я працюю за комп'ютером.", synonyms: ["PC"], difficulty: .a1),
        Word(id: "a1_054", original: "time", translation: "час", transcription: "/taɪm/", exampleSentence: "What time is it?", exampleTranslation: "Котра година?", synonyms: [], difficulty: .a1),
        Word(id: "a1_055", original: "day", translation: "день", transcription: "/deɪ/", exampleSentence: "Have a nice day!", exampleTranslation: "Гарного дня!", synonyms: [], difficulty: .a1),
        Word(id: "a1_056", original: "night", translation: "ніч", transcription: "/naɪt/", exampleSentence: "At night I sleep.", exampleTranslation: "Вночі я сплю.", synonyms: [], difficulty: .a1),
        Word(id: "a1_057", original: "morning", translation: "ранок", transcription: "/ˈmɔːrnɪŋ/", exampleSentence: "Good morning!", exampleTranslation: "Доброго ранку!", synonyms: [], difficulty: .a1),
        Word(id: "a1_058", original: "evening", translation: "вечір", transcription: "/ˈiːvnɪŋ/", exampleSentence: "Good evening!", exampleTranslation: "Добрий вечір!", synonyms: [], difficulty: .a1),
        Word(id: "a1_059", original: "today", translation: "сьогодні", transcription: "/təˈdeɪ/", exampleSentence: "Today is Monday.", exampleTranslation: "Сьогодні понеділок.", synonyms: [], difficulty: .a1),
        Word(id: "a1_060", original: "tomorrow", translation: "завтра", transcription: "/təˈmɔːroʊ/", exampleSentence: "See you tomorrow!", exampleTranslation: "Побачимось завтра!", synonyms: [], difficulty: .a1),
        Word(id: "a1_061", original: "yesterday", translation: "вчора", transcription: "/ˈjestərdeɪ/", exampleSentence: "I was busy yesterday.", exampleTranslation: "Я був зайнятий вчора.", synonyms: [], difficulty: .a1),
        Word(id: "a1_062", original: "week", translation: "тиждень", transcription: "/wiːk/", exampleSentence: "I work five days a week.", exampleTranslation: "Я працюю п'ять днів на тиждень.", synonyms: [], difficulty: .a1),
        Word(id: "a1_063", original: "month", translation: "місяць", transcription: "/mʌnθ/", exampleSentence: "My birthday is next month.", exampleTranslation: "Мій день народження наступного місяця.", synonyms: [], difficulty: .a1),
        Word(id: "a1_064", original: "year", translation: "рік", transcription: "/jɪr/", exampleSentence: "Happy New Year!", exampleTranslation: "Щасливого Нового Року!", synonyms: [], difficulty: .a1),
        Word(id: "a1_065", original: "Monday", translation: "понеділок", transcription: "/ˈmʌndeɪ/", exampleSentence: "Monday is the first day.", exampleTranslation: "Понеділок — перший день.", synonyms: [], difficulty: .a1),
        Word(id: "a1_066", original: "Tuesday", translation: "вівторок", transcription: "/ˈtuːzdeɪ/", exampleSentence: "Tuesday comes after Monday.", exampleTranslation: "Вівторок йде після понеділка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_067", original: "Wednesday", translation: "середа", transcription: "/ˈwenzdeɪ/", exampleSentence: "Wednesday is in the middle.", exampleTranslation: "Середа посередині.", synonyms: [], difficulty: .a1),
        Word(id: "a1_068", original: "Thursday", translation: "четвер", transcription: "/ˈθɜːrzdeɪ/", exampleSentence: "Thursday is almost Friday.", exampleTranslation: "Четвер — майже п'ятниця.", synonyms: [], difficulty: .a1),
        Word(id: "a1_069", original: "Friday", translation: "п'ятниця", transcription: "/ˈfraɪdeɪ/", exampleSentence: "Friday is my favorite day.", exampleTranslation: "П'ятниця — мій улюблений день.", synonyms: [], difficulty: .a1),
        Word(id: "a1_070", original: "Saturday", translation: "субота", transcription: "/ˈsætərdeɪ/", exampleSentence: "Saturday is the weekend.", exampleTranslation: "Субота — вихідний.", synonyms: [], difficulty: .a1),
        Word(id: "a1_071", original: "Sunday", translation: "неділя", transcription: "/ˈsʌndeɪ/", exampleSentence: "Sunday is a day off.", exampleTranslation: "Неділя — вихідний день.", synonyms: [], difficulty: .a1),
        Word(id: "a1_072", original: "one", translation: "один", transcription: "/wʌn/", exampleSentence: "I have one apple.", exampleTranslation: "У мене одне яблуко.", synonyms: [], difficulty: .a1),
        Word(id: "a1_073", original: "two", translation: "два", transcription: "/tuː/", exampleSentence: "I have two cats.", exampleTranslation: "У мене два коти.", synonyms: [], difficulty: .a1),
        Word(id: "a1_074", original: "three", translation: "три", transcription: "/θriː/", exampleSentence: "Three little pigs.", exampleTranslation: "Три поросятка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_075", original: "four", translation: "чотири", transcription: "/fɔːr/", exampleSentence: "I see four birds.", exampleTranslation: "Я бачу чотири птахи.", synonyms: [], difficulty: .a1),
        Word(id: "a1_076", original: "five", translation: "п'ять", transcription: "/faɪv/", exampleSentence: "I am five years old.", exampleTranslation: "Мені п'ять років.", synonyms: [], difficulty: .a1),
        Word(id: "a1_077", original: "six", translation: "шість", transcription: "/sɪks/", exampleSentence: "Six eggs in the box.", exampleTranslation: "Шість яєць у коробці.", synonyms: [], difficulty: .a1),
        Word(id: "a1_078", original: "seven", translation: "сім", transcription: "/ˈsevn/", exampleSentence: "Seven days in a week.", exampleTranslation: "Сім днів у тижні.", synonyms: [], difficulty: .a1),
        Word(id: "a1_079", original: "eight", translation: "вісім", transcription: "/eɪt/", exampleSentence: "I sleep eight hours.", exampleTranslation: "Я сплю вісім годин.", synonyms: [], difficulty: .a1),
        Word(id: "a1_080", original: "nine", translation: "дев'ять", transcription: "/naɪn/", exampleSentence: "Nine lives of a cat.", exampleTranslation: "Дев'ять життів кота.", synonyms: [], difficulty: .a1),
        Word(id: "a1_081", original: "ten", translation: "десять", transcription: "/ten/", exampleSentence: "Count to ten.", exampleTranslation: "Порахуй до десяти.", synonyms: [], difficulty: .a1),
        Word(id: "a1_082", original: "big", translation: "великий", transcription: "/bɪɡ/", exampleSentence: "This is a big house.", exampleTranslation: "Це великий дім.", synonyms: ["large", "huge"], difficulty: .a1),
        Word(id: "a1_083", original: "small", translation: "маленький", transcription: "/smɔːl/", exampleSentence: "I have a small dog.", exampleTranslation: "У мене маленька собака.", synonyms: ["little", "tiny"], difficulty: .a1),
        Word(id: "a1_084", original: "good", translation: "добрий", transcription: "/ɡʊd/", exampleSentence: "You are a good person.", exampleTranslation: "Ти добра людина.", synonyms: ["nice", "kind"], difficulty: .a1),
        Word(id: "a1_085", original: "bad", translation: "поганий", transcription: "/bæd/", exampleSentence: "This is bad news.", exampleTranslation: "Це погані новини.", synonyms: ["awful"], difficulty: .a1),
        Word(id: "a1_086", original: "happy", translation: "щасливий", transcription: "/ˈhæpi/", exampleSentence: "I am very happy.", exampleTranslation: "Я дуже щасливий.", synonyms: ["glad", "joyful"], difficulty: .a1),
        Word(id: "a1_087", original: "sad", translation: "сумний", transcription: "/sæd/", exampleSentence: "Why are you sad?", exampleTranslation: "Чому ти сумний?", synonyms: ["unhappy"], difficulty: .a1),
        Word(id: "a1_088", original: "hot", translation: "гарячий", transcription: "/hɑːt/", exampleSentence: "The tea is hot.", exampleTranslation: "Чай гарячий.", synonyms: ["warm"], difficulty: .a1),
        Word(id: "a1_089", original: "cold", translation: "холодний", transcription: "/koʊld/", exampleSentence: "It is cold today.", exampleTranslation: "Сьогодні холодно.", synonyms: ["freezing"], difficulty: .a1),
        Word(id: "a1_090", original: "new", translation: "новий", transcription: "/nuː/", exampleSentence: "I have a new phone.", exampleTranslation: "У мене новий телефон.", synonyms: [], difficulty: .a1),
        Word(id: "a1_091", original: "old", translation: "старий", transcription: "/oʊld/", exampleSentence: "This is an old book.", exampleTranslation: "Це стара книга.", synonyms: [], difficulty: .a1),
        Word(id: "a1_092", original: "long", translation: "довгий", transcription: "/lɔːŋ/", exampleSentence: "Her hair is long.", exampleTranslation: "У неї довге волосся.", synonyms: [], difficulty: .a1),
        Word(id: "a1_093", original: "short", translation: "короткий", transcription: "/ʃɔːrt/", exampleSentence: "He is short.", exampleTranslation: "Він низький.", synonyms: [], difficulty: .a1),
        Word(id: "a1_094", original: "fast", translation: "швидкий", transcription: "/fæst/", exampleSentence: "The car is fast.", exampleTranslation: "Машина швидка.", synonyms: ["quick", "rapid"], difficulty: .a1),
        Word(id: "a1_095", original: "slow", translation: "повільний", transcription: "/sloʊ/", exampleSentence: "The turtle is slow.", exampleTranslation: "Черепаха повільна.", synonyms: [], difficulty: .a1),
        Word(id: "a1_096", original: "beautiful", translation: "красивий", transcription: "/ˈbjuːtɪfl/", exampleSentence: "You are beautiful.", exampleTranslation: "Ти красива.", synonyms: ["pretty", "lovely"], difficulty: .a1),
        Word(id: "a1_097", original: "ugly", translation: "потворний", transcription: "/ˈʌɡli/", exampleSentence: "The monster is ugly.", exampleTranslation: "Монстр потворний.", synonyms: [], difficulty: .a1),
        Word(id: "a1_098", original: "easy", translation: "легкий", transcription: "/ˈiːzi/", exampleSentence: "This test is easy.", exampleTranslation: "Цей тест легкий.", synonyms: ["simple"], difficulty: .a1),
        Word(id: "a1_099", original: "difficult", translation: "важкий", transcription: "/ˈdɪfɪkəlt/", exampleSentence: "Math is difficult.", exampleTranslation: "Математика важка.", synonyms: ["hard"], difficulty: .a1),
        Word(id: "a1_100", original: "love", translation: "любити", transcription: "/lʌv/", exampleSentence: "I love you.", exampleTranslation: "Я люблю тебе.", synonyms: ["adore"], difficulty: .a1),
        
        // Travel (50)
        Word(id: "a1_101", original: "airport", translation: "аеропорт", transcription: "/ˈerpɔːrt/", exampleSentence: "We meet at the airport.", exampleTranslation: "Зустрічаємось в аеропорту.", synonyms: [], difficulty: .a1),
        Word(id: "a1_102", original: "train", translation: "поїзд", transcription: "/treɪn/", exampleSentence: "I go by train.", exampleTranslation: "Я їду поїздом.", synonyms: [], difficulty: .a1),
        Word(id: "a1_103", original: "bus", translation: "автобус", transcription: "/bʌs/", exampleSentence: "The bus is late.", exampleTranslation: "Автобус запізнюється.", synonyms: [], difficulty: .a1),
        Word(id: "a1_104", original: "car", translation: "машина", transcription: "/kɑːr/", exampleSentence: "I have a red car.", exampleTranslation: "У мене червона машина.", synonyms: ["automobile"], difficulty: .a1),
        Word(id: "a1_105", original: "bike", translation: "велосипед", transcription: "/baɪk/", exampleSentence: "I ride a bike.", exampleTranslation: "Я їжджу на велосипеді.", synonyms: ["bicycle"], difficulty: .a1),
        Word(id: "a1_106", original: "ticket", translation: "квиток", transcription: "/ˈtɪkɪt/", exampleSentence: "I need a ticket.", exampleTranslation: "Мені потрібен квиток.", synonyms: [], difficulty: .a1),
        Word(id: "a1_107", original: "passport", translation: "паспорт", transcription: "/ˈpæspɔːrt/", exampleSentence: "Show your passport.", exampleTranslation: "Покажіть паспорт.", synonyms: [], difficulty: .a1),
        Word(id: "a1_108", original: "hotel", translation: "готель", transcription: "/hoʊˈtel/", exampleSentence: "We stay at a hotel.", exampleTranslation: "Ми зупиняємось в готелі.", synonyms: [], difficulty: .a1),
        Word(id: "a1_109", original: "city", translation: "місто", transcription: "/ˈsɪti/", exampleSentence: "London is a big city.", exampleTranslation: "Лондон — велике місто.", synonyms: ["town"], difficulty: .a1),
        Word(id: "a1_110", original: "street", translation: "вулиця", transcription: "/striːt/", exampleSentence: "I live on this street.", exampleTranslation: "Я живу на цій вулиці.", synonyms: [], difficulty: .a1),
        Word(id: "a1_111", original: "road", translation: "дорога", transcription: "/roʊd/", exampleSentence: "The road is long.", exampleTranslation: "Дорога довга.", synonyms: [], difficulty: .a1),
        Word(id: "a1_112", original: "bridge", translation: "міст", transcription: "/brɪdʒ/", exampleSentence: "There is a bridge.", exampleTranslation: "Там є міст.", synonyms: [], difficulty: .a1),
        Word(id: "a1_113", original: "river", translation: "річка", transcription: "/ˈrɪvər/", exampleSentence: "The river is wide.", exampleTranslation: "Річка широка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_114", original: "mountain", translation: "гора", transcription: "/ˈmaʊntən/", exampleSentence: "The mountain is high.", exampleTranslation: "Гора висока.", synonyms: [], difficulty: .a1),
        Word(id: "a1_115", original: "beach", translation: "пляж", transcription: "/biːtʃ/", exampleSentence: "We go to the beach.", exampleTranslation: "Ми йдемо на пляж.", synonyms: [], difficulty: .a1),
        Word(id: "a1_116", original: "sea", translation: "море", transcription: "/siː/", exampleSentence: "The sea is blue.", exampleTranslation: "Море синє.", synonyms: ["ocean"], difficulty: .a1),
        Word(id: "a1_117", original: "map", translation: "карта", transcription: "/mæp/", exampleSentence: "I need a map.", exampleTranslation: "Мені потрібна карта.", synonyms: [], difficulty: .a1),
        Word(id: "a1_118", original: "left", translation: "ліворуч", transcription: "/left/", exampleSentence: "Turn left.", exampleTranslation: "Поверніть ліворуч.", synonyms: [], difficulty: .a1),
        Word(id: "a1_119", original: "right", translation: "праворуч", transcription: "/raɪt/", exampleSentence: "Turn right.", exampleTranslation: "Поверніть праворуч.", synonyms: [], difficulty: .a1),
        Word(id: "a1_120", original: "straight", translation: "прямо", transcription: "/streɪt/", exampleSentence: "Go straight ahead.", exampleTranslation: "Йдіть прямо.", synonyms: [], difficulty: .a1),
        Word(id: "a1_121", original: "near", translation: "близько", transcription: "/nɪr/", exampleSentence: "The shop is near.", exampleTranslation: "Магазин близько.", synonyms: ["close"], difficulty: .a1),
        Word(id: "a1_122", original: "far", translation: "далеко", transcription: "/fɑːr/", exampleSentence: "It is far away.", exampleTranslation: "Це далеко.", synonyms: ["distant"], difficulty: .a1),
        Word(id: "a1_123", original: "here", translation: "тут", transcription: "/hɪr/", exampleSentence: "I am here.", exampleTranslation: "Я тут.", synonyms: [], difficulty: .a1),
        Word(id: "a1_124", original: "there", translation: "там", transcription: "/ðer/", exampleSentence: "He is there.", exampleTranslation: "Він там.", synonyms: [], difficulty: .a1),
        Word(id: "a1_125", original: "up", translation: "вгору", transcription: "/ʌp/", exampleSentence: "Go up the stairs.", exampleTranslation: "Йдіть вгору по сходах.", synonyms: [], difficulty: .a1),
        Word(id: "a1_126", original: "down", translation: "вниз", transcription: "/daʊn/", exampleSentence: "Go down, please.", exampleTranslation: "Йдіть вниз, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_127", original: "station", translation: "станція", transcription: "/ˈsteɪʃn/", exampleSentence: "Where is the station?", exampleTranslation: "Де станція?", synonyms: [], difficulty: .a1),
        Word(id: "a1_128", original: "stop", translation: "зупинка", transcription: "/stɑːp/", exampleSentence: "The bus stop is here.", exampleTranslation: "Автобусна зупинка тут.", synonyms: [], difficulty: .a1),
        Word(id: "a1_129", original: "taxi", translation: "таксі", transcription: "/ˈtæksi/", exampleSentence: "Call a taxi.", exampleTranslation: "Виклич таксі.", synonyms: ["cab"], difficulty: .a1),
        Word(id: "a1_130", original: "driver", translation: "водій", transcription: "/ˈdraɪvər/", exampleSentence: "The driver is nice.", exampleTranslation: "Водій милий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_131", original: "walk", translation: "йти пішки", transcription: "/wɔːk/", exampleSentence: "I walk to school.", exampleTranslation: "Я ходжу до школи пішки.", synonyms: [], difficulty: .a1),
        Word(id: "a1_132", original: "run", translation: "бігти", transcription: "/rʌn/", exampleSentence: "Don't run!", exampleTranslation: "Не біжи!", synonyms: [], difficulty: .a1),
        Word(id: "a1_133", original: "swim", translation: "плавати", transcription: "/swɪm/", exampleSentence: "I can swim.", exampleTranslation: "Я вмію плавати.", synonyms: [], difficulty: .a1),
        Word(id: "a1_134", original: "fly", translation: "літати", transcription: "/flaɪ/", exampleSentence: "Birds fly.", exampleTranslation: "Птахи літають.", synonyms: [], difficulty: .a1),
        Word(id: "a1_135", original: "drive", translation: "водити", transcription: "/draɪv/", exampleSentence: "I can drive.", exampleTranslation: "Я вмію водити.", synonyms: [], difficulty: .a1),
        Word(id: "a1_136", original: "travel", translation: "подорожувати", transcription: "/ˈtrævl/", exampleSentence: "I love to travel.", exampleTranslation: "Я люблю подорожувати.", synonyms: [], difficulty: .a1),
        Word(id: "a1_137", original: "visit", translation: "відвідувати", transcription: "/ˈvɪzɪt/", exampleSentence: "I visit my grandma.", exampleTranslation: "Я відвідую бабусю.", synonyms: [], difficulty: .a1),
        Word(id: "a1_138", original: "country", translation: "країна", transcription: "/ˈkʌntri/", exampleSentence: "Ukraine is my country.", exampleTranslation: "Україна — моя країна.", synonyms: ["nation"], difficulty: .a1),
        Word(id: "a1_139", original: "world", translation: "світ", transcription: "/wɜːrld/", exampleSentence: "The world is big.", exampleTranslation: "Світ великий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_140", original: "place", translation: "місце", transcription: "/pleɪs/", exampleSentence: "This is a nice place.", exampleTranslation: "Це гарне місце.", synonyms: ["location"], difficulty: .a1),
        Word(id: "a1_141", original: "restaurant", translation: "ресторан", transcription: "/ˈrestrɑːnt/", exampleSentence: "Let's go to a restaurant.", exampleTranslation: "Підемо в ресторан.", synonyms: [], difficulty: .a1),
        Word(id: "a1_142", original: "cafe", translation: "кафе", transcription: "/ˈkæfeɪ/", exampleSentence: "Meet me at the cafe.", exampleTranslation: "Зустрінь мене в кафе.", synonyms: [], difficulty: .a1),
        Word(id: "a1_143", original: "shop", translation: "магазин", transcription: "/ʃɑːp/", exampleSentence: "I go to the shop.", exampleTranslation: "Я йду в магазин.", synonyms: ["store"], difficulty: .a1),
        Word(id: "a1_144", original: "market", translation: "ринок", transcription: "/ˈmɑːrkɪt/", exampleSentence: "The market is busy.", exampleTranslation: "На ринку людно.", synonyms: [], difficulty: .a1),
        Word(id: "a1_145", original: "bank", translation: "банк", transcription: "/bæŋk/", exampleSentence: "I go to the bank.", exampleTranslation: "Я йду в банк.", synonyms: [], difficulty: .a1),
        Word(id: "a1_146", original: "hospital", translation: "лікарня", transcription: "/ˈhɑːspɪtl/", exampleSentence: "He is at the hospital.", exampleTranslation: "Він у лікарні.", synonyms: [], difficulty: .a1),
        Word(id: "a1_147", original: "pharmacy", translation: "аптека", transcription: "/ˈfɑːrməsi/", exampleSentence: "I need a pharmacy.", exampleTranslation: "Мені потрібна аптека.", synonyms: ["drugstore"], difficulty: .a1),
        Word(id: "a1_148", original: "police", translation: "поліція", transcription: "/pəˈliːs/", exampleSentence: "Call the police!", exampleTranslation: "Виклич поліцію!", synonyms: [], difficulty: .a1),
        Word(id: "a1_149", original: "post office", translation: "пошта", transcription: "/poʊst ˈɔːfɪs/", exampleSentence: "Where is the post office?", exampleTranslation: "Де пошта?", synonyms: [], difficulty: .a1),
        Word(id: "a1_150", original: "museum", translation: "музей", transcription: "/mjuˈziːəm/", exampleSentence: "The museum is closed.", exampleTranslation: "Музей зачинений.", synonyms: [], difficulty: .a1),
        
        // Work (50)
        Word(id: "a1_151", original: "work", translation: "робота", transcription: "/wɜːrk/", exampleSentence: "I go to work.", exampleTranslation: "Я йду на роботу.", synonyms: ["job"], difficulty: .a1),
        Word(id: "a1_152", original: "job", translation: "робота", transcription: "/dʒɑːb/", exampleSentence: "I have a good job.", exampleTranslation: "У мене хороша робота.", synonyms: ["work"], difficulty: .a1),
        Word(id: "a1_153", original: "office", translation: "офіс", transcription: "/ˈɔːfɪs/", exampleSentence: "I work in an office.", exampleTranslation: "Я працюю в офісі.", synonyms: [], difficulty: .a1),
        Word(id: "a1_154", original: "company", translation: "компанія", transcription: "/ˈkʌmpəni/", exampleSentence: "I work for a company.", exampleTranslation: "Я працюю в компанії.", synonyms: ["firm"], difficulty: .a1),
        Word(id: "a1_155", original: "boss", translation: "начальник", transcription: "/bɔːs/", exampleSentence: "My boss is strict.", exampleTranslation: "Мій начальник суворий.", synonyms: ["manager"], difficulty: .a1),
        Word(id: "a1_156", original: "colleague", translation: "колега", transcription: "/ˈkɑːliːɡ/", exampleSentence: "She is my colleague.", exampleTranslation: "Вона моя колега.", synonyms: ["coworker"], difficulty: .a1),
        Word(id: "a1_157", original: "meeting", translation: "зустріч", transcription: "/ˈmiːtɪŋ/", exampleSentence: "I have a meeting.", exampleTranslation: "У мене зустріч.", synonyms: [], difficulty: .a1),
        Word(id: "a1_158", original: "money", translation: "гроші", transcription: "/ˈmʌni/", exampleSentence: "I need money.", exampleTranslation: "Мені потрібні гроші.", synonyms: ["cash"], difficulty: .a1),
        Word(id: "a1_159", original: "price", translation: "ціна", transcription: "/praɪs/", exampleSentence: "What is the price?", exampleTranslation: "Яка ціна?", synonyms: ["cost"], difficulty: .a1),
        Word(id: "a1_160", original: "buy", translation: "купувати", transcription: "/baɪ/", exampleSentence: "I want to buy this.", exampleTranslation: "Я хочу це купити.", synonyms: ["purchase"], difficulty: .a1),
        Word(id: "a1_161", original: "sell", translation: "продавати", transcription: "/sel/", exampleSentence: "They sell books.", exampleTranslation: "Вони продають книги.", synonyms: [], difficulty: .a1),
        Word(id: "a1_162", original: "pay", translation: "платити", transcription: "/peɪ/", exampleSentence: "I pay by card.", exampleTranslation: "Я плачу карткою.", synonyms: [], difficulty: .a1),
        Word(id: "a1_163", original: "cheap", translation: "дешевий", transcription: "/tʃiːp/", exampleSentence: "This is cheap.", exampleTranslation: "Це дешево.", synonyms: ["inexpensive"], difficulty: .a1),
        Word(id: "a1_164", original: "expensive", translation: "дорогий", transcription: "/ɪkˈspensɪv/", exampleSentence: "This is expensive.", exampleTranslation: "Це дорого.", synonyms: ["costly"], difficulty: .a1),
        Word(id: "a1_165", original: "free", translation: "безкоштовно", transcription: "/friː/", exampleSentence: "It's free!", exampleTranslation: "Це безкоштовно!", synonyms: [], difficulty: .a1),
        Word(id: "a1_166", original: "open", translation: "відкрити", transcription: "/ˈoʊpən/", exampleSentence: "Open the door.", exampleTranslation: "Відкрий двері.", synonyms: [], difficulty: .a1),
        Word(id: "a1_167", original: "close", translation: "закрити", transcription: "/kloʊz/", exampleSentence: "Close the window.", exampleTranslation: "Закрий вікно.", synonyms: ["shut"], difficulty: .a1),
        Word(id: "a1_168", original: "start", translation: "почати", transcription: "/stɑːrt/", exampleSentence: "Let's start!", exampleTranslation: "Почнімо!", synonyms: ["begin"], difficulty: .a1),
        Word(id: "a1_169", original: "finish", translation: "закінчити", transcription: "/ˈfɪnɪʃ/", exampleSentence: "I finish at 5.", exampleTranslation: "Я закінчую о 5.", synonyms: ["end"], difficulty: .a1),
        Word(id: "a1_170", original: "help", translation: "допомога", transcription: "/help/", exampleSentence: "I need help.", exampleTranslation: "Мені потрібна допомога.", synonyms: ["aid"], difficulty: .a1),
        Word(id: "a1_171", original: "problem", translation: "проблема", transcription: "/ˈprɑːbləm/", exampleSentence: "No problem!", exampleTranslation: "Без проблем!", synonyms: ["issue"], difficulty: .a1),
        Word(id: "a1_172", original: "answer", translation: "відповідь", transcription: "/ˈænsər/", exampleSentence: "What is the answer?", exampleTranslation: "Яка відповідь?", synonyms: ["reply"], difficulty: .a1),
        Word(id: "a1_173", original: "question", translation: "питання", transcription: "/ˈkwestʃən/", exampleSentence: "I have a question.", exampleTranslation: "У мене питання.", synonyms: ["query"], difficulty: .a1),
        Word(id: "a1_174", original: "idea", translation: "ідея", transcription: "/aɪˈdɪə/", exampleSentence: "Good idea!", exampleTranslation: "Хороша ідея!", synonyms: ["thought"], difficulty: .a1),
        Word(id: "a1_175", original: "plan", translation: "план", transcription: "/plæn/", exampleSentence: "What's your plan?", exampleTranslation: "Який твій план?", synonyms: [], difficulty: .a1),
        Word(id: "a1_176", original: "project", translation: "проект", transcription: "/ˈprɑːdʒekt/", exampleSentence: "We have a new project.", exampleTranslation: "У нас новий проект.", synonyms: [], difficulty: .a1),
        Word(id: "a1_177", original: "report", translation: "звіт", transcription: "/rɪˈpɔːrt/", exampleSentence: "I write a report.", exampleTranslation: "Я пишу звіт.", synonyms: [], difficulty: .a1),
        Word(id: "a1_178", original: "email", translation: "email", transcription: "/ˈiːmeɪl/", exampleSentence: "Send me an email.", exampleTranslation: "Надішли мені email.", synonyms: [], difficulty: .a1),
        Word(id: "a1_179", original: "letter", translation: "лист", transcription: "/ˈletər/", exampleSentence: "I got a letter.", exampleTranslation: "Я отримав лист.", synonyms: [], difficulty: .a1),
        Word(id: "a1_180", original: "message", translation: "повідомлення", transcription: "/ˈmesɪdʒ/", exampleSentence: "I sent a message.", exampleTranslation: "Я надіслав повідомлення.", synonyms: [], difficulty: .a1),
        Word(id: "a1_181", original: "call", translation: "дзвінок", transcription: "/kɔːl/", exampleSentence: "I got a call.", exampleTranslation: "Мені подзвонили.", synonyms: ["phone call"], difficulty: .a1),
        Word(id: "a1_182", original: "number", translation: "номер", transcription: "/ˈnʌmbər/", exampleSentence: "What is your number?", exampleTranslation: "Який твій номер?", synonyms: [], difficulty: .a1),
        Word(id: "a1_183", original: "zero", translation: "нуль", transcription: "/ˈzɪəroʊ/", exampleSentence: "It's zero degrees.", exampleTranslation: "Нуль градусів.", synonyms: [], difficulty: .a1),
        Word(id: "a1_184", original: "hundred", translation: "сто", transcription: "/ˈhʌndrəd/", exampleSentence: "One hundred people.", exampleTranslation: "Сто людей.", synonyms: [], difficulty: .a1),
        Word(id: "a1_185", original: "thousand", translation: "тисяча", transcription: "/ˈθaʊznd/", exampleSentence: "One thousand dollars.", exampleTranslation: "Тисяча доларів.", synonyms: [], difficulty: .a1),
        Word(id: "a1_186", original: "million", translation: "мільйон", transcription: "/ˈmɪljən/", exampleSentence: "One million people.", exampleTranslation: "Мільйон людей.", synonyms: [], difficulty: .a1),
        Word(id: "a1_187", original: "dollar", translation: "долар", transcription: "/ˈdɑːlər/", exampleSentence: "It costs five dollars.", exampleTranslation: "Це коштує п'ять доларів.", synonyms: [], difficulty: .a1),
        Word(id: "a1_188", original: "euro", translation: "євро", transcription: "/ˈjʊroʊ/", exampleSentence: "Ten euros, please.", exampleTranslation: "Десять євро, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_189", original: "pound", translation: "фунт", transcription: "/paʊnd/", exampleSentence: "One pound of apples.", exampleTranslation: "Фунт яблук.", synonyms: [], difficulty: .a1),
        Word(id: "a1_190", original: "hour", translation: "година", transcription: "/ˈaʊər/", exampleSentence: "I work eight hours.", exampleTranslation: "Я працюю вісім годин.", synonyms: [], difficulty: .a1),
        Word(id: "a1_191", original: "minute", translation: "хвилина", transcription: "/ˈmɪnɪt/", exampleSentence: "Wait a minute.", exampleTranslation: "Зачекай хвилину.", synonyms: [], difficulty: .a1),
        Word(id: "a1_192", original: "second", translation: "секунда", transcription: "/ˈsekənd/", exampleSentence: "One second, please.", exampleTranslation: "Секундочку, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_193", original: "half", translation: "половина", transcription: "/hæf/", exampleSentence: "Half an hour.", exampleTranslation: "Півгодини.", synonyms: [], difficulty: .a1),
        Word(id: "a1_194", original: "quarter", translation: "чверть", transcription: "/ˈkwɔːrtər/", exampleSentence: "A quarter past three.", exampleTranslation: "Чверть по третій.", synonyms: [], difficulty: .a1),
        Word(id: "a1_195", original: "early", translation: "рано", transcription: "/ˈɜːrli/", exampleSentence: "I wake up early.", exampleTranslation: "Я прокидаюсь рано.", synonyms: [], difficulty: .a1),
        Word(id: "a1_196", original: "late", translation: "пізно", transcription: "/leɪt/", exampleSentence: "Don't be late!", exampleTranslation: "Не запізнюйся!", synonyms: [], difficulty: .a1),
        Word(id: "a1_197", original: "now", translation: "зараз", transcription: "/naʊ/", exampleSentence: "I am busy now.", exampleTranslation: "Я зараз зайнятий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_198", original: "later", translation: "пізніше", transcription: "/ˈleɪtər/", exampleSentence: "See you later!", exampleTranslation: "Побачимось пізніше!", synonyms: [], difficulty: .a1),
        Word(id: "a1_199", original: "soon", translation: "скоро", transcription: "/suːn/", exampleSentence: "I will come soon.", exampleTranslation: "Я прийду скоро.", synonyms: [], difficulty: .a1),
        Word(id: "a1_200", original: "always", translation: "завжди", transcription: "/ˈɔːlweɪz/", exampleSentence: "I always smile.", exampleTranslation: "Я завжди посміхаюсь.", synonyms: [], difficulty: .a1),
        
        // Emotions & Descriptions (100)
        Word(id: "a1_201", original: "angry", translation: "злий", transcription: "/ˈæŋɡri/", exampleSentence: "Don't be angry.", exampleTranslation: "Не сердься.", synonyms: ["mad"], difficulty: .a1),
        Word(id: "a1_202", original: "afraid", translation: "наляканий", transcription: "/əˈfreɪd/", exampleSentence: "I am afraid.", exampleTranslation: "Я боюсь.", synonyms: ["scared"], difficulty: .a1),
        Word(id: "a1_203", original: "tired", translation: "втомлений", transcription: "/ˈtaɪərd/", exampleSentence: "I am very tired.", exampleTranslation: "Я дуже втомлений.", synonyms: ["exhausted"], difficulty: .a1),
        Word(id: "a1_204", original: "hungry", translation: "голодний", transcription: "/ˈhʌŋɡri/", exampleSentence: "I am hungry.", exampleTranslation: "Я голодний.", synonyms: [], difficulty: .a1),
        Word(id: "a1_205", original: "thirsty", translation: "спраглий", transcription: "/ˈθɜːrsti/", exampleSentence: "I am thirsty.", exampleTranslation: "Я хочу пити.", synonyms: [], difficulty: .a1),
        Word(id: "a1_206", original: "sick", translation: "хворий", transcription: "/sɪk/", exampleSentence: "I feel sick.", exampleTranslation: "Я почуваюсь погано.", synonyms: ["ill"], difficulty: .a1),
        Word(id: "a1_207", original: "healthy", translation: "здоровий", transcription: "/ˈhelθi/", exampleSentence: "I am healthy.", exampleTranslation: "Я здоровий.", synonyms: [], difficulty: .a1),
        Word(id: "a1_208", original: "strong", translation: "сильний", transcription: "/strɔːŋ/", exampleSentence: "He is strong.", exampleTranslation: "Він сильний.", synonyms: ["powerful"], difficulty: .a1),
        Word(id: "a1_209", original: "weak", translation: "слабкий", transcription: "/wiːk/", exampleSentence: "I feel weak.", exampleTranslation: "Я почуваюсь слабким.", synonyms: ["feeble"], difficulty: .a1),
        Word(id: "a1_210", original: "busy", translation: "зайнятий", transcription: "/ˈbɪzi/", exampleSentence: "I am busy today.", exampleTranslation: "Я сьогодні зайнятий.", synonyms: ["occupied"], difficulty: .a1),
        Word(id: "a1_211", original: "free", translation: "вільний", transcription: "/friː/", exampleSentence: "Are you free?", exampleTranslation: "Ти вільний?", synonyms: ["available"], difficulty: .a1),
        Word(id: "a1_212", original: "ready", translation: "готовий", transcription: "/ˈredi/", exampleSentence: "I am ready.", exampleTranslation: "Я готовий.", synonyms: ["prepared"], difficulty: .a1),
        Word(id: "a1_213", original: "sure", translation: "впевнений", transcription: "/ʃʊr/", exampleSentence: "Are you sure?", exampleTranslation: "Ти впевнений?", synonyms: ["certain"], difficulty: .a1),
        Word(id: "a1_214", original: "right", translation: "правильний", transcription: "/raɪt/", exampleSentence: "You are right.", exampleTranslation: "Ти правий.", synonyms: ["correct"], difficulty: .a1),
        Word(id: "a1_215", original: "wrong", translation: "неправильний", transcription: "/rɔːŋ/", exampleSentence: "This is wrong.", exampleTranslation: "Це неправильно.", synonyms: ["incorrect"], difficulty: .a1),
        Word(id: "a1_216", original: "true", translation: "правда", transcription: "/truː/", exampleSentence: "Is it true?", exampleTranslation: "Це правда?", synonyms: [], difficulty: .a1),
        Word(id: "a1_217", original: "false", translation: "брехня", transcription: "/fɔːls/", exampleSentence: "This is false.", exampleTranslation: "Це брехня.", synonyms: ["untrue"], difficulty: .a1),
        Word(id: "a1_218", original: "possible", translation: "можливо", transcription: "/ˈpɑːsəbl/", exampleSentence: "Is it possible?", exampleTranslation: "Це можливо?", synonyms: [], difficulty: .a1),
        Word(id: "a1_219", original: "impossible", translation: "неможливо", transcription: "/ɪmˈpɑːsəbl/", exampleSentence: "This is impossible.", exampleTranslation: "Це неможливо.", synonyms: [], difficulty: .a1),
        Word(id: "a1_220", original: "same", translation: "такий самий", transcription: "/seɪm/", exampleSentence: "We are the same.", exampleTranslation: "Ми однакові.", synonyms: ["identical"], difficulty: .a1),
        Word(id: "a1_221", original: "different", translation: "інший", transcription: "/ˈdɪfrənt/", exampleSentence: "We are different.", exampleTranslation: "Ми різні.", synonyms: [], difficulty: .a1),
        Word(id: "a1_222", original: "important", translation: "важливий", transcription: "/ɪmˈpɔːrtnt/", exampleSentence: "This is important.", exampleTranslation: "Це важливо.", synonyms: ["significant"], difficulty: .a1),
        Word(id: "a1_223", original: "interesting", translation: "цікавий", transcription: "/ˈɪntrəstɪŋ/", exampleSentence: "This is interesting.", exampleTranslation: "Це цікаво.", synonyms: [], difficulty: .a1),
        Word(id: "a1_224", original: "boring", translation: "нудний", transcription: "/ˈbɔːrɪŋ/", exampleSentence: "This is boring.", exampleTranslation: "Це нудно.", synonyms: ["dull"], difficulty: .a1),
        Word(id: "a1_225", original: "fun", translation: "весело", transcription: "/fʌn/", exampleSentence: "This is fun!", exampleTranslation: "Це весело!", synonyms: ["enjoyable"], difficulty: .a1),
        Word(id: "a1_226", original: "funny", translation: "смішний", transcription: "/ˈfʌni/", exampleSentence: "You are funny!", exampleTranslation: "Ти смішний!", synonyms: ["humorous"], difficulty: .a1),
        Word(id: "a1_227", original: "serious", translation: "серйозний", transcription: "/ˈsɪriəs/", exampleSentence: "Be serious!", exampleTranslation: "Будь серйозним!", synonyms: [], difficulty: .a1),
        Word(id: "a1_228", original: "kind", translation: "добрий", transcription: "/kaɪnd/", exampleSentence: "You are so kind.", exampleTranslation: "Ти такий добрий.", synonyms: ["nice"], difficulty: .a1),
        Word(id: "a1_229", original: "clever", translation: "розумний", transcription: "/ˈklevər/", exampleSentence: "You are clever.", exampleTranslation: "Ти розумний.", synonyms: ["smart", "intelligent"], difficulty: .a1),
        Word(id: "a1_230", original: "stupid", translation: "дурний", transcription: "/ˈstuːpɪd/", exampleSentence: "Don't be stupid.", exampleTranslation: "Не будь дурним.", synonyms: ["foolish"], difficulty: .a1),
        Word(id: "a1_231", original: "rich", translation: "багатий", transcription: "/rɪtʃ/", exampleSentence: "He is rich.", exampleTranslation: "Він багатий.", synonyms: ["wealthy"], difficulty: .a1),
        Word(id: "a1_232", original: "poor", translation: "бідний", transcription: "/pʊr/", exampleSentence: "He is poor.", exampleTranslation: "Він бідний.", synonyms: [], difficulty: .a1),
        Word(id: "a1_233", original: "clean", translation: "чистий", transcription: "/kliːn/", exampleSentence: "The room is clean.", exampleTranslation: "Кімната чиста.", synonyms: ["tidy"], difficulty: .a1),
        Word(id: "a1_234", original: "dirty", translation: "брудний", transcription: "/ˈdɜːrti/", exampleSentence: "The shoes are dirty.", exampleTranslation: "Взуття брудне.", synonyms: [], difficulty: .a1),
        Word(id: "a1_235", original: "empty", translation: "порожній", transcription: "/ˈempti/", exampleSentence: "The glass is empty.", exampleTranslation: "Склянка порожня.", synonyms: [], difficulty: .a1),
        Word(id: "a1_236", original: "full", translation: "повний", transcription: "/fʊl/", exampleSentence: "The bus is full.", exampleTranslation: "Автобус повний.", synonyms: [], difficulty: .a1),
        Word(id: "a1_237", original: "quiet", translation: "тихий", transcription: "/ˈkwaɪət/", exampleSentence: "Be quiet!", exampleTranslation: "Тиша!", synonyms: ["silent"], difficulty: .a1),
        Word(id: "a1_238", original: "loud", translation: "гучний", transcription: "/laʊd/", exampleSentence: "Don't be loud.", exampleTranslation: "Не шуміть.", synonyms: ["noisy"], difficulty: .a1),
        Word(id: "a1_239", original: "safe", translation: "безпечний", transcription: "/seɪf/", exampleSentence: "You are safe.", exampleTranslation: "Ти в безпеці.", synonyms: ["secure"], difficulty: .a1),
        Word(id: "a1_240", original: "dangerous", translation: "небезпечний", transcription: "/ˈdeɪndʒərəs/", exampleSentence: "This is dangerous.", exampleTranslation: "Це небезпечно.", synonyms: ["risky"], difficulty: .a1),
        Word(id: "a1_241", original: "alone", translation: "самотній", transcription: "/əˈloʊn/", exampleSentence: "I am alone.", exampleTranslation: "Я сам.", synonyms: [], difficulty: .a1),
        Word(id: "a1_242", original: "together", translation: "разом", transcription: "/təˈɡeðər/", exampleSentence: "We are together.", exampleTranslation: "Ми разом.", synonyms: [], difficulty: .a1),
        Word(id: "a1_243", original: "early", translation: "ранній", transcription: "/ˈɜːrli/", exampleSentence: "The early bird.", exampleTranslation: "Рання пташка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_244", original: "late", translation: "пізній", transcription: "/leɪt/", exampleSentence: "I am late.", exampleTranslation: "Я запізнився.", synonyms: [], difficulty: .a1),
        Word(id: "a1_245", original: "first", translation: "перший", transcription: "/fɜːrst/", exampleSentence: "I am first.", exampleTranslation: "Я перший.", synonyms: [], difficulty: .a1),
        Word(id: "a1_246", original: "last", translation: "останній", transcription: "/læst/", exampleSentence: "I am last.", exampleTranslation: "Я останній.", synonyms: ["final"], difficulty: .a1),
        Word(id: "a1_247", original: "next", translation: "наступний", transcription: "/nekst/", exampleSentence: "Next, please.", exampleTranslation: "Наступний, будь ласка.", synonyms: [], difficulty: .a1),
        Word(id: "a1_248", original: "other", translation: "інший", transcription: "/ˈʌðər/", exampleSentence: "The other day.", exampleTranslation: "Іншого дня.", synonyms: ["another"], difficulty: .a1),
        Word(id: "a1_249", original: "each", translation: "кожен", transcription: "/iːtʃ/", exampleSentence: "Each student.", exampleTranslation: "Кожен учень.", synonyms: ["every"], difficulty: .a1),
        Word(id: "a1_250", original: "every", translation: "кожен", transcription: "/ˈevri/", exampleSentence: "Every day.", exampleTranslation: "Кожен день.", synonyms: ["each"], difficulty: .a1),
        Word(id: "a1_251", original: "all", translation: "всі", transcription: "/ɔːl/", exampleSentence: "All people.", exampleTranslation: "Всі люди.", synonyms: ["everyone"], difficulty: .a1),
        Word(id: "a1_252", original: "some", translation: "деякі", transcription: "/sʌm/", exampleSentence: "Some people.", exampleTranslation: "Деякі люди.", synonyms: [], difficulty: .a1),
        Word(id: "a1_253", original: "any", translation: "будь-який", transcription: "/ˈeni/", exampleSentence: "Do you have any?", exampleTranslation: "У тебе є якісь?", synonyms: [], difficulty: .a1),
        Word(id: "a1_254", original: "many", translation: "багато", transcription: "/ˈmeni/", exampleSentence: "Many people.", exampleTranslation: "Багато людей.", synonyms: ["lots of"], difficulty: .a1),
        Word(id: "a1_255", original: "much", translation: "багато", transcription: "/mʌtʃ/", exampleSentence: "How much?", exampleTranslation: "Скільки?", synonyms: [], difficulty: .a1),
        Word(id: "a1_256", original: "more", translation: "більше", transcription: "/mɔːr/", exampleSentence: "I want more.", exampleTranslation: "Я хочу більше.", synonyms: [], difficulty: .a1),
        Word(id: "a1_257", original: "most", translation: "більшість", transcription: "/moʊst/", exampleSentence: "Most people.", exampleTranslation: "Більшість людей.", synonyms: [], difficulty: .a1),
        Word(id: "a1_258", original: "few", translation: "мало", transcription: "/fjuː/", exampleSentence: "Few people.", exampleTranslation: "Мало людей.", synonyms: [], difficulty: .a1),
        Word(id: "a1_259", original: "little", translation: "трохи", transcription: "/ˈlɪtl/", exampleSentence: "A little water.", exampleTranslation: "Трохи води.", synonyms: [], difficulty: .a1),
        Word(id: "a1_260", original: "own", translation: "власний", transcription: "/oʊn/", exampleSentence: "My own car.", exampleTranslation: "Моя власна машина.", synonyms: [], difficulty: .a1),
        Word(id: "a1_261", original: "main", translation: "головний", transcription: "/meɪn/", exampleSentence: "The main idea.", exampleTranslation: "Головна ідея.", synonyms: ["primary"], difficulty: .a1),
        Word(id: "a1_262", original: "enough", translation: "достатньо", transcription: "/ɪˈnʌf/", exampleSentence: "That's enough.", exampleTranslation: "Цього достатньо.", synonyms: ["sufficient"], difficulty: .a1),
        Word(id: "a1_263", original: "quite", translation: "досить", transcription: "/kwaɪt/", exampleSentence: "It's quite good.", exampleTranslation: "Це досить добре.", synonyms: ["rather"], difficulty: .a1),
        Word(id: "a1_264", original: "very", translation: "дуже", transcription: "/ˈveri/", exampleSentence: "Very good!", exampleTranslation: "Дуже добре!", synonyms: ["really"], difficulty: .a1),
        Word(id: "a1_265", original: "too", translation: "також", transcription: "/tuː/", exampleSentence: "I like it too.", exampleTranslation: "Мені теж подобається.", synonyms: ["also"], difficulty: .a1),
        Word(id: "a1_266", original: "also", translation: "також", transcription: "/ˈɔːlsoʊ/", exampleSentence: "I also agree.", exampleTranslation: "Я також згоден.", synonyms: ["too"], difficulty: .a1),
        Word(id: "a1_267", original: "only", translation: "тільки", transcription: "/ˈoʊnli/", exampleSentence: "Only one.", exampleTranslation: "Тільки один.", synonyms: ["just"], difficulty: .a1),
        Word(id: "a1_268", original: "just", translation: "просто", transcription: "/dʒʌst/", exampleSentence: "Just a minute.", exampleTranslation: "Хвилинку.", synonyms: ["only"], difficulty: .a1),
        Word(id: "a1_269", original: "even", translation: "навіть", transcription: "/ˈiːvn/", exampleSentence: "Even better.", exampleTranslation: "Навіть краще.", synonyms: [], difficulty: .a1),
        Word(id: "a1_270", original: "still", translation: "все ще", transcription: "/stɪl/", exampleSentence: "I still love you.", exampleTranslation: "Я все ще люблю тебе.", synonyms: ["yet"], difficulty: .a1),
        Word(id: "a1_271", original: "already", translation: "вже", transcription: "/ɔːlˈredi/", exampleSentence: "I already know.", exampleTranslation: "Я вже знаю.", synonyms: [], difficulty: .a1),
        Word(id: "a1_272", original: "yet", translation: "ще", transcription: "/jet/", exampleSentence: "Not yet.", exampleTranslation: "Ще ні.", synonyms: ["still"], difficulty: .a1),
        Word(id: "a1_273", original: "again", translation: "знову", transcription: "/əˈɡen/", exampleSentence: "Say it again.", exampleTranslation: "Скажи це знову.", synonyms: ["once more"], difficulty: .a1),
        Word(id: "a1_274", original: "back", translation: "назад", transcription: "/bæk/", exampleSentence: "Come back!", exampleTranslation: "Повертайся!", synonyms: ["return"], difficulty: .a1),
        Word(id: "a1_275", original: "away", translation: "геть", transcription: "/əˈweɪ/", exampleSentence: "Go away!", exampleTranslation: "Йди геть!", synonyms: [], difficulty: .a1),
        Word(id: "a1_276", original: "out", translation: "назовні", transcription: "/aʊt/", exampleSentence: "Go out.", exampleTranslation: "Вийди.", synonyms: ["outside"], difficulty: .a1),
        Word(id: "a1_277", original: "inside", translation: "всередині", transcription: "/ˌɪnˈsaɪd/", exampleSentence: "Stay inside.", exampleTranslation: "Залишайся всередині.", synonyms: [], difficulty: .a1),
        Word(id: "a1_278", original: "outside", translation: "зовні", transcription: "/ˌaʊtˈsaɪd/", exampleSentence: "It's cold outside.", exampleTranslation: "Зовні холодно.", synonyms: [], difficulty: .a1),
        Word(id: "a1_279", original: "above", translation: "над", transcription: "/əˈbʌv/", exampleSentence: "The sky above.", exampleTranslation: "Небо над.", synonyms: ["over"], difficulty: .a1),
        Word(id: "a1_280", original: "below", translation: "під", transcription: "/bɪˈloʊ/", exampleSentence: "See below.", exampleTranslation: "Дивись нижче.", synonyms: ["under"], difficulty: .a1),
        Word(id: "a1_281", original: "between", translation: "між", transcription: "/bɪˈtwiːn/", exampleSentence: "Between us.", exampleTranslation: "Між нами.", synonyms: [], difficulty: .a1),
        Word(id: "a1_282", original: "behind", translation: "позаду", transcription: "/bɪˈhaɪnd/", exampleSentence: "Behind the door.", exampleTranslation: "За дверима.", synonyms: [], difficulty: .a1),
        Word(id: "a1_283", original: "in front of", translation: "перед", transcription: "/ɪn frʌnt ʌv/", exampleSentence: "In front of me.", exampleTranslation: "Передо мною.", synonyms: [], difficulty: .a1),
        Word(id: "a1_284", original: "next to", translation: "поруч з", transcription: "/nekst tuː/", exampleSentence: "Sit next to me.", exampleTranslation: "Сядь поруч зі мною.", synonyms: ["beside"], difficulty: .a1),
        Word(id: "a1_285", original: "across", translation: "через", transcription: "/əˈkrɔːs/", exampleSentence: "Walk across.", exampleTranslation: "Йди через.", synonyms: [], difficulty: .a1),
        Word(id: "a1_286", original: "through", translation: "крізь", transcription: "/θruː/", exampleSentence: "Go through.", exampleTranslation: "Пройди крізь.", synonyms: [], difficulty: .a1),
        Word(id: "a1_287", original: "around", translation: "навколо", transcription: "/əˈraʊnd/", exampleSentence: "Look around.", exampleTranslation: "Подивись навколо.", synonyms: [], difficulty: .a1),
        Word(id: "a1_288", original: "into", translation: "в", transcription: "/ˈɪntuː/", exampleSentence: "Go into the room.", exampleTranslation: "Зайди в кімнату.", synonyms: [], difficulty: .a1),
        Word(id: "a1_289", original: "from", translation: "від", transcription: "/frʌm/", exampleSentence: "I am from Ukraine.", exampleTranslation: "Я з України.", synonyms: [], difficulty: .a1),
        Word(id: "a1_290", original: "to", translation: "до", transcription: "/tuː/", exampleSentence: "Go to school.", exampleTranslation: "Йди до школи.", synonyms: [], difficulty: .a1),
        Word(id: "a1_291", original: "with", translation: "з", transcription: "/wɪð/", exampleSentence: "Come with me.", exampleTranslation: "Йди зі мною.", synonyms: [], difficulty: .a1),
        Word(id: "a1_292", original: "without", translation: "без", transcription: "/wɪˈðaʊt/", exampleSentence: "Without you.", exampleTranslation: "Без тебе.", synonyms: [], difficulty: .a1),
        Word(id: "a1_293", original: "for", translation: "для", transcription: "/fɔːr/", exampleSentence: "This is for you.", exampleTranslation: "Це для тебе.", synonyms: [], difficulty: .a1),
        Word(id: "a1_294", original: "about", translation: "про", transcription: "/əˈbaʊt/", exampleSentence: "Tell me about it.", exampleTranslation: "Розкажи мені про це.", synonyms: [], difficulty: .a1),
        Word(id: "a1_295", original: "like", translation: "подобатися", transcription: "/laɪk/", exampleSentence: "I like it.", exampleTranslation: "Мені подобається.", synonyms: ["enjoy"], difficulty: .a1),
        Word(id: "a1_296", original: "want", translation: "хотіти", transcription: "/wɑːnt/", exampleSentence: "I want water.", exampleTranslation: "Я хочу води.", synonyms: ["desire"], difficulty: .a1),
        Word(id: "a1_297", original: "need", translation: "потребувати", transcription: "/niːd/", exampleSentence: "I need help.", exampleTranslation: "Мені потрібна допомога.", synonyms: ["require"], difficulty: .a1),
        Word(id: "a1_298", original: "have", translation: "мати", transcription: "/hæv/", exampleSentence: "I have a cat.", exampleTranslation: "У мене є кіт.", synonyms: ["possess"], difficulty: .a1),
        Word(id: "a1_299", original: "know", translation: "знати", transcription: "/noʊ/", exampleSentence: "I know you.", exampleTranslation: "Я знаю тебе.", synonyms: [], difficulty: .a1),
        Word(id: "a1_300", original: "think", translation: "думати", transcription: "/θɪŋk/", exampleSentence: "I think so.", exampleTranslation: "Я так думаю.", synonyms: ["believe"], difficulty: .a1),
    ]
    
    // A2 — 320 слів
    static let a2Words: [Word] = [
        Word(id: "a2_001", original: "ability", translation: "здатність", transcription: "/əˈbɪləti/", exampleSentence: "She has the ability to learn quickly.", exampleTranslation: "Вона має здатність швидко вчитися.", synonyms: ["skill", "talent"], difficulty: .a2),
        Word(id: "a2_002", original: "absolutely", translation: "абсолютно", transcription: "/ˈæbsəluːtli/", exampleSentence: "I absolutely agree with you.", exampleTranslation: "Я абсолютно згоден з тобою.", synonyms: ["completely", "totally"], difficulty: .a2),
        Word(id: "a2_003", original: "accept", translation: "приймати", transcription: "/əkˈsept/", exampleSentence: "I accept your apology.", exampleTranslation: "Я приймаю твої вибачення.", synonyms: ["agree to", "approve"], difficulty: .a2),
        Word(id: "a2_004", original: "accident", translation: "нещасний випадок", transcription: "/ˈæksɪdənt/", exampleSentence: "There was a car accident.", exampleTranslation: "Сталася автомобільна аварія.", synonyms: ["crash", "mishap"], difficulty: .a2),
        Word(id: "a2_005", original: "achieve", translation: "досягати", transcription: "/əˈtʃiːv/", exampleSentence: "You can achieve your goals.", exampleTranslation: "Ти можеш досягти своїх цілей.", synonyms: ["accomplish", "reach"], difficulty: .a2),
        Word(id: "a2_006", original: "activity", translation: "діяльність", transcription: "/ækˈtɪvəti/", exampleSentence: "What is your favorite activity?", exampleTranslation: "Яка твоя улюблена діяльність?", synonyms: ["pastime", "hobby"], difficulty: .a2),
        Word(id: "a2_007", original: "actually", translation: "насправді", transcription: "/ˈæktʃuəli/", exampleSentence: "Actually, I don't know.", exampleTranslation: "Насправді, я не знаю.", synonyms: ["in fact", "really"], difficulty: .a2),
        Word(id: "a2_008", original: "advantage", translation: "перевага", transcription: "/ədˈvæntɪdʒ/", exampleSentence: "This gives us an advantage.", exampleTranslation: "Це дає нам перевагу.", synonyms: ["benefit", "edge"], difficulty: .a2),
        Word(id: "a2_009", original: "adventure", translation: "пригода", transcription: "/ədˈventʃər/", exampleSentence: "Life is either a daring adventure or nothing.", exampleTranslation: "Життя — це або смілива пригода, або ніщо.", synonyms: ["expedition", "journey"], difficulty: .a2),
        Word(id: "a2_010", original: "advertise", translation: "рекламувати", transcription: "/ˈædvərtaɪz/", exampleSentence: "They advertise on TV.", exampleTranslation: "Вони рекламують по телевізору.", synonyms: ["promote", "market"], difficulty: .a2),
        Word(id: "a2_011", original: "advice", translation: "порада", transcription: "/ədˈvaɪs/", exampleSentence: "Can you give me some advice?", exampleTranslation: "Чи можеш дати мені пораду?", synonyms: ["suggestion", "tip"], difficulty: .a2),
        Word(id: "a2_012", original: "affect", translation: "впливати", transcription: "/əˈfekt/", exampleSentence: "This will affect our plans.", exampleTranslation: "Це вплине на наші плани.", synonyms: ["influence", "impact"], difficulty: .a2),
        Word(id: "a2_013", original: "afraid", translation: "боятися", transcription: "/əˈfreɪd/", exampleSentence: "I'm afraid of heights.", exampleTranslation: "Я боюся висоти.", synonyms: ["scared", "frightened"], difficulty: .a2),
        Word(id: "a2_014", original: "against", translation: "проти", transcription: "/əˈɡenst/", exampleSentence: "I'm against this idea.", exampleTranslation: "Я проти цієї ідеї.", synonyms: ["opposed to"], difficulty: .a2),
        Word(id: "a2_015", original: "agreement", translation: "угода", transcription: "/əˈɡriːmənt/", exampleSentence: "We reached an agreement.", exampleTranslation: "Ми досягли угоди.", synonyms: ["contract", "deal"], difficulty: .a2),
        Word(id: "a2_016", original: "air", translation: "повітря", transcription: "/er/", exampleSentence: "The air is fresh here.", exampleTranslation: "Тут повітря свіже.", synonyms: ["atmosphere"], difficulty: .a2),
        Word(id: "a2_017", original: "alive", translation: "живий", transcription: "/əˈlaɪv/", exampleSentence: "Is he still alive?", exampleTranslation: "Він ще живий?", synonyms: ["living"], difficulty: .a2),
        Word(id: "a2_018", original: "allow", translation: "дозволяти", transcription: "/əˈlaʊ/", exampleSentence: "Dogs are not allowed.", exampleTranslation: "Собаки не дозволені.", synonyms: ["permit", "let"], difficulty: .a2),
        Word(id: "a2_019", original: "almost", translation: "майже", transcription: "/ˈɔːlmoʊst/", exampleSentence: "It's almost time.", exampleTranslation: "Майже час.", synonyms: ["nearly", "practically"], difficulty: .a2),
        Word(id: "a2_020", original: "alone", translation: "самотній", transcription: "/əˈloʊn/", exampleSentence: "I prefer to be alone.", exampleTranslation: "Я віддаю перевагу бути сам.", synonyms: ["by oneself"], difficulty: .a2),
        Word(id: "a2_021", original: "along", translation: "вздовж", transcription: "/əˈlɔːŋ/", exampleSentence: "Walk along the street.", exampleTranslation: "Йди вздовж вулиці.", synonyms: [], difficulty: .a2),
        Word(id: "a2_022", original: "already", translation: "вже", transcription: "/ɔːlˈredi/", exampleSentence: "I've already eaten.", exampleTranslation: "Я вже поїв.", synonyms: ["by now"], difficulty: .a2),
        Word(id: "a2_023", original: "although", translation: "хоча", transcription: "/ɔːlˈðoʊ/", exampleSentence: "Although it rained, we went out.", exampleTranslation: "Хоча йшов дощ, ми вийшли.", synonyms: ["though", "even though"], difficulty: .a2),
        Word(id: "a2_024", original: "amount", translation: "кількість", transcription: "/əˈmaʊnt/", exampleSentence: "A large amount of money.", exampleTranslation: "Велика кількість грошей.", synonyms: ["quantity", "volume"], difficulty: .a2),
        Word(id: "a2_025", original: "ancient", translation: "давній", transcription: "/ˈeɪnʃənt/", exampleSentence: "Ancient Rome was powerful.", exampleTranslation: "Давній Рим був могутнім.", synonyms: ["old", "antique"], difficulty: .a2),
        Word(id: "a2_026", original: "angry", translation: "злий", transcription: "/ˈæŋɡri/", exampleSentence: "Don't get angry with me.", exampleTranslation: "Не сердься на мене.", synonyms: ["mad", "furious"], difficulty: .a2),
        Word(id: "a2_027", original: "animal", translation: "тварина", transcription: "/ˈænɪml/", exampleSentence: "What is your favorite animal?", exampleTranslation: "Яка твоя улюблена тварина?", synonyms: ["creature", "beast"], difficulty: .a2),
        Word(id: "a2_028", original: "announce", translation: "оголошувати", transcription: "/əˈnaʊns/", exampleSentence: "They will announce the winner.", exampleTranslation: "Вони оголосять переможця.", synonyms: ["declare", "proclaim"], difficulty: .a2),
        Word(id: "a2_029", original: "annoy", translation: "дратувати", transcription: "/əˈnɔɪ/", exampleSentence: "His behavior annoys me.", exampleTranslation: "Його поведінка дратує мене.", synonyms: ["irritate", "bother"], difficulty: .a2),
        Word(id: "a2_030", original: "another", translation: "інший", transcription: "/əˈnʌðər/", exampleSentence: "Can I have another cup?", exampleTranslation: "Можна мені ще чашку?", synonyms: ["one more", "additional"], difficulty: .a2),
        Word(id: "a2_031", original: "answer", translation: "відповідь", transcription: "/ˈænsər/", exampleSentence: "What's the answer?", exampleTranslation: "Яка відповідь?", synonyms: ["reply", "response"], difficulty: .a2),
        Word(id: "a2_032", original: "anxious", translation: "тривожний", transcription: "/ˈæŋkʃəs/", exampleSentence: "I feel anxious about the exam.", exampleTranslation: "Я відчуваю тривогу через іспит.", synonyms: ["worried", "nervous"], difficulty: .a2),
        Word(id: "a2_033", original: "anybody", translation: "хтось", transcription: "/ˈenibɑːdi/", exampleSentence: "Is anybody there?", exampleTranslation: "Хтось є?", synonyms: ["anyone"], difficulty: .a2),
        Word(id: "a2_034", original: "anymore", translation: "більше", transcription: "/ˌeniˈmɔːr/", exampleSentence: "I don't love you anymore.", exampleTranslation: "Я більше не люблю тебе.", synonyms: ["no longer"], difficulty: .a2),
        Word(id: "a2_035", original: "anyone", translation: "хтось", transcription: "/ˈeniwʌn/", exampleSentence: "Does anyone know?", exampleTranslation: "Хтось знає?", synonyms: ["anybody"], difficulty: .a2),
        Word(id: "a2_036", original: "anything", translation: "щось", transcription: "/ˈeniθɪŋ/", exampleSentence: "I don't want anything.", exampleTranslation: "Я нічого не хочу.", synonyms: [], difficulty: .a2),
        Word(id: "a2_037", original: "anyway", translation: "в будь-якому випадку", transcription: "/ˈeniweɪ/", exampleSentence: "Anyway, let's start.", exampleTranslation: "В будь-якому випадку, почнімо.", synonyms: ["anyhow"], difficulty: .a2),
        Word(id: "a2_038", original: "anywhere", translation: "будь-де", transcription: "/ˈeniwer/", exampleSentence: "I can't find it anywhere.", exampleTranslation: "Я не можу знайти це ніде.", synonyms: [], difficulty: .a2),
        Word(id: "a2_039", original: "apart", translation: "окремо", transcription: "/əˈpɑːrt/", exampleSentence: "We live apart now.", exampleTranslation: "Тепер ми живемо окремо.", synonyms: ["separately"], difficulty: .a2),
        Word(id: "a2_040", original: "apartment", translation: "квартира", transcription: "/əˈpɑːrtmənt/", exampleSentence: "I rent an apartment.", exampleTranslation: "Я орендую квартиру.", synonyms: ["flat"], difficulty: .a2),
        Word(id: "a2_041", original: "apparently", translation: "очевидно", transcription: "/əˈpærəntli/", exampleSentence: "Apparently, he's leaving.", exampleTranslation: "Очевидно, він їде.", synonyms: ["seemingly", "evidently"], difficulty: .a2),
        Word(id: "a2_042", original: "appear", translation: "з'являтися", transcription: "/əˈpɪr/", exampleSentence: "She didn't appear at work.", exampleTranslation: "Вона не з'явилась на роботі.", synonyms: ["seem", "look"], difficulty: .a2),
        Word(id: "a2_043", original: "appearance", translation: "зовнішність", transcription: "/əˈpɪrəns/", exampleSentence: "Appearance isn't everything.", exampleTranslation: "Зовнішність — не все.", synonyms: ["look"], difficulty: .a2),
        Word(id: "a2_044", original: "application", translation: "заява", transcription: "/ˌæplɪˈkeɪʃn/", exampleSentence: "I sent my application.", exampleTranslation: "Я надіслав свою заяву.", synonyms: ["form", "request"], difficulty: .a2),
        Word(id: "a2_045", original: "apply", translation: "застосовувати", transcription: "/əˈplaɪ/", exampleSentence: "Apply for the job.", exampleTranslation: "Подай заявку на роботу.", synonyms: ["use", "employ"], difficulty: .a2),
        Word(id: "a2_046", original: "appoint", translation: "призначати", transcription: "/əˈpɔɪnt/", exampleSentence: "They appointed him manager.", exampleTranslation: "Вони призначили його менеджером.", synonyms: ["assign", "name"], difficulty: .a2),
        Word(id: "a2_047", original: "appointment", translation: "призначення", transcription: "/əˈpɔɪntmənt/", exampleSentence: "I have a doctor's appointment.", exampleTranslation: "У мене прийом у лікаря.", synonyms: ["meeting", "date"], difficulty: .a2),
        Word(id: "a2_048", original: "appreciate", translation: "цінувати", transcription: "/əˈpriːʃieɪt/", exampleSentence: "I really appreciate your help.", exampleTranslation: "Я дійсно ціную твою допомогу.", synonyms: ["value", "be grateful for"], difficulty: .a2),
        Word(id: "a2_049", original: "approach", translation: "підхід", transcription: "/əˈproʊtʃ/", exampleSentence: "We need a new approach.", exampleTranslation: "Нам потрібен новий підхід.", synonyms: ["method", "way"], difficulty: .a2),
        Word(id: "a2_050", original: "appropriate", translation: "відповідний", transcription: "/əˈproʊpriət/", exampleSentence: "Wear appropriate clothes.", exampleTranslation: "Носи відповідний одяг.", synonyms: ["suitable", "proper"], difficulty: .a2),
        Word(id: "a2_051", original: "approve", translation: "схвалювати", transcription: "/əˈpruːv/", exampleSentence: "Do you approve?", exampleTranslation: "Ти схвалюєш?", synonyms: ["agree with", "accept"], difficulty: .a2),
        Word(id: "a2_052", original: "area", translation: "район", transcription: "/ˈeriə/", exampleSentence: "This is a quiet area.", exampleTranslation: "Це тихий район.", synonyms: ["region", "zone"], difficulty: .a2),
        Word(id: "a2_053", original: "argue", translation: "сперечатися", transcription: "/ˈɑːrɡjuː/", exampleSentence: "They always argue.", exampleTranslation: "Вони завжди сперечаються.", synonyms: ["quarrel", "debate"], difficulty: .a2),
        Word(id: "a2_054", original: "argument", translation: "аргумент", transcription: "/ˈɑːrɡjumənt/", exampleSentence: "What's your argument?", exampleTranslation: "Який твій аргумент?", synonyms: ["reason", "point"], difficulty: .a2),
        Word(id: "a2_055", original: "arise", translation: "виникати", transcription: "/əˈraɪz/", exampleSentence: "Problems may arise.", exampleTranslation: "Можуть виникнути проблеми.", synonyms: ["occur", "appear"], difficulty: .a2),
        Word(id: "a2_056", original: "army", translation: "армія", transcription: "/ˈɑːrmi/", exampleSentence: "He joined the army.", exampleTranslation: "Він пішов до армії.", synonyms: ["military"], difficulty: .a2),
        Word(id: "a2_057", original: "arrange", translation: "організовувати", transcription: "/əˈreɪndʒ/", exampleSentence: "I'll arrange a meeting.", exampleTranslation: "Я організую зустріч.", synonyms: ["organize", "plan"], difficulty: .a2),
        Word(id: "a2_058", original: "arrangement", translation: "домовленість", transcription: "/əˈreɪndʒmənt/", exampleSentence: "We have an arrangement.", exampleTranslation: "У нас є домовленість.", synonyms: ["agreement", "plan"], difficulty: .a2),
        Word(id: "a2_059", original: "arrest", translation: "арешт", transcription: "/əˈrest/", exampleSentence: "The police made an arrest.", exampleTranslation: "Поліція зробила арешт.", synonyms: ["detention"], difficulty: .a2),
        Word(id: "a2_060", original: "arrival", translation: "прибуття", transcription: "/əˈraɪvl/", exampleSentence: "What time is your arrival?", exampleTranslation: "О котрій твій приліт?", synonyms: ["coming"], difficulty: .a2),
        Word(id: "a2_061", original: "article", translation: "стаття", transcription: "/ˈɑːrtɪkl/", exampleSentence: "I read an interesting article.", exampleTranslation: "Я прочитав цікаву статтю.", synonyms: ["piece", "essay"], difficulty: .a2),
        Word(id: "a2_062", original: "artist", translation: "художник", transcription: "/ˈɑːrtɪst/", exampleSentence: "She is a famous artist.", exampleTranslation: "Вона відома художниця.", synonyms: ["painter", "creator"], difficulty: .a2),
        Word(id: "a2_063", original: "ashamed", translation: "соромно", transcription: "/əˈʃeɪmd/", exampleSentence: "I'm ashamed of my behavior.", exampleTranslation: "Мені соромно за свою поведінку.", synonyms: ["embarrassed"], difficulty: .a2),
        Word(id: "a2_064", original: "aside", translation: "вбік", transcription: "/əˈsaɪd/", exampleSentence: "Step aside, please.", exampleTranslation: "Відступіть вбік, будь ласка.", synonyms: [], difficulty: .a2),
        Word(id: "a2_065", original: "asleep", translation: "сплячий", transcription: "/əˈsliːp/", exampleSentence: "The baby is asleep.", exampleTranslation: "Дитина спить.", synonyms: ["sleeping"], difficulty: .a2),
        Word(id: "a2_066", original: "aspect", translation: "аспект", transcription: "/ˈæspekt/", exampleSentence: "This is one aspect.", exampleTranslation: "Це один аспект.", synonyms: ["facet", "side"], difficulty: .a2),
        Word(id: "a2_067", original: "assist", translation: "допомагати", transcription: "/əˈsɪst/", exampleSentence: "Can you assist me?", exampleTranslation: "Чи можете допомогти мені?", synonyms: ["help", "aid"], difficulty: .a2),
        Word(id: "a2_068", original: "assistant", translation: "помічник", transcription: "/əˈsɪstənt/", exampleSentence: "She works as an assistant.", exampleTranslation: "Вона працює помічницею.", synonyms: ["helper"], difficulty: .a2),
        Word(id: "a2_069", original: "associate", translation: "асоціювати", transcription: "/əˈsoʊʃieɪt/", exampleSentence: "I associate him with success.", exampleTranslation: "Я асоціюю його з успіхом.", synonyms: ["connect", "link"], difficulty: .a2),
        Word(id: "a2_070", original: "association", translation: "асоціація", transcription: "/əˌsoʊʃiˈeɪʃn/", exampleSentence: "He belongs to an association.", exampleTranslation: "Він належить до асоціації.", synonyms: ["organization", "society"], difficulty: .a2),
        Word(id: "a2_071", original: "assume", translation: "припускати", transcription: "/əˈsuːm/", exampleSentence: "I assume you're right.", exampleTranslation: "Я припускаю, що ти правий.", synonyms: ["suppose", "presume"], difficulty: .a2),
        Word(id: "a2_072", original: "assure", translation: "запевняти", transcription: "/əˈʃʊr/", exampleSentence: "I assure you it's safe.", exampleTranslation: "Я запевняю тебе, це безпечно.", synonyms: ["promise", "guarantee"], difficulty: .a2),
        Word(id: "a2_073", original: "attach", translation: "прикріплювати", transcription: "/əˈtætʃ/", exampleSentence: "Please attach the file.", exampleTranslation: "Будь ласка, прикріпіть файл.", synonyms: ["fasten", "connect"], difficulty: .a2),
        Word(id: "a2_074", original: "attack", translation: "атака", transcription: "/əˈtæk/", exampleSentence: "There was an attack.", exampleTranslation: "Була атака.", synonyms: ["assault", "strike"], difficulty: .a2),
        Word(id: "a2_075", original: "attempt", translation: "спроба", transcription: "/əˈtempt/", exampleSentence: "This is my first attempt.", exampleTranslation: "Це моя перша спроба.", synonyms: ["try", "effort"], difficulty: .a2),
        Word(id: "a2_076", original: "attend", translation: "відвідувати", transcription: "/əˈtend/", exampleSentence: "I attend classes regularly.", exampleTranslation: "Я регулярно відвідую заняття.", synonyms: ["go to", "participate"], difficulty: .a2),
        Word(id: "a2_077", original: "attention", translation: "увага", transcription: "/əˈtenʃn/", exampleSentence: "Pay attention!", exampleTranslation: "Зверни увагу!", synonyms: ["notice", "focus"], difficulty: .a2),
        Word(id: "a2_078", original: "attitude", translation: "ставлення", transcription: "/ˈætɪtuːd/", exampleSentence: "Your attitude is important.", exampleTranslation: "Твоє ставлення важливе.", synonyms: ["opinion", "view"], difficulty: .a2),
        Word(id: "a2_079", original: "attract", translation: "приваблювати", transcription: "/əˈtrækt/", exampleSentence: "The light attracts insects.", exampleTranslation: "Світло приваблює комах.", synonyms: ["draw", "appeal to"], difficulty: .a2),
        Word(id: "a2_080", original: "audience", translation: "аудиторія", transcription: "/ˈɔːdiəns/", exampleSentence: "The audience applauded.", exampleTranslation: "Аудиторія аплодувала.", synonyms: ["spectators", "crowd"], difficulty: .a2),
        Word(id: "a2_081", original: "author", translation: "автор", transcription: "/ˈɔːθər/", exampleSentence: "Who is the author?", exampleTranslation: "Хто автор?", synonyms: ["writer"], difficulty: .a2),
        Word(id: "a2_082", original: "automatic", translation: "автоматичний", transcription: "/ˌɔːtəˈmætɪk/", exampleSentence: "The door is automatic.", exampleTranslation: "Двері автоматичні.", synonyms: ["self-operating"], difficulty: .a2),
        Word(id: "a2_083", original: "available", translation: "доступний", transcription: "/əˈveɪləbl/", exampleSentence: "Is this room available?", exampleTranslation: "Ця кімната вільна?", synonyms: ["free", "accessible"], difficulty: .a2),
        Word(id: "a2_084", original: "average", translation: "середній", transcription: "/ˈævərɪdʒ/", exampleSentence: "The average age is 25.", exampleTranslation: "Середній вік — 25.", synonyms: ["mean", "medium"], difficulty: .a2),
        Word(id: "a2_085", original: "avoid", translation: "уникати", transcription: "/əˈvɔɪd/", exampleSentence: "Avoid this area.", exampleTranslation: "Уникай цього району.", synonyms: ["stay away from"], difficulty: .a2),
        Word(id: "a2_086", original: "awake", translation: "прокинутий", transcription: "/əˈweɪk/", exampleSentence: "Are you awake?", exampleTranslation: "Ти не спиш?", synonyms: ["conscious"], difficulty: .a2),
        Word(id: "a2_087", original: "award", translation: "нагорода", transcription: "/əˈwɔːrd/", exampleSentence: "She won an award.", exampleTranslation: "Вона отримала нагороду.", synonyms: ["prize", "trophy"], difficulty: .a2),
        Word(id: "a2_088", original: "aware", translation: "обізнаний", transcription: "/əˈwer/", exampleSentence: "Are you aware of this?", exampleTranslation: "Ти знаєш про це?", synonyms: ["conscious", "informed"], difficulty: .a2),
        Word(id: "a2_089", original: "awful", translation: "жахливий", transcription: "/ˈɔːfl/", exampleSentence: "The weather is awful.", exampleTranslation: "Погода жахлива.", synonyms: ["terrible", "horrible"], difficulty: .a2),
        Word(id: "a2_090", original: "background", translation: "фон", transcription: "/ˈbækɡraʊnd/", exampleSentence: "Tell me your background.", exampleTranslation: "Розкажи мені про свій досвід.", synonyms: ["history", "experience"], difficulty: .a2),
        Word(id: "a2_091", original: "bake", translation: "пекти", transcription: "/beɪk/", exampleSentence: "I love to bake cakes.", exampleTranslation: "Я люблю пекти торти.", synonyms: ["cook"], difficulty: .a2),
        Word(id: "a2_092", original: "balance", translation: "баланс", transcription: "/ˈbæləns/", exampleSentence: "Keep your balance.", exampleTranslation: "Тримай баланс.", synonyms: ["equilibrium"], difficulty: .a2),
        Word(id: "a2_093", original: "band", translation: "гурт", transcription: "/bænd/", exampleSentence: "I love this band.", exampleTranslation: "Я люблю цей гурт.", synonyms: ["group", "orchestra"], difficulty: .a2),
        Word(id: "a2_094", original: "bar", translation: "бар", transcription: "/bɑːr/", exampleSentence: "Meet me at the bar.", exampleTranslation: "Зустрінь мене в барі.", synonyms: ["pub"], difficulty: .a2),
        Word(id: "a2_095", original: "base", translation: "база", transcription: "/beɪs/", exampleSentence: "This is our base.", exampleTranslation: "Це наша база.", synonyms: ["foundation", "center"], difficulty: .a2),
        Word(id: "a2_096", original: "basic", translation: "базовий", transcription: "/ˈbeɪsɪk/", exampleSentence: "These are basic skills.", exampleTranslation: "Це базові навички.", synonyms: ["fundamental", "essential"], difficulty: .a2),
        Word(id: "a2_097", original: "basis", translation: "основа", transcription: "/ˈbeɪsɪs/", exampleSentence: "On a daily basis.", exampleTranslation: "На щоденній основі.", synonyms: ["foundation"], difficulty: .a2),
        Word(id: "a2_098", original: "bath", translation: "ванна", transcription: "/bæθ/", exampleSentence: "I need a bath.", exampleTranslation: "Мені потрібна ванна.", synonyms: [], difficulty: .a2),
        Word(id: "a2_099", original: "battle", translation: "битва", transcription: "/ˈbætl/", exampleSentence: "It was a fierce battle.", exampleTranslation: "Це була запекла битва.", synonyms: ["fight", "combat"], difficulty: .a2),
        Word(id: "a2_100", original: "beach", translation: "пляж", transcription: "/biːtʃ/", exampleSentence: "Let's go to the beach.", exampleTranslation: "Підемо на пляж.", synonyms: ["shore", "coast"], difficulty: .a2),
        Word(id: "a2_101", original: "beat", translation: "бити", transcription: "/biːt/", exampleSentence: "My heart beats fast.", exampleTranslation: "Моє серце б'ється швидко.", synonyms: ["hit", "defeat"], difficulty: .a2),
        Word(id: "a2_102", original: "beauty", translation: "краса", transcription: "/ˈbjuːti/", exampleSentence: "She has natural beauty.", exampleTranslation: "У неї природна краса.", synonyms: ["attractiveness"], difficulty: .a2),
        Word(id: "a2_103", original: "because", translation: "тому що", transcription: "/bɪˈkɔːz/", exampleSentence: "Because I said so.", exampleTranslation: "Тому що я так сказав.", synonyms: ["since", "as"], difficulty: .a2),
        Word(id: "a2_104", original: "become", translation: "ставати", transcription: "/bɪˈkʌm/", exampleSentence: "I want to become a doctor.", exampleTranslation: "Я хочу стати лікарем.", synonyms: ["get", "turn into"], difficulty: .a2),
        Word(id: "a2_105", original: "bedroom", translation: "спальня", transcription: "/ˈbedruːm/", exampleSentence: "This is my bedroom.", exampleTranslation: "Це моя спальня.", synonyms: [], difficulty: .a2),
        Word(id: "a2_106", original: "beef", translation: "яловичина", transcription: "/biːf/", exampleSentence: "I prefer beef to pork.", exampleTranslation: "Я віддаю перевагу яловичині.", synonyms: [], difficulty: .a2),
        Word(id: "a2_107", original: "beer", translation: "пиво", transcription: "/bɪr/", exampleSentence: "A glass of beer, please.", exampleTranslation: "Склянку пива, будь ласка.", synonyms: [], difficulty: .a2),
        Word(id: "a2_108", original: "before", translation: "перед", transcription: "/bɪˈfɔːr/", exampleSentence: "Before we start...", exampleTranslation: "Перед тим як ми почнемо...", synonyms: ["prior to"], difficulty: .a2),
        Word(id: "a2_109", original: "begin", translation: "починати", transcription: "/bɪˈɡɪn/", exampleSentence: "Let's begin the lesson.", exampleTranslation: "Почнімо урок.", synonyms: ["start", "commence"], difficulty: .a2),
        Word(id: "a2_110", original: "behave", translation: "поводитися", transcription: "/bɪˈheɪv/", exampleSentence: "Behave yourself!", exampleTranslation: "Веди себе пристойно!", synonyms: ["act", "conduct oneself"], difficulty: .a2),
        Word(id: "a2_111", original: "behavior", translation: "поведінка", transcription: "/bɪˈheɪvjər/", exampleSentence: "His behavior was strange.", exampleTranslation: "Його поведінка була дивною.", synonyms: ["conduct"], difficulty: .a2),
        Word(id: "a2_112", original: "behind", translation: "позаду", transcription: "/bɪˈhaɪnd/", exampleSentence: "Behind the building.", exampleTranslation: "Позаду будівлі.", synonyms: ["at the back of"], difficulty: .a2),
        Word(id: "a2_113", original: "believe", translation: "вірити", transcription: "/bɪˈliːv/", exampleSentence: "I believe in you.", exampleTranslation: "Я вірю в тебе.", synonyms: ["trust", "have faith"], difficulty: .a2),
        Word(id: "a2_114", original: "belong", translation: "належати", transcription: "/bɪˈlɔːŋ/", exampleSentence: "This book belongs to me.", exampleTranslation: "Ця книга належить мені.", synonyms: ["be owned by"], difficulty: .a2),
        Word(id: "a2_115", original: "below", translation: "нижче", transcription: "/bɪˈloʊ/", exampleSentence: "See the details below.", exampleTranslation: "Дивись деталі нижче.", synonyms: ["under", "beneath"], difficulty: .a2),
        Word(id: "a2_116", original: "belt", translation: "пояс", transcription: "/belt/", exampleSentence: "Fasten your seat belt.", exampleTranslation: "Застебни ремінь безпеки.", synonyms: ["strap"], difficulty: .a2),
        Word(id: "a2_117", original: "benefit", translation: "вигода", transcription: "/ˈbenɪfɪt/", exampleSentence: "This has many benefits.", exampleTranslation: "Це має багато переваг.", synonyms: ["advantage", "profit"], difficulty: .a2),
        Word(id: "a2_118", original: "best", translation: "найкращий", transcription: "/best/", exampleSentence: "You're the best!", exampleTranslation: "Ти найкращий!", synonyms: ["finest", "greatest"], difficulty: .a2),
        Word(id: "a2_119", original: "better", translation: "краще", transcription: "/ˈbetər/", exampleSentence: "I feel better now.", exampleTranslation: "Тепер мені краще.", synonyms: ["improved"], difficulty: .a2),
        Word(id: "a2_120", original: "between", translation: "між", transcription: "/bɪˈtwiːn/", exampleSentence: "Between you and me.", exampleTranslation: "Між нами.", synonyms: [], difficulty: .a2),
        Word(id: "a2_121", original: "beyond", translation: "за", transcription: "/bɪˈjɑːnd/", exampleSentence: "Beyond my expectations.", exampleTranslation: "За моїми очікуваннями.", synonyms: ["past", "further than"], difficulty: .a2),
        Word(id: "a2_122", original: "bill", translation: "рахунок", transcription: "/bɪl/", exampleSentence: "Can I have the bill?", exampleTranslation: "Можна рахунок?", synonyms: ["invoice", "check"], difficulty: .a2),
        Word(id: "a2_123", original: "billion", translation: "мільярд", transcription: "/ˈbɪljən/", exampleSentence: "Over a billion people.", exampleTranslation: "Понад мільярд людей.", synonyms: [], difficulty: .a2),
        Word(id: "a2_124", original: "bin", translation: "смітник", transcription: "/bɪn/", exampleSentence: "Throw it in the bin.", exampleTranslation: "Викинь у смітник.", synonyms: ["trash can"], difficulty: .a2),
        Word(id: "a2_125", original: "biology", translation: "біологія", transcription: "/baɪˈɑːlədʒi/", exampleSentence: "I study biology.", exampleTranslation: "Я вивчаю біологію.", synonyms: [], difficulty: .a2),
        Word(id: "a2_126", original: "birth", translation: "народження", transcription: "/bɜːrθ/", exampleSentence: "The birth of a child.", exampleTranslation: "Народження дитини.", synonyms: [], difficulty: .a2),
        Word(id: "a2_127", original: "birthday", translation: "день народження", transcription: "/ˈbɜːrθdeɪ/", exampleSentence: "Happy birthday!", exampleTranslation: "З днем народження!", synonyms: [], difficulty: .a2),
        Word(id: "a2_128", original: "biscuit", translation: "печиво", transcription: "/ˈbɪskɪt/", exampleSentence: "Have a biscuit.", exampleTranslation: "Візьми печиво.", synonyms: ["cookie"], difficulty: .a2),
        Word(id: "a2_129", original: "bit", translation: "трохи", transcription: "/bɪt/", exampleSentence: "Wait a bit.", exampleTranslation: "Зачекай трохи.", synonyms: ["moment", "while"], difficulty: .a2),
        Word(id: "a2_130", original: "bite", translation: "кусати", transcription: "/baɪt/", exampleSentence: "Don't bite your nails.", exampleTranslation: "Не гризи нігті.", synonyms: ["nibble"], difficulty: .a2),
        Word(id: "a2_131", original: "bitter", translation: "гіркий", transcription: "/ˈbɪtər/", exampleSentence: "The coffee is bitter.", exampleTranslation: "Кава гірка.", synonyms: [], difficulty: .a2),
        Word(id: "a2_132", original: "blame", translation: "звинувачувати", transcription: "/bleɪm/", exampleSentence: "Don't blame me.", exampleTranslation: "Не звинувачуй мене.", synonyms: ["accuse"], difficulty: .a2),
        Word(id: "a2_133", original: "blank", translation: "порожній", transcription: "/blæŋk/", exampleSentence: "Fill in the blank.", exampleTranslation: "Заповни порожнє місце.", synonyms: ["empty"], difficulty: .a2),
        Word(id: "a2_134", original: "blind", translation: "сліпий", transcription: "/blaɪnd/", exampleSentence: "He is blind.", exampleTranslation: "Він сліпий.", synonyms: ["sightless"], difficulty: .a2),
        Word(id: "a2_135", original: "block", translation: "блок", transcription: "/blɑːk/", exampleSentence: "A block of ice.", exampleTranslation: "Блок льоду.", synonyms: ["obstruct"], difficulty: .a2),
        Word(id: "a2_136", original: "blood", translation: "кров", transcription: "/blʌd/", exampleSentence: "There was blood.", exampleTranslation: "Була кров.", synonyms: [], difficulty: .a2),
        Word(id: "a2_137", original: "blow", translation: "дути", transcription: "/bloʊ/", exampleSentence: "The wind is blowing.", exampleTranslation: "Вітер дме.", synonyms: ["puff"], difficulty: .a2),
        Word(id: "a2_138", original: "board", translation: "дошка", transcription: "/bɔːrd/", exampleSentence: "Write on the board.", exampleTranslation: "Пиши на дошці.", synonyms: ["plank"], difficulty: .a2),
        Word(id: "a2_139", original: "boat", translation: "човен", transcription: "/boʊt/", exampleSentence: "Let's take a boat.", exampleTranslation: "Сядемо на човен.", synonyms: ["ship", "vessel"], difficulty: .a2),
        Word(id: "a2_140", original: "body", translation: "тіло", transcription: "/ˈbɑːdi/", exampleSentence: "My body hurts.", exampleTranslation: "Моє тіло болить.", synonyms: ["physique"], difficulty: .a2),
        Word(id: "a2_141", original: "boil", translation: "кип'ятити", transcription: "/bɔɪl/", exampleSentence: "Boil the water.", exampleTranslation: "Закип'яти воду.", synonyms: ["simmer"], difficulty: .a2),
        Word(id: "a2_142", original: "bomb", translation: "бомба", transcription: "/bɑːm/", exampleSentence: "A bomb exploded.", exampleTranslation: "Бомба вибухнула.", synonyms: ["explosive"], difficulty: .a2),
        Word(id: "a2_143", original: "bone", translation: "кістка", transcription: "/boʊn/", exampleSentence: "I broke a bone.", exampleTranslation: "Я зламав кістку.", synonyms: [], difficulty: .a2),
        Word(id: "a2_144", original: "book", translation: "бронювати", transcription: "/bʊk/", exampleSentence: "Book a table.", exampleTranslation: "Забронюй столик.", synonyms: ["reserve"], difficulty: .a2),
        Word(id: "a2_145", original: "boot", translation: "черевик", transcription: "/buːt/", exampleSentence: "Wear your boots.", exampleTranslation: "Взуй черевики.", synonyms: ["shoe"], difficulty: .a2),
        Word(id: "a2_146", original: "border", translation: "кордон", transcription: "/ˈbɔːrdər/", exampleSentence: "Cross the border.", exampleTranslation: "Перетни кордон.", synonyms: ["boundary", "frontier"], difficulty: .a2),
        Word(id: "a2_147", original: "bored", translation: "нудьгуючий", transcription: "/bɔːrd/", exampleSentence: "I'm bored.", exampleTranslation: "Мені нудно.", synonyms: ["uninterested"], difficulty: .a2),
        Word(id: "a2_148", original: "boring", translation: "нудний", transcription: "/ˈbɔːrɪŋ/", exampleSentence: "This is boring.", exampleTranslation: "Це нудно.", synonyms: ["dull", "tedious"], difficulty: .a2),
        Word(id: "a2_149", original: "born", translation: "народжений", transcription: "/bɔːrn/", exampleSentence: "I was born in 1990.", exampleTranslation: "Я народився в 1990.", synonyms: [], difficulty: .a2),
        Word(id: "a2_150", original: "borrow", translation: "позичати", transcription: "/ˈbɑːroʊ/", exampleSentence: "Can I borrow this?", exampleTranslation: "Можна позичити це?", synonyms: ["take on loan"], difficulty: .a2),
        Word(id: "a2_151", original: "boss", translation: "начальник", transcription: "/bɔːs/", exampleSentence: "My boss is nice.", exampleTranslation: "Мій начальник хороший.", synonyms: ["manager", "supervisor"], difficulty: .a2),
        Word(id: "a2_152", original: "both", translation: "обидва", transcription: "/boʊθ/", exampleSentence: "Both of us.", exampleTranslation: "Ми обидва.", synonyms: [], difficulty: .a2),
        Word(id: "a2_153", original: "bother", translation: "турбувати", transcription: "/ˈbɑːðər/", exampleSentence: "Don't bother me.", exampleTranslation: "Не турбуй мене.", synonyms: ["disturb", "annoy"], difficulty: .a2),
        Word(id: "a2_154", original: "bottle", translation: "пляшка", transcription: "/ˈbɑːtl/", exampleSentence: "A bottle of water.", exampleTranslation: "Пляшка води.", synonyms: ["container"], difficulty: .a2),
        Word(id: "a2_155", original: "bottom", translation: "дно", transcription: "/ˈbɑːtəm/", exampleSentence: "At the bottom.", exampleTranslation: "На дні.", synonyms: ["base"], difficulty: .a2),
        Word(id: "a2_156", original: "bowl", translation: "миска", transcription: "/boʊl/", exampleSentence: "A bowl of soup.", exampleTranslation: "Миска супу.", synonyms: ["dish"], difficulty: .a2),
        Word(id: "a2_157", original: "box", translation: "коробка", transcription: "/bɑːks/", exampleSentence: "Put it in a box.", exampleTranslation: "Поклади в коробку.", synonyms: ["container"], difficulty: .a2),
        Word(id: "a2_158", original: "boyfriend", translation: "хлопець", transcription: "/ˈbɔɪfrend/", exampleSentence: "My boyfriend is tall.", exampleTranslation: "Мій хлопець високий.", synonyms: ["partner"], difficulty: .a2),
        Word(id: "a2_159", original: "brain", translation: "мозок", transcription: "/breɪn/", exampleSentence: "Use your brain.", exampleTranslation: "Використовуй мозок.", synonyms: ["mind"], difficulty: .a2),
        Word(id: "a2_160", original: "branch", translation: "гілка", transcription: "/bræntʃ/", exampleSentence: "A tree branch.", exampleTranslation: "Гілка дерева.", synonyms: ["limb"], difficulty: .a2),
        Word(id: "a2_161", original: "brave", translation: "хоробрий", transcription: "/breɪv/", exampleSentence: "You are brave.", exampleTranslation: "Ти хоробрий.", synonyms: ["courageous"], difficulty: .a2),
        Word(id: "a2_162", original: "bread", translation: "хліб", transcription: "/bred/", exampleSentence: "Fresh bread.", exampleTranslation: "Свіжий хліб.", synonyms: [], difficulty: .a2),
        Word(id: "a2_163", original: "break", translation: "перерва", transcription: "/breɪk/", exampleSentence: "Take a break.", exampleTranslation: "Зроби перерву.", synonyms: ["rest", "pause"], difficulty: .a2),
        Word(id: "a2_164", original: "breakfast", translation: "сніданок", transcription: "/ˈbrekfəst/", exampleSentence: "I eat breakfast.", exampleTranslation: "Я снідаю.", synonyms: [], difficulty: .a2),
        Word(id: "a2_165", original: "breath", translation: "подих", transcription: "/breθ/", exampleSentence: "Take a deep breath.", exampleTranslation: "Зроби глибокий вдих.", synonyms: [], difficulty: .a2),
        Word(id: "a2_166", original: "breathe", translation: "дихати", transcription: "/briːð/", exampleSentence: "Breathe deeply.", exampleTranslation: "Дихай глибоко.", synonyms: ["inhale"], difficulty: .a2),
        Word(id: "a2_167", original: "brick", translation: "цегла", transcription: "/brɪk/", exampleSentence: "A brick wall.", exampleTranslation: "Цегляна стіна.", synonyms: [], difficulty: .a2),
        Word(id: "a2_168", original: "bridge", translation: "міст", transcription: "/brɪdʒ/", exampleSentence: "Cross the bridge.", exampleTranslation: "Перейди міст.", synonyms: [], difficulty: .a2),
        Word(id: "a2_169", original: "bright", translation: "яскравий", transcription: "/braɪt/", exampleSentence: "The sun is bright.", exampleTranslation: "Сонце яскраве.", synonyms: ["shining", "brilliant"], difficulty: .a2),
        Word(id: "a2_170", original: "brilliant", translation: "блискучий", transcription: "/ˈbrɪliənt/", exampleSentence: "A brilliant idea.", exampleTranslation: "Блискуча ідея.", synonyms: ["excellent"], difficulty: .a2),
        Word(id: "a2_171", original: "bring", translation: "приносити", transcription: "/brɪŋ/", exampleSentence: "Bring me water.", exampleTranslation: "Принеси мені води.", synonyms: ["carry", "fetch"], difficulty: .a2),
        Word(id: "a2_172", original: "broad", translation: "широкий", transcription: "/brɔːd/", exampleSentence: "A broad street.", exampleTranslation: "Широка вулиця.", synonyms: ["wide"], difficulty: .a2),
        Word(id: "a2_173", original: "brother", translation: "брат", transcription: "/ˈbrʌðər/", exampleSentence: "My older brother.", exampleTranslation: "Мій старший брат.", synonyms: [], difficulty: .a2),
        Word(id: "a2_174", original: "brown", translation: "коричневий", transcription: "/braʊn/", exampleSentence: "Brown eyes.", exampleTranslation: "Карі очі.", synonyms: [], difficulty: .a2),
        Word(id: "a2_175", original: "brush", translation: "щітка", transcription: "/brʌʃ/", exampleSentence: "Brush your teeth.", exampleTranslation: "Чисти зуби.", synonyms: [], difficulty: .a2),
        Word(id: "a2_176", original: "budget", translation: "бюджет", transcription: "/ˈbʌdʒɪt/", exampleSentence: "We have a tight budget.", exampleTranslation: "У нас обмежений бюджет.", synonyms: ["finances"], difficulty: .a2),
        Word(id: "a2_177", original: "build", translation: "будувати", transcription: "/bɪld/", exampleSentence: "Build a house.", exampleTranslation: "Побудуй будинок.", synonyms: ["construct"], difficulty: .a2),
        Word(id: "a2_178", original: "building", translation: "будівля", transcription: "/ˈbɪldɪŋ/", exampleSentence: "A tall building.", exampleTranslation: "Висока будівля.", synonyms: ["structure"], difficulty: .a2),
        Word(id: "a2_179", original: "bullet", translation: "куля", transcription: "/ˈbʊlɪt/", exampleSentence: "A bullet wound.", exampleTranslation: "Поранення від кулі.", synonyms: [], difficulty: .a2),
        Word(id: "a2_180", original: "bunch", translation: "пучок", transcription: "/bʌntʃ/", exampleSentence: "A bunch of flowers.", exampleTranslation: "Пучок квітів.", synonyms: ["group"], difficulty: .a2),
        Word(id: "a2_181", original: "burn", translation: "палити", transcription: "/bɜːrn/", exampleSentence: "The fire is burning.", exampleTranslation: "Вогонь горить.", synonyms: ["ignite"], difficulty: .a2),
        Word(id: "a2_182", original: "burst", translation: "вибух", transcription: "/bɜːrst/", exampleSentence: "The pipe burst.", exampleTranslation: "Труба луснула.", synonyms: ["explode"], difficulty: .a2),
        Word(id: "a2_183", original: "bury", translation: "ховати", transcription: "/ˈberi/", exampleSentence: "Bury the treasure.", exampleTranslation: "Закопай скарб.", synonyms: ["inter"], difficulty: .a2),
        Word(id: "a2_184", original: "bus", translation: "автобус", transcription: "/bʌs/", exampleSentence: "Take the bus.", exampleTranslation: "Сідай на автобус.", synonyms: [], difficulty: .a2),
        Word(id: "a2_185", original: "bush", translation: "кущ", transcription: "/bʊʃ/", exampleSentence: "Hide in the bush.", exampleTranslation: "Сховайся в кущах.", synonyms: ["shrub"], difficulty: .a2),
        Word(id: "a2_186", original: "business", translation: "бізнес", transcription: "/ˈbɪznəs/", exampleSentence: "Mind your own business.", exampleTranslation: "Займайся своїми справами.", synonyms: ["commerce"], difficulty: .a2),
        Word(id: "a2_187", original: "busy", translation: "зайнятий", transcription: "/ˈbɪzi/", exampleSentence: "I'm very busy.", exampleTranslation: "Я дуже зайнятий.", synonyms: ["occupied"], difficulty: .a2),
        Word(id: "a2_188", original: "but", translation: "але", transcription: "/bʌt/", exampleSentence: "But I don't know.", exampleTranslation: "Але я не знаю.", synonyms: ["however"], difficulty: .a2),
        Word(id: "a2_189", original: "butter", translation: "вершкове масло", transcription: "/ˈbʌtər/", exampleSentence: "Pass the butter.", exampleTranslation: "Передай масло.", synonyms: [], difficulty: .a2),
        Word(id: "a2_190", original: "button", translation: "кнопка", transcription: "/ˈbʌtn/", exampleSentence: "Press the button.", exampleTranslation: "Натисни кнопку.", synonyms: [], difficulty: .a2),
        Word(id: "a2_191", original: "buy", translation: "купувати", transcription: "/baɪ/", exampleSentence: "I want to buy this.", exampleTranslation: "Я хочу це купити.", synonyms: ["purchase"], difficulty: .a2),
        Word(id: "a2_192", original: "by", translation: "до", transcription: "/baɪ/", exampleSentence: "By tomorrow.", exampleTranslation: "До завтра.", synonyms: ["before"], difficulty: .a2),
        Word(id: "a2_193", original: "bye", translation: "бувай", transcription: "/baɪ/", exampleSentence: "Bye for now.", exampleTranslation: "Бувай поки.", synonyms: ["goodbye"], difficulty: .a2),
        Word(id: "a2_194", original: "cabin", translation: "кабіна", transcription: "/ˈkæbɪn/", exampleSentence: "A log cabin.", exampleTranslation: "Зруб.", synonyms: ["hut"], difficulty: .a2),
        Word(id: "a2_195", original: "cabinet", translation: "шафа", transcription: "/ˈkæbɪnət/", exampleSentence: "Kitchen cabinet.", exampleTranslation: "Кухонна шафа.", synonyms: ["cupboard"], difficulty: .a2),
        Word(id: "a2_196", original: "cable", translation: "кабель", transcription: "/ˈkeɪbl/", exampleSentence: "Connect the cable.", exampleTranslation: "Під'єднай кабель.", synonyms: ["wire"], difficulty: .a2),
        Word(id: "a2_197", original: "cafe", translation: "кафе", transcription: "/ˈkæfeɪ/", exampleSentence: "Meet at the cafe.", exampleTranslation: "Зустрінься в кафе.", synonyms: ["coffee shop"], difficulty: .a2),
        Word(id: "a2_198", original: "cage", translation: "клітка", transcription: "/keɪdʒ/", exampleSentence: "A bird cage.", exampleTranslation: "Клітка для птахів.", synonyms: [], difficulty: .a2),
        Word(id: "a2_199", original: "cake", translation: "торт", transcription: "/keɪk/", exampleSentence: "Birthday cake.", exampleTranslation: "Торт на день народження.", synonyms: [], difficulty: .a2),
        Word(id: "a2_200", original: "calculate", translation: "рахувати", transcription: "/ˈkælkjuleɪt/", exampleSentence: "Calculate the cost.", exampleTranslation: "Порахуй вартість.", synonyms: ["compute"], difficulty: .a2),
        Word(id: "a2_201", original: "calendar", translation: "календар", transcription: "/ˈkælɪndər/", exampleSentence: "Mark the calendar.", exampleTranslation: "Познач у календарі.", synonyms: ["schedule"], difficulty: .a2),
        Word(id: "a2_202", original: "call", translation: "дзвінок", transcription: "/kɔːl/", exampleSentence: "I'll call you.", exampleTranslation: "Я подзвоню тобі.", synonyms: ["phone", "ring"], difficulty: .a2),
        Word(id: "a2_203", original: "calm", translation: "спокійний", transcription: "/kɑːm/", exampleSentence: "Stay calm.", exampleTranslation: "Залишайся спокійним.", synonyms: ["peaceful"], difficulty: .a2),
        Word(id: "a2_204", original: "camera", translation: "камера", transcription: "/ˈkæmərə/", exampleSentence: "Take a photo with the camera.", exampleTranslation: "Зроби фото камерою.", synonyms: [], difficulty: .a2),
        Word(id: "a2_205", original: "camp", translation: "табір", transcription: "/kæmp/", exampleSentence: "We went to camp.", exampleTranslation: "Ми поїхали в табір.", synonyms: [], difficulty: .a2),
        Word(id: "a2_206", original: "campaign", translation: "кампанія", transcription: "/kæmˈpeɪn/", exampleSentence: "An advertising campaign.", exampleTranslation: "Рекламна кампанія.", synonyms: ["drive"], difficulty: .a2),
        Word(id: "a2_207", original: "can", translation: "банка", transcription: "/kæn/", exampleSentence: "A can of soda.", exampleTranslation: "Банка газованої води.", synonyms: ["tin"], difficulty: .a2),
        Word(id: "a2_208", original: "cancel", translation: "скасувати", transcription: "/ˈkænsl/", exampleSentence: "Cancel the meeting.", exampleTranslation: "Скасуй зустріч.", synonyms: ["call off"], difficulty: .a2),
        Word(id: "a2_209", original: "cancer", translation: "рак", transcription: "/ˈkænsər/", exampleSentence: "Fight cancer.", exampleTranslation: "Боротьба з раком.", synonyms: [], difficulty: .a2),
        Word(id: "a2_210", original: "candidate", translation: "кандидат", transcription: "/ˈkændɪdət/", exampleSentence: "A job candidate.", exampleTranslation: "Кандидат на роботу.", synonyms: ["applicant"], difficulty: .a2),
        Word(id: "a2_211", original: "candle", translation: "свічка", transcription: "/ˈkændl/", exampleSentence: "Light a candle.", exampleTranslation: "Запали свічку.", synonyms: [], difficulty: .a2),
        Word(id: "a2_212", original: "candy", translation: "цукерка", transcription: "/ˈkændi/", exampleSentence: "I love candy.", exampleTranslation: "Я люблю цукерки.", synonyms: ["sweets"], difficulty: .a2),
        Word(id: "a2_213", original: "cap", translation: "кепка", transcription: "/kæp/", exampleSentence: "Wear a cap.", exampleTranslation: "Носи кепку.", synonyms: ["hat"], difficulty: .a2),
        Word(id: "a2_214", original: "capable", translation: "здатний", transcription: "/ˈkeɪpəbl/", exampleSentence: "You are capable.", exampleTranslation: "Ти здатний.", synonyms: ["able"], difficulty: .a2),
        Word(id: "a2_215", original: "capacity", translation: "місткість", transcription: "/kəˈpæsəti/", exampleSentence: "Full capacity.", exampleTranslation: "Повна місткість.", synonyms: ["ability"], difficulty: .a2),
        Word(id: "a2_216", original: "capital", translation: "столиця", transcription: "/ˈkæpɪtl/", exampleSentence: "Kyiv is the capital.", exampleTranslation: "Київ — столиця.", synonyms: [], difficulty: .a2),
        Word(id: "a2_217", original: "captain", translation: "капітан", transcription: "/ˈkæptɪn/", exampleSentence: "The team captain.", exampleTranslation: "Капітан команди.", synonyms: ["leader"], difficulty: .a2),
        Word(id: "a2_218", original: "capture", translation: "захоплювати", transcription: "/ˈkæptʃər/", exampleSentence: "Capture the moment.", exampleTranslation: "Захопи момент.", synonyms: ["catch"], difficulty: .a2),
        Word(id: "a2_219", original: "car", translation: "автомобіль", transcription: "/kɑːr/", exampleSentence: "I bought a car.", exampleTranslation: "Я купив машину.", synonyms: ["automobile"], difficulty: .a2),
        Word(id: "a2_220", original: "card", translation: "картка", transcription: "/kɑːrd/", exampleSentence: "Credit card.", exampleTranslation: "Кредитна картка.", synonyms: [], difficulty: .a2),
        Word(id: "a2_221", original: "care", translation: "турбота", transcription: "/ker/", exampleSentence: "Take care of yourself.", exampleTranslation: "Піклуйся про себе.", synonyms: ["concern"], difficulty: .a2),
        Word(id: "a2_222", original: "career", translation: "кар'єра", transcription: "/kəˈrɪr/", exampleSentence: "Build a career.", exampleTranslation: "Будуй кар'єру.", synonyms: ["profession"], difficulty: .a2),
        Word(id: "a2_223", original: "careful", translation: "обережний", transcription: "/ˈkerfl/", exampleSentence: "Be careful!", exampleTranslation: "Будь обережний!", synonyms: ["cautious"], difficulty: .a2),
        Word(id: "a2_224", original: "careless", translation: "необережний", transcription: "/ˈkerləs/", exampleSentence: "Don't be careless.", exampleTranslation: "Не будь необережним.", synonyms: ["reckless"], difficulty: .a2),
        Word(id: "a2_225", original: "carpet", translation: "килим", transcription: "/ˈkɑːrpɪt/", exampleSentence: "A red carpet.", exampleTranslation: "Червоний килим.", synonyms: ["rug"], difficulty: .a2),
        Word(id: "a2_226", original: "carrot", translation: "морква", transcription: "/ˈkærət/", exampleSentence: "Eat your carrots.", exampleTranslation: "Їж моркву.", synonyms: [], difficulty: .a2),
        Word(id: "a2_227", original: "carry", translation: "нести", transcription: "/ˈkæri/", exampleSentence: "Carry this bag.", exampleTranslation: "Неси цю сумку.", synonyms: ["transport"], difficulty: .a2),
        Word(id: "a2_228", original: "cart", translation: "візок", transcription: "/kɑːrt/", exampleSentence: "Shopping cart.", exampleTranslation: "Візок для покупок.", synonyms: ["trolley"], difficulty: .a2),
        Word(id: "a2_229", original: "case", translation: "випадок", transcription: "/keɪs/", exampleSentence: "In that case...", exampleTranslation: "У цьому випадку...", synonyms: ["instance"], difficulty: .a2),
        Word(id: "a2_230", original: "cash", translation: "готівка", transcription: "/kæʃ/", exampleSentence: "Pay in cash.", exampleTranslation: "Плати готівкою.", synonyms: ["money"], difficulty: .a2),
        Word(id: "a2_231", original: "cast", translation: "акторський склад", transcription: "/kæst/", exampleSentence: "The movie cast.", exampleTranslation: "Акторський склад фільму.", synonyms: ["actors"], difficulty: .a2),
        Word(id: "a2_232", original: "castle", translation: "замок", transcription: "/ˈkæsl/", exampleSentence: "A medieval castle.", exampleTranslation: "Середньовічний замок.", synonyms: ["palace"], difficulty: .a2),
        Word(id: "a2_233", original: "cat", translation: "кіт", transcription: "/kæt/", exampleSentence: "I have a cat.", exampleTranslation: "У мене є кіт.", synonyms: ["feline"], difficulty: .a2),
        Word(id: "a2_234", original: "catch", translation: "ловити", transcription: "/kætʃ/", exampleSentence: "Catch the ball.", exampleTranslation: "Лови м'яч.", synonyms: ["grab"], difficulty: .a2),
        Word(id: "a2_235", original: "category", translation: "категорія", transcription: "/ˈkætəɡɔːri/", exampleSentence: "What category?", exampleTranslation: "Яка категорія?", synonyms: ["class", "type"], difficulty: .a2),
        Word(id: "a2_236", original: "cause", translation: "причина", transcription: "/kɔːz/", exampleSentence: "What's the cause?", exampleTranslation: "Яка причина?", synonyms: ["reason"], difficulty: .a2),
        Word(id: "a2_237", original: "ceiling", translation: "стеля", transcription: "/ˈsiːlɪŋ/", exampleSentence: "Paint the ceiling.", exampleTranslation: "Пофарбуй стелю.", synonyms: [], difficulty: .a2),
        Word(id: "a2_238", original: "celebrate", translation: "святкувати", transcription: "/ˈselɪbreɪt/", exampleSentence: "Let's celebrate!", exampleTranslation: "Давай святкувати!", synonyms: ["commemorate"], difficulty: .a2),
        Word(id: "a2_239", original: "celebrity", translation: "знаменитість", transcription: "/səˈlebrəti/", exampleSentence: "A famous celebrity.", exampleTranslation: "Відома знаменитість.", synonyms: ["star"], difficulty: .a2),
        Word(id: "a2_240", original: "cell", translation: "клітина", transcription: "/sel/", exampleSentence: "A prison cell.", exampleTranslation: "В'язнична камера.", synonyms: [], difficulty: .a2),
        Word(id: "a2_241", original: "cent", translation: "цент", transcription: "/sent/", exampleSentence: "It costs 50 cents.", exampleTranslation: "Це коштує 50 центів.", synonyms: ["penny"], difficulty: .a2),
        Word(id: "a2_242", original: "center", translation: "центр", transcription: "/ˈsentər/", exampleSentence: "In the center.", exampleTranslation: "В центрі.", synonyms: ["middle"], difficulty: .a2),
        Word(id: "a2_243", original: "century", translation: "століття", transcription: "/ˈsentʃəri/", exampleSentence: "The 21st century.", exampleTranslation: "21 століття.", synonyms: [], difficulty: .a2),
        Word(id: "a2_244", original: "ceremony", translation: "церемонія", transcription: "/ˈserəmoʊni/", exampleSentence: "A wedding ceremony.", exampleTranslation: "Весільна церемонія.", synonyms: ["ritual"], difficulty: .a2),
        Word(id: "a2_245", original: "certain", translation: "певний", transcription: "/ˈsɜːrtn/", exampleSentence: "I'm certain.", exampleTranslation: "Я певен.", synonyms: ["sure"], difficulty: .a2),
        Word(id: "a2_246", original: "chain", translation: "ланцюг", transcription: "/tʃeɪn/", exampleSentence: "A chain of stores.", exampleTranslation: "Мережа магазинів.", synonyms: ["series"], difficulty: .a2),
        Word(id: "a2_247", original: "chair", translation: "стілець", transcription: "/tʃer/", exampleSentence: "Sit on the chair.", exampleTranslation: "Сідай на стілець.", synonyms: ["seat"], difficulty: .a2),
        Word(id: "a2_248", original: "chairman", translation: "голова", transcription: "/ˈtʃermən/", exampleSentence: "The chairman spoke.", exampleTranslation: "Голова виступив.", synonyms: ["president"], difficulty: .a2),
        Word(id: "a2_249", original: "challenge", translation: "виклик", transcription: "/ˈtʃælɪndʒ/", exampleSentence: "Accept the challenge.", exampleTranslation: "Прийми виклик.", synonyms: ["dare"], difficulty: .a2),
        Word(id: "a2_250", original: "champion", translation: "чемпіон", transcription: "/ˈtʃæmpiən/", exampleSentence: "He is the champion.", exampleTranslation: "Він чемпіон.", synonyms: ["winner"], difficulty: .a2),
        Word(id: "a2_251", original: "chance", translation: "шанс", transcription: "/tʃæns/", exampleSentence: "Give me a chance.", exampleTranslation: "Дай мені шанс.", synonyms: ["opportunity"], difficulty: .a2),
        Word(id: "a2_252", original: "change", translation: "зміна", transcription: "/tʃeɪndʒ/", exampleSentence: "Time for a change.", exampleTranslation: "Час змін.", synonyms: ["alteration"], difficulty: .a2),
        Word(id: "a2_253", original: "channel", translation: "канал", transcription: "/ˈtʃænl/", exampleSentence: "Change the channel.", exampleTranslation: "Перемкни канал.", synonyms: [], difficulty: .a2),
        Word(id: "a2_254", original: "chapter", translation: "розділ", transcription: "/ˈtʃæptər/", exampleSentence: "Read chapter 5.", exampleTranslation: "Прочитай розділ 5.", synonyms: ["section"], difficulty: .a2),
        Word(id: "a2_255", original: "character", translation: "характер", transcription: "/ˈkærəktər/", exampleSentence: "He has good character.", exampleTranslation: "У нього хороший характер.", synonyms: ["personality"], difficulty: .a2),
        Word(id: "a2_256", original: "charge", translation: "заряд", transcription: "/tʃɑːrdʒ/", exampleSentence: "Is there a charge?", exampleTranslation: "Чи є плата?", synonyms: ["fee"], difficulty: .a2),
        Word(id: "a2_257", original: "charity", translation: "благодійність", transcription: "/ˈtʃærəti/", exampleSentence: "Give to charity.", exampleTranslation: "Пожертвуй на благодійність.", synonyms: [], difficulty: .a2),
        Word(id: "a2_258", original: "charm", translation: "чарівність", transcription: "/tʃɑːrm/", exampleSentence: "She has charm.", exampleTranslation: "У неї є чарівність.", synonyms: ["appeal"], difficulty: .a2),
        Word(id: "a2_259", original: "chase", translation: "переслідувати", transcription: "/tʃeɪs/", exampleSentence: "Chase your dreams.", exampleTranslation: "Переслідуй свої мрії.", synonyms: ["pursue"], difficulty: .a2),
        Word(id: "a2_260", original: "chat", translation: "балакати", transcription: "/tʃæt/", exampleSentence: "Let's have a chat.", exampleTranslation: "Давай побалакаємо.", synonyms: ["talk"], difficulty: .a2),
        Word(id: "a2_261", original: "cheap", translation: "дешевий", transcription: "/tʃiːp/", exampleSentence: "It's very cheap.", exampleTranslation: "Це дуже дешево.", synonyms: ["inexpensive"], difficulty: .a2),
        Word(id: "a2_262", original: "cheat", translation: "обманювати", transcription: "/tʃiːt/", exampleSentence: "Don't cheat!", exampleTranslation: "Не обманюй!", synonyms: ["deceive"], difficulty: .a2),
        Word(id: "a2_263", original: "check", translation: "перевіряти", transcription: "/tʃek/", exampleSentence: "Check your email.", exampleTranslation: "Перевір пошту.", synonyms: ["examine"], difficulty: .a2),
        Word(id: "a2_264", original: "cheek", translation: "щока", transcription: "/tʃiːk/", exampleSentence: "Kiss on the cheek.", exampleTranslation: "Поцілунок в щоку.", synonyms: [], difficulty: .a2),
        Word(id: "a2_265", original: "cheer", translation: "вболівати", transcription: "/tʃɪr/", exampleSentence: "Cheer for the team.", exampleTranslation: "Вболівай за команду.", synonyms: ["applaud"], difficulty: .a2),
        Word(id: "a2_266", original: "cheese", translation: "сир", transcription: "/tʃiːz/", exampleSentence: "I love cheese.", exampleTranslation: "Я люблю сир.", synonyms: [], difficulty: .a2),
        Word(id: "a2_267", original: "chef", translation: "шеф-кухар", transcription: "/ʃef/", exampleSentence: "The chef cooked dinner.", exampleTranslation: "Шеф приготував вечерю.", synonyms: ["cook"], difficulty: .a2),
        Word(id: "a2_268", original: "chemical", translation: "хімічний", transcription: "/ˈkemɪkl/", exampleSentence: "Chemical reaction.", exampleTranslation: "Хімічна реакція.", synonyms: [], difficulty: .a2),
        Word(id: "a2_269", original: "chest", translation: "груди", transcription: "/tʃest/", exampleSentence: "Pain in the chest.", exampleTranslation: "Біль у грудях.", synonyms: ["torso"], difficulty: .a2),
        Word(id: "a2_270", original: "chicken", translation: "курка", transcription: "/ˈtʃɪkɪn/", exampleSentence: "Fried chicken.", exampleTranslation: "Смажена курка.", synonyms: [], difficulty: .a2),
        Word(id: "a2_271", original: "chief", translation: "головний", transcription: "/tʃiːf/", exampleSentence: "The chief officer.", exampleTranslation: "Головний офіцер.", synonyms: ["main"], difficulty: .a2),
        Word(id: "a2_272", original: "child", translation: "дитина", transcription: "/tʃaɪld/", exampleSentence: "A happy child.", exampleTranslation: "Щаслива дитина.", synonyms: ["kid"], difficulty: .a2),
        Word(id: "a2_273", original: "childhood", translation: "дитинство", transcription: "/ˈtʃaɪldhʊd/", exampleSentence: "My happy childhood.", exampleTranslation: "Моє щасливе дитинство.", synonyms: ["youth"], difficulty: .a2),
        Word(id: "a2_274", original: "chip", translation: "чіп", transcription: "/tʃɪp/", exampleSentence: "Computer chip.", exampleTranslation: "Комп'ютерний чіп.", synonyms: [], difficulty: .a2),
        Word(id: "a2_275", original: "chocolate", translation: "шоколад", transcription: "/ˈtʃɔːklət/", exampleSentence: "I love chocolate.", exampleTranslation: "Я люблю шоколад.", synonyms: [], difficulty: .a2),
        Word(id: "a2_276", original: "choice", translation: "вибір", transcription: "/tʃɔɪs/", exampleSentence: "Make a choice.", exampleTranslation: "Зроби вибір.", synonyms: ["option"], difficulty: .a2),
        Word(id: "a2_277", original: "choose", translation: "вибирати", transcription: "/tʃuːz/", exampleSentence: "Choose wisely.", exampleTranslation: "Вибирай мудро.", synonyms: ["select", "pick"], difficulty: .a2),
        Word(id: "a2_278", original: "church", translation: "церква", transcription: "/tʃɜːrtʃ/", exampleSentence: "Go to church.", exampleTranslation: "Йди до церкви.", synonyms: [], difficulty: .a2),
        Word(id: "a2_279", original: "cigarette", translation: "сигарета", transcription: "/ˌsɪɡəˈret/", exampleSentence: "Stop smoking cigarettes.", exampleTranslation: "Кинь курити сигарети.", synonyms: [], difficulty: .a2),
        Word(id: "a2_280", original: "cinema", translation: "кінотеатр", transcription: "/ˈsɪnəmə/", exampleSentence: "Let's go to the cinema.", exampleTranslation: "Підемо в кіно.", synonyms: ["movies"], difficulty: .a2),
        Word(id: "a2_281", original: "circle", translation: "коло", transcription: "/ˈsɜːrkl/", exampleSentence: "Draw a circle.", exampleTranslation: "Намалюй коло.", synonyms: ["ring"], difficulty: .a2),
        Word(id: "a2_282", original: "circumstance", translation: "обставина", transcription: "/ˈsɜːrkəmstæns/", exampleSentence: "Under the circumstances...", exampleTranslation: "За цих обставин...", synonyms: ["condition"], difficulty: .a2),
        Word(id: "a2_283", original: "citizen", translation: "громадянин", transcription: "/ˈsɪtɪzn/", exampleSentence: "I am a citizen.", exampleTranslation: "Я громадянин.", synonyms: ["national"], difficulty: .a2),
        Word(id: "a2_284", original: "city", translation: "місто", transcription: "/ˈsɪti/", exampleSentence: "A big city.", exampleTranslation: "Велике місто.", synonyms: ["town"], difficulty: .a2),
        Word(id: "a2_285", original: "civil", translation: "цивільний", transcription: "/ˈsɪvl/", exampleSentence: "Civil rights.", exampleTranslation: "Громадянські права.", synonyms: [], difficulty: .a2),
        Word(id: "a2_286", original: "claim", translation: "заява", transcription: "/kleɪm/", exampleSentence: "Make a claim.", exampleTranslation: "Подай заяву.", synonyms: ["demand"], difficulty: .a2),
        Word(id: "a2_287", original: "class", translation: "клас", transcription: "/klæs/", exampleSentence: "English class.", exampleTranslation: "Урок англійської.", synonyms: ["lesson"], difficulty: .a2),
        Word(id: "a2_288", original: "classic", translation: "класичний", transcription: "/ˈklæsɪk/", exampleSentence: "A classic movie.", exampleTranslation: "Класичний фільм.", synonyms: ["traditional"], difficulty: .a2),
        Word(id: "a2_289", original: "classroom", translation: "клас", transcription: "/ˈklæsruːm/", exampleSentence: "In the classroom.", exampleTranslation: "В класі.", synonyms: [], difficulty: .a2),
        Word(id: "a2_290", original: "clean", translation: "чистити", transcription: "/kliːn/", exampleSentence: "Clean your room.", exampleTranslation: "Прибери кімнату.", synonyms: ["tidy"], difficulty: .a2),
        Word(id: "a2_291", original: "clear", translation: "чистий", transcription: "/klɪr/", exampleSentence: "The sky is clear.", exampleTranslation: "Небо чисте.", synonyms: ["transparent"], difficulty: .a2),
        Word(id: "a2_292", original: "clearly", translation: "чітко", transcription: "/ˈklɪrli/", exampleSentence: "Speak clearly.", exampleTranslation: "Говори чітко.", synonyms: ["obviously"], difficulty: .a2),
        Word(id: "a2_293", original: "clever", translation: "розумний", transcription: "/ˈklevər/", exampleSentence: "You are clever.", exampleTranslation: "Ти розумний.", synonyms: ["smart"], difficulty: .a2),
        Word(id: "a2_294", original: "click", translation: "клік", transcription: "/klɪk/", exampleSentence: "Click the button.", exampleTranslation: "Клікни кнопку.", synonyms: [], difficulty: .a2),
        Word(id: "a2_295", original: "client", translation: "клієнт", transcription: "/ˈklaɪənt/", exampleSentence: "Our client is happy.", exampleTranslation: "Наш клієнт задоволений.", synonyms: ["customer"], difficulty: .a2),
        Word(id: "a2_296", original: "climate", translation: "клімат", transcription: "/ˈklaɪmət/", exampleSentence: "The climate is changing.", exampleTranslation: "Клімат змінюється.", synonyms: ["weather"], difficulty: .a2),
        Word(id: "a2_297", original: "climb", translation: "лазити", transcription: "/klaɪm/", exampleSentence: "Climb the mountain.", exampleTranslation: "Залізь на гору.", synonyms: ["ascend"], difficulty: .a2),
        Word(id: "a2_298", original: "clinic", translation: "клініка", transcription: "/ˈklɪnɪk/", exampleSentence: "Go to the clinic.", exampleTranslation: "Йди до клініки.", synonyms: ["hospital"], difficulty: .a2),
        Word(id: "a2_299", original: "clock", translation: "годинник", transcription: "/klɑːk/", exampleSentence: "Look at the clock.", exampleTranslation: "Подивись на годинник.", synonyms: ["timepiece"], difficulty: .a2),
        Word(id: "a2_300", original: "close", translation: "близький", transcription: "/kloʊs/", exampleSentence: "Stay close to me.", exampleTranslation: "Залишайся близько до мене.", synonyms: ["near"], difficulty: .a2),
        Word(id: "a2_301", original: "closely", translation: "уважно", transcription: "/ˈkloʊsli/", exampleSentence: "Watch closely.", exampleTranslation: "Дивись уважно.", synonyms: ["carefully"], difficulty: .a2),
        Word(id: "a2_302", original: "clothes", translation: "одяг", transcription: "/kloʊðz/", exampleSentence: "Put on your clothes.", exampleTranslation: "Одягнися.", synonyms: ["clothing"], difficulty: .a2),
        Word(id: "a2_303", original: "cloud", translation: "хмара", transcription: "/klaʊd/", exampleSentence: "A dark cloud.", exampleTranslation: "Темна хмара.", synonyms: [], difficulty: .a2),
        Word(id: "a2_304", original: "club", translation: "клуб", transcription: "/klʌb/", exampleSentence: "Join the club.", exampleTranslation: "Вступи в клуб.", synonyms: ["society"], difficulty: .a2),
        Word(id: "a2_305", original: "clue", translation: "підказка", transcription: "/kluː/", exampleSentence: "Find a clue.", exampleTranslation: "Знайди підказку.", synonyms: ["hint"], difficulty: .a2),
        Word(id: "a2_306", original: "coach", translation: "тренер", transcription: "/koʊtʃ/", exampleSentence: "The team coach.", exampleTranslation: "Тренер команди.", synonyms: ["trainer"], difficulty: .a2),
        Word(id: "a2_307", original: "coal", translation: "вугілля", transcription: "/koʊl/", exampleSentence: "Burning coal.", exampleTranslation: "Палаюче вугілля.", synonyms: [], difficulty: .a2),
        Word(id: "a2_308", original: "coast", translation: "узбережжя", transcription: "/koʊst/", exampleSentence: "The west coast.", exampleTranslation: "Західне узбережжя.", synonyms: ["shore"], difficulty: .a2),
        Word(id: "a2_309", original: "coat", translation: "пальто", transcription: "/koʊt/", exampleSentence: "Wear a warm coat.", exampleTranslation: "Носи тепле пальто.", synonyms: ["jacket"], difficulty: .a2),
        Word(id: "a2_310", original: "code", translation: "код", transcription: "/koʊd/", exampleSentence: "Enter the code.", exampleTranslation: "Введи код.", synonyms: ["password"], difficulty: .a2),
        Word(id: "a2_311", original: "coffee", translation: "кава", transcription: "/ˈkɔːfi/", exampleSentence: "A cup of coffee.", exampleTranslation: "Чашка кави.", synonyms: [], difficulty: .a2),
        Word(id: "a2_312", original: "coin", translation: "монета", transcription: "/kɔɪn/", exampleSentence: "Flip a coin.", exampleTranslation: "Підкинь монету.", synonyms: [], difficulty: .a2),
        Word(id: "a2_313", original: "cold", translation: "холодний", transcription: "/koʊld/", exampleSentence: "It's cold outside.", exampleTranslation: "На вулиці холодно.", synonyms: ["chilly"], difficulty: .a2),
        Word(id: "a2_314", original: "collapse", translation: "обвал", transcription: "/kəˈlæps/", exampleSentence: "The building collapsed.", exampleTranslation: "Будівля обвалилася.", synonyms: ["fall down"], difficulty: .a2),
        Word(id: "a2_315", original: "colleague", translation: "колега", transcription: "/ˈkɑːliːɡ/", exampleSentence: "My colleague helped me.", exampleTranslation: "Мій колега допоміг мені.", synonyms: ["coworker"], difficulty: .a2),
        Word(id: "a2_316", original: "collect", translation: "збирати", transcription: "/kəˈlekt/", exampleSentence: "Collect stamps.", exampleTranslation: "Збирай марки.", synonyms: ["gather"], difficulty: .a2),
        Word(id: "a2_317", original: "collection", translation: "колекція", transcription: "/kəˈlekʃn/", exampleSentence: "A coin collection.", exampleTranslation: "Колекція монет.", synonyms: ["set"], difficulty: .a2),
        Word(id: "a2_318", original: "college", translation: "коледж", transcription: "/ˈkɑːlɪdʒ/", exampleSentence: "Go to college.", exampleTranslation: "Йди до коледжу.", synonyms: ["university"], difficulty: .a2),
        Word(id: "a2_319", original: "color", translation: "колір", transcription: "/ˈkʌlər/", exampleSentence: "What color?", exampleTranslation: "Який колір?", synonyms: ["hue"], difficulty: .a2),
        Word(id: "a2_320", original: "combination", translation: "комбінація", transcription: "/ˌkɑːmbɪˈneɪʃn/", exampleSentence: "A winning combination.", exampleTranslation: "Виграшна комбінація.", synonyms: ["mix"], difficulty: .a2),
    ]
    
    // B1 — 400 слів
    static let b1Words: [Word] = [
        Word(id: "b1_001", original: "abandon", translation: "покидати", transcription: "/əˈbændən/", exampleSentence: "Don't abandon hope.", exampleTranslation: "Не покидай надію.", synonyms: ["desert", "leave"], difficulty: .b1),
        Word(id: "b1_002", original: "ability", translation: "здатність", transcription: "/əˈbɪləti/", exampleSentence: "She has the ability to sing.", exampleTranslation: "Вона має здатність співати.", synonyms: ["talent", "skill"], difficulty: .b1),
        Word(id: "b1_003", original: "abroad", translation: "за кордоном", transcription: "/əˈbrɔːd/", exampleSentence: "I want to study abroad.", exampleTranslation: "Я хочу вчитися за кордоном.", synonyms: ["overseas"], difficulty: .b1),
        Word(id: "b1_004", original: "absence", translation: "відсутність", transcription: "/ˈæbsəns/", exampleSentence: "In your absence...", exampleTranslation: "За твоєї відсутності...", synonyms: ["lack"], difficulty: .b1),
        Word(id: "b1_005", original: "absolute", translation: "абсолютний", transcription: "/ˈæbsəluːt/", exampleSentence: "Absolute silence.", exampleTranslation: "Абсолютна тиша.", synonyms: ["complete"], difficulty: .b1),
        Word(id: "b1_006", original: "absorb", translation: "вбирати", transcription: "/əbˈzɔːrb/", exampleSentence: "The sponge absorbs water.", exampleTranslation: "Губка вбирає воду.", synonyms: ["soak up"], difficulty: .b1),
        Word(id: "b1_007", original: "abstract", translation: "абстрактний", transcription: "/ˈæbstrækt/", exampleSentence: "Abstract art.", exampleTranslation: "Абстрактне мистецтво.", synonyms: ["theoretical"], difficulty: .b1),
        Word(id: "b1_008", original: "abuse", translation: "зловживання", transcription: "/əˈbjuːs/", exampleSentence: "Stop the abuse.", exampleTranslation: "Припини зловживання.", synonyms: ["misuse"], difficulty: .b1),
        Word(id: "b1_009", original: "academic", translation: "академічний", transcription: "/ˌækəˈdemɪk/", exampleSentence: "Academic year.", exampleTranslation: "Академічний рік.", synonyms: ["scholarly"], difficulty: .b1),
        Word(id: "b1_010", original: "accelerate", translation: "прискорювати", transcription: "/əkˈseləreɪt/", exampleSentence: "Accelerate the process.", exampleTranslation: "Прискор процес.", synonyms: ["speed up"], difficulty: .b1),
        Word(id: "b1_011", original: "accent", translation: "акцент", transcription: "/ˈæksent/", exampleSentence: "She has a British accent.", exampleTranslation: "У неї британський акцент.", synonyms: ["pronunciation"], difficulty: .b1),
        Word(id: "b1_012", original: "acceptable", translation: "прийнятний", transcription: "/əkˈseptəbl/", exampleSentence: "This is acceptable.", exampleTranslation: "Це прийнятно.", synonyms: ["satisfactory"], difficulty: .b1),
        Word(id: "b1_013", original: "access", translation: "доступ", transcription: "/ˈækses/", exampleSentence: "Gain access to data.", exampleTranslation: "Отримай доступ до даних.", synonyms: ["entry"], difficulty: .b1),
        Word(id: "b1_014", original: "accident", translation: "нещасний випадок", transcription: "/ˈæksɪdənt/", exampleSentence: "It was an accident.", exampleTranslation: "Це був нещасний випадок.", synonyms: ["crash"], difficulty: .b1),
        Word(id: "b1_015", original: "accompany", translation: "супроводжувати", transcription: "/əˈkʌmpəni/", exampleSentence: "She accompanied me.", exampleTranslation: "Вона супроводжувала мене.", synonyms: ["go with"], difficulty: .b1),
        Word(id: "b1_016", original: "accomplish", translation: "виконувати", transcription: "/əˈkʌmplɪʃ/", exampleSentence: "Accomplish your goals.", exampleTranslation: "Виконуй свої цілі.", synonyms: ["achieve"], difficulty: .b1),
        Word(id: "b1_017", original: "accordance", translation: "відповідно", transcription: "/əˈkɔːrdns/", exampleSentence: "In accordance with rules.", exampleTranslation: "Відповідно до правил.", synonyms: ["conformity"], difficulty: .b1),
        Word(id: "b1_018", original: "according", translation: "згідно", transcription: "/əˈkɔːrdɪŋ/", exampleSentence: "According to plan.", exampleTranslation: "Згідно з планом.", synonyms: [], difficulty: .b1),
        Word(id: "b1_019", original: "account", translation: "рахунок", transcription: "/əˈkaʊnt/", exampleSentence: "Bank account.", exampleTranslation: "Банківський рахунок.", synonyms: ["report"], difficulty: .b1),
        Word(id: "b1_020", original: "accumulate", translation: "накопичувати", transcription: "/əˈkjuːmjəleɪt/", exampleSentence: "Accumulate wealth.", exampleTranslation: "Накопичуй багатство.", synonyms: ["gather"], difficulty: .b1),
        Word(id: "b1_021", original: "accuracy", translation: "точність", transcription: "/ˈækjərəsi/", exampleSentence: "With great accuracy.", exampleTranslation: "З великою точністю.", synonyms: ["precision"], difficulty: .b1),
        Word(id: "b1_022", original: "accurate", translation: "точний", transcription: "/ˈækjərət/", exampleSentence: "The report is accurate.", exampleTranslation: "Звіт точний.", synonyms: ["correct"], difficulty: .b1),
        Word(id: "b1_023", original: "accuse", translation: "звинувачувати", transcription: "/əˈkjuːz/", exampleSentence: "They accused him of theft.", exampleTranslation: "Вони звинуватили його в крадіжці.", synonyms: ["blame"], difficulty: .b1),
        Word(id: "b1_024", original: "achieve", translation: "досягати", transcription: "/əˈtʃiːv/", exampleSentence: "Achieve success.", exampleTranslation: "Досягни успіху.", synonyms: ["accomplish"], difficulty: .b1),
        Word(id: "b1_025", original: "achievement", translation: "досягнення", transcription: "/əˈtʃiːvmənt/", exampleSentence: "A great achievement.", exampleTranslation: "Велике досягнення.", synonyms: ["accomplishment"], difficulty: .b1),
        Word(id: "b1_026", original: "acid", translation: "кислота", transcription: "/ˈæsɪd/", exampleSentence: "Strong acid.", exampleTranslation: "Сильна кислота.", synonyms: [], difficulty: .b1),
        Word(id: "b1_027", original: "acknowledge", translation: "визнавати", transcription: "/əkˈnɑːlɪdʒ/", exampleSentence: "I acknowledge my mistake.", exampleTranslation: "Я визнаю свою помилку.", synonyms: ["admit"], difficulty: .b1),
        Word(id: "b1_028", original: "acquire", translation: "набувати", transcription: "/əˈkwaɪər/", exampleSentence: "Acquire new skills.", exampleTranslation: "Набувай нові навички.", synonyms: ["obtain"], difficulty: .b1),
        Word(id: "b1_029", original: "acquisition", translation: "придбання", transcription: "/ˌækwɪˈzɪʃn/", exampleSentence: "The acquisition of property.", exampleTranslation: "Придбання майна.", synonyms: ["purchase"], difficulty: .b1),
        Word(id: "b1_030", original: "acre", translation: "акр", transcription: "/ˈeɪkər/", exampleSentence: "Ten acres of land.", exampleTranslation: "Десять акрів землі.", synonyms: [], difficulty: .b1),
        Word(id: "b1_031", original: "across", translation: "через", transcription: "/əˈkrɔːs/", exampleSentence: "Walk across the street.", exampleTranslation: "Перейди через вулицю.", synonyms: ["through"], difficulty: .b1),
        Word(id: "b1_032", original: "act", translation: "діяти", transcription: "/ækt/", exampleSentence: "Act quickly!", exampleTranslation: "Дій швидко!", synonyms: ["behave"], difficulty: .b1),
        Word(id: "b1_033", original: "action", translation: "дія", transcription: "/ˈækʃn/", exampleSentence: "Take action now.", exampleTranslation: "Дій зараз.", synonyms: ["deed"], difficulty: .b1),
        Word(id: "b1_034", original: "active", translation: "активний", transcription: "/ˈæktɪv/", exampleSentence: "Lead an active lifestyle.", exampleTranslation: "Веди активний спосіб життя.", synonyms: ["energetic"], difficulty: .b1),
        Word(id: "b1_035", original: "activist", translation: "активіст", transcription: "/ˈæktɪvɪst/", exampleSentence: "A political activist.", exampleTranslation: "Політичний активіст.", synonyms: ["campaigner"], difficulty: .b1),
        Word(id: "b1_036", original: "activity", translation: "діяльність", transcription: "/ækˈtɪvəti/", exampleSentence: "Physical activity.", exampleTranslation: "Фізична активність.", synonyms: ["pursuit"], difficulty: .b1),
        Word(id: "b1_037", original: "actor", translation: "актор", transcription: "/ˈæktər/", exampleSentence: "A famous actor.", exampleTranslation: "Відомий актор.", synonyms: ["performer"], difficulty: .b1),
        Word(id: "b1_038", original: "actual", translation: "фактичний", transcription: "/ˈæktʃuəl/", exampleSentence: "The actual cost.", exampleTranslation: "Фактична вартість.", synonyms: ["real"], difficulty: .b1),
        Word(id: "b1_039", original: "actually", translation: "насправді", transcription: "/ˈæktʃuəli/", exampleSentence: "Actually, I disagree.", exampleTranslation: "Насправді, я не згоден.", synonyms: ["in fact"], difficulty: .b1),
        Word(id: "b1_040", original: "acute", translation: "гострий", transcription: "/əˈkjuːt/", exampleSentence: "Acute pain.", exampleTranslation: "Гострий біль.", synonyms: ["sharp"], difficulty: .b1),
        Word(id: "b1_041", original: "adapt", translation: "адаптуватися", transcription: "/əˈdæpt/", exampleSentence: "Adapt to changes.", exampleTranslation: "Адаптуйся до змін.", synonyms: ["adjust"], difficulty: .b1),
        Word(id: "b1_042", original: "addition", translation: "додавання", transcription: "/əˈdɪʃn/", exampleSentence: "In addition to...", exampleTranslation: "На додаток до...", synonyms: ["extra"], difficulty: .b1),
        Word(id: "b1_043", original: "additional", translation: "додатковий", transcription: "/əˈdɪʃənl/", exampleSentence: "Additional information.", exampleTranslation: "Додаткова інформація.", synonyms: ["extra"], difficulty: .b1),
        Word(id: "b1_044", original: "address", translation: "адреса", transcription: "/əˈdres/", exampleSentence: "What's your address?", exampleTranslation: "Яка твоя адреса?", synonyms: ["speech"], difficulty: .b1),
        Word(id: "b1_045", original: "adequate", translation: "адекватний", transcription: "/ˈædɪkwət/", exampleSentence: "Adequate resources.", exampleTranslation: "Адекватні ресурси.", synonyms: ["sufficient"], difficulty: .b1),
        Word(id: "b1_046", original: "adjust", translation: "налаштовувати", transcription: "/əˈdʒʌst/", exampleSentence: "Adjust the settings.", exampleTranslation: "Налаштуй параметри.", synonyms: ["modify"], difficulty: .b1),
        Word(id: "b1_047", original: "adjustment", translation: "налаштування", transcription: "/əˈdʒʌstmənt/", exampleSentence: "Make an adjustment.", exampleTranslation: "Зроби налаштування.", synonyms: ["change"], difficulty: .b1),
        Word(id: "b1_048", original: "administration", translation: "адміністрація", transcription: "/ədˌmɪnɪˈstreɪʃn/", exampleSentence: "The school administration.", exampleTranslation: "Шкільна адміністрація.", synonyms: ["management"], difficulty: .b1),
        Word(id: "b1_049", original: "administrative", translation: "адміністративний", transcription: "/ədˈmɪnɪstreɪtɪv/", exampleSentence: "Administrative work.", exampleTranslation: "Адміністративна робота.", synonyms: [], difficulty: .b1),
        Word(id: "b1_050", original: "admire", translation: "захоплюватися", transcription: "/ədˈmaɪər/", exampleSentence: "I admire your courage.", exampleTranslation: "Я захоплююсь твоєю сміливістю.", synonyms: ["respect"], difficulty: .b1),
        Word(id: "b1_051", original: "admission", translation: "вступ", transcription: "/ədˈmɪʃn/", exampleSentence: "Admission to university.", exampleTranslation: "Вступ до університету.", synonyms: ["entry"], difficulty: .b1),
        Word(id: "b1_052", original: "admit", translation: "визнавати", transcription: "/ədˈmɪt/", exampleSentence: "I admit I was wrong.", exampleTranslation: "Я визнаю, що був неправий.", synonyms: ["confess"], difficulty: .b1),
        Word(id: "b1_053", original: "adolescent", translation: "підліток", transcription: "/ˌædəˈlesnt/", exampleSentence: "An adolescent boy.", exampleTranslation: "Підліток-хлопець.", synonyms: ["teenager"], difficulty: .b1),
        Word(id: "b1_054", original: "adopt", translation: "усиновлювати", transcription: "/əˈdɑːpt/", exampleSentence: "Adopt a child.", exampleTranslation: "Усинови дитину.", synonyms: ["take in"], difficulty: .b1),
        Word(id: "b1_055", original: "adoption", translation: "усиновлення", transcription: "/əˈdɑːpʃn/", exampleSentence: "The adoption process.", exampleTranslation: "Процес усиновлення.", synonyms: [], difficulty: .b1),
        Word(id: "b1_056", original: "adult", translation: "дорослий", transcription: "/əˈdʌlt/", exampleSentence: "An adult person.", exampleTranslation: "Доросла людина.", synonyms: ["grown-up"], difficulty: .b1),
        Word(id: "b1_057", original: "advance", translation: "просуватися", transcription: "/ədˈvæns/", exampleSentence: "Advance in your career.", exampleTranslation: "Просувайся в кар'єрі.", synonyms: ["progress"], difficulty: .b1),
        Word(id: "b1_058", original: "advanced", translation: "просунутий", transcription: "/ədˈvænst/", exampleSentence: "Advanced level.", exampleTranslation: "Просунутий рівень.", synonyms: ["sophisticated"], difficulty: .b1),
        Word(id: "b1_059", original: "advantage", translation: "перевага", transcription: "/ədˈvæntɪdʒ/", exampleSentence: "Take advantage of this.", exampleTranslation: "Скористайся цим.", synonyms: ["benefit"], difficulty: .b1),
        Word(id: "b1_060", original: "adventure", translation: "пригода", transcription: "/ədˈventʃər/", exampleSentence: "An exciting adventure.", exampleTranslation: "Захоплююча пригода.", synonyms: ["expedition"], difficulty: .b1),
        Word(id: "b1_061", original: "advertising", translation: "реклама", transcription: "/ˈædvərtaɪzɪŋ/", exampleSentence: "Work in advertising.", exampleTranslation: "Працюй в рекламі.", synonyms: ["promotion"], difficulty: .b1),
        Word(id: "b1_062", original: "advice", translation: "порада", transcription: "/ədˈvaɪs/", exampleSentence: "Give me some advice.", exampleTranslation: "Дай мені пораду.", synonyms: ["guidance"], difficulty: .b1),
        Word(id: "b1_063", original: "advise", translation: "радити", transcription: "/ədˈvaɪz/", exampleSentence: "I advise you to wait.", exampleTranslation: "Я раджу тобі почекати.", synonyms: ["recommend"], difficulty: .b1),
        Word(id: "b1_064", original: "advocate", translation: "адвокат", transcription: "/ˈædvəkeɪt/", exampleSentence: "An advocate for peace.", exampleTranslation: "Адвокат миру.", synonyms: ["supporter"], difficulty: .b1),
        Word(id: "b1_065", original: "affair", translation: "справа", transcription: "/əˈfer/", exampleSentence: "A private affair.", exampleTranslation: "Приватна справа.", synonyms: ["matter"], difficulty: .b1),
        Word(id: "b1_066", original: "affect", translation: "впливати", transcription: "/əˈfekt/", exampleSentence: "This will affect us all.", exampleTranslation: "Це вплине на всіх нас.", synonyms: ["influence"], difficulty: .b1),
        Word(id: "b1_067", original: "afford", translation: "дозволити собі", transcription: "/əˈfɔːrd/", exampleSentence: "I can't afford it.", exampleTranslation: "Я не можу собі це дозволити.", synonyms: [], difficulty: .b1),
        Word(id: "b1_068", original: "afraid", translation: "боятися", transcription: "/əˈfreɪd/", exampleSentence: "Don't be afraid.", exampleTranslation: "Не бійся.", synonyms: ["scared"], difficulty: .b1),
        Word(id: "b1_069", original: "after", translation: "після", transcription: "/ˈæftər/", exampleSentence: "After dinner.", exampleTranslation: "Після вечері.", synonyms: ["following"], difficulty: .b1),
        Word(id: "b1_070", original: "afternoon", translation: "післяполудень", transcription: "/ˌæftərˈnuːn/", exampleSentence: "Good afternoon!", exampleTranslation: "Добрий день!", synonyms: [], difficulty: .b1),
        Word(id: "b1_071", original: "afterward", translation: "пізніше", transcription: "/ˈæftərwərd/", exampleSentence: "Shortly afterward...", exampleTranslation: "Незабаром після цього...", synonyms: ["later"], difficulty: .b1),
        Word(id: "b1_072", original: "again", translation: "знову", transcription: "/əˈɡen/", exampleSentence: "Try again.", exampleTranslation: "Спробуй знову.", synonyms: ["once more"], difficulty: .b1),
        Word(id: "b1_073", original: "against", translation: "проти", transcription: "/əˈɡenst/", exampleSentence: "Fight against injustice.", exampleTranslation: "Борись проти несправедливості.", synonyms: ["opposed to"], difficulty: .b1),
        Word(id: "b1_074", original: "age", translation: "вік", transcription: "/eɪdʒ/", exampleSentence: "What is your age?", exampleTranslation: "Який твій вік?", synonyms: ["era"], difficulty: .b1),
        Word(id: "b1_075", original: "agency", translation: "агентство", transcription: "/ˈeɪdʒənsi/", exampleSentence: "A travel agency.", exampleTranslation: "Туристичне агентство.", synonyms: ["bureau"], difficulty: .b1),
        Word(id: "b1_076", original: "agenda", translation: "порядок денний", transcription: "/əˈdʒendə/", exampleSentence: "What's on the agenda?", exampleTranslation: "Що в порядку денному?", synonyms: ["schedule"], difficulty: .b1),
        Word(id: "b1_077", original: "agent", translation: "агент", transcription: "/ˈeɪdʒənt/", exampleSentence: "A secret agent.", exampleTranslation: "Таємний агент.", synonyms: ["representative"], difficulty: .b1),
        Word(id: "b1_078", original: "aggressive", translation: "агресивний", transcription: "/əˈɡresɪv/", exampleSentence: "Aggressive behavior.", exampleTranslation: "Агресивна поведінка.", synonyms: ["hostile"], difficulty: .b1),
        Word(id: "b1_079", original: "ago", translation: "тому", transcription: "/əˈɡoʊ/", exampleSentence: "Long time ago.", exampleTranslation: "Давним-давно.", synonyms: ["past"], difficulty: .b1),
        Word(id: "b1_080", original: "agree", translation: "погоджуватися", transcription: "/əˈɡriː/", exampleSentence: "I agree with you.", exampleTranslation: "Я згоден з тобою.", synonyms: ["concur"], difficulty: .b1),
        Word(id: "b1_081", original: "agreement", translation: "угода", transcription: "/əˈɡriːmənt/", exampleSentence: "Sign the agreement.", exampleTranslation: "Підпиш угоду.", synonyms: ["contract"], difficulty: .b1),
        Word(id: "b1_082", original: "agriculture", translation: "сільське господарство", transcription: "/ˈæɡrɪkʌltʃər/", exampleSentence: "Modern agriculture.", exampleTranslation: "Сучасне сільське господарство.", synonyms: ["farming"], difficulty: .b1),
        Word(id: "b1_083", original: "ahead", translation: "попереду", transcription: "/əˈhed/", exampleSentence: "Go ahead!", exampleTranslation: "Йди вперед!", synonyms: ["forward"], difficulty: .b1),
        Word(id: "b1_084", original: "aid", translation: "допомога", transcription: "/eɪd/", exampleSentence: "Humanitarian aid.", exampleTranslation: "Гуманітарна допомога.", synonyms: ["assistance"], difficulty: .b1),
        Word(id: "b1_085", original: "aim", translation: "ціль", transcription: "/eɪm/", exampleSentence: "What's your aim?", exampleTranslation: "Яка твоя ціль?", synonyms: ["goal"], difficulty: .b1),
        Word(id: "b1_086", original: "air", translation: "повітря", transcription: "/er/", exampleSentence: "Fresh air.", exampleTranslation: "Свіже повітря.", synonyms: ["atmosphere"], difficulty: .b1),
        Word(id: "b1_087", original: "aircraft", translation: "літак", transcription: "/ˈerkræft/", exampleSentence: "Military aircraft.", exampleTranslation: "Військовий літак.", synonyms: ["plane"], difficulty: .b1),
        Word(id: "b1_088", original: "airline", translation: "авіакомпанія", transcription: "/ˈerlaɪn/", exampleSentence: "A major airline.", exampleTranslation: "Велика авіакомпанія.", synonyms: ["carrier"], difficulty: .b1),
        Word(id: "b1_089", original: "airport", translation: "аеропорт", transcription: "/ˈerpɔːrt/", exampleSentence: "At the airport.", exampleTranslation: "В аеропорту.", synonyms: [], difficulty: .b1),
        Word(id: "b1_090", original: "alarm", translation: "тривога", transcription: "/əˈlɑːrm/", exampleSentence: "False alarm.", exampleTranslation: "Хибна тривога.", synonyms: ["alert"], difficulty: .b1),
        Word(id: "b1_091", original: "album", translation: "альбом", transcription: "/ˈælbəm/", exampleSentence: "A photo album.", exampleTranslation: "Фотоальбом.", synonyms: ["collection"], difficulty: .b1),
        Word(id: "b1_092", original: "alcohol", translation: "алкоголь", transcription: "/ˈælkəhɔːl/", exampleSentence: "No alcohol.", exampleTranslation: "Без алкоголю.", synonyms: ["liquor"], difficulty: .b1),
        Word(id: "b1_093", original: "alive", translation: "живий", transcription: "/əˈlaɪv/", exampleSentence: "Stay alive!", exampleTranslation: "Залишайся живим!", synonyms: ["living"], difficulty: .b1),
        Word(id: "b1_094", original: "all", translation: "всі", transcription: "/ɔːl/", exampleSentence: "All people.", exampleTranslation: "Всі люди.", synonyms: ["everyone"], difficulty: .b1),
        Word(id: "b1_095", original: "alliance", translation: "альянс", transcription: "/əˈlaɪəns/", exampleSentence: "A military alliance.", exampleTranslation: "Військовий альянс.", synonyms: ["union"], difficulty: .b1),
        Word(id: "b1_096", original: "allow", translation: "дозволяти", transcription: "/əˈlaʊ/", exampleSentence: "Allow me to help.", exampleTranslation: "Дозволь мені допомогти.", synonyms: ["permit"], difficulty: .b1),
        Word(id: "b1_097", original: "ally", translation: "союзник", transcription: "/ˈælaɪ/", exampleSentence: "A close ally.", exampleTranslation: "Близький союзник.", synonyms: ["partner"], difficulty: .b1),
        Word(id: "b1_098", original: "almost", translation: "майже", transcription: "/ˈɔːlmoʊst/", exampleSentence: "Almost finished.", exampleTranslation: "Майже закінчено.", synonyms: ["nearly"], difficulty: .b1),
        Word(id: "b1_099", original: "alone", translation: "самотній", transcription: "/əˈloʊn/", exampleSentence: "Leave me alone.", exampleTranslation: "Залиш мене в спокої.", synonyms: ["solitary"], difficulty: .b1),
        Word(id: "b1_100", original: "along", translation: "вздовж", transcription: "/əˈlɔːŋ/", exampleSentence: "Walk along the river.", exampleTranslation: "Йди вздовж річки.", synonyms: [], difficulty: .b1),
    ]
    
    // B2 — 300 слів
    static let b2Words: [Word] = [
        Word(id: "b2_001", original: "abandon", translation: "покидати", transcription: "/əˈbændən/", exampleSentence: "They had to abandon the project.", exampleTranslation: "Вони мали покинути проект.", synonyms: ["desert", "forsake"], difficulty: .b2),
        Word(id: "b2_002", original: "abstract", translation: "абстрактний", transcription: "/ˈæbstrækt/", exampleSentence: "Abstract concepts are difficult.", exampleTranslation: "Абстрактні концепції складні.", synonyms: ["theoretical"], difficulty: .b2),
        Word(id: "b2_003", original: "abundant", translation: "багатий", transcription: "/əˈbʌndənt/", exampleSentence: "Abundant natural resources.", exampleTranslation: "Багаті природні ресурси.", synonyms: ["plentiful"], difficulty: .b2),
        Word(id: "b2_004", original: "academy", translation: "академія", transcription: "/əˈkædəmi/", exampleSentence: "Military academy.", exampleTranslation: "Військова академія.", synonyms: ["institute"], difficulty: .b2),
        Word(id: "b2_005", original: "accelerate", translation: "прискорювати", transcription: "/əkˈseləreɪt/", exampleSentence: "Accelerate economic growth.", exampleTranslation: "Прискор економічне зростання.", synonyms: ["speed up"], difficulty: .b2),
        Word(id: "b2_006", original: "accent", translation: "акцент", transcription: "/ˈæksent/", exampleSentence: "Regional accent.", exampleTranslation: "Регіональний акцент.", synonyms: ["pronunciation"], difficulty: .b2),
        Word(id: "b2_007", original: "acceptance", translation: "прийняття", transcription: "/əkˈseptəns/", exampleSentence: "Acceptance of the situation.", exampleTranslation: "Прийняття ситуації.", synonyms: ["approval"], difficulty: .b2),
        Word(id: "b2_008", original: "access", translation: "доступ", transcription: "/ˈækses/", exampleSentence: "Gain access to information.", exampleTranslation: "Отримай доступ до інформації.", synonyms: ["entry"], difficulty: .b2),
        Word(id: "b2_009", original: "accident", translation: "нещасний випадок", transcription: "/ˈæksɪdənt/", exampleSentence: "A tragic accident.", exampleTranslation: "Трагічний нещасний випадок.", synonyms: ["mishap"], difficulty: .b2),
        Word(id: "b2_010", original: "accommodate", translation: "розміщувати", transcription: "/əˈkɑːmədeɪt/", exampleSentence: "The hotel can accommodate 500 guests.", exampleTranslation: "Готель може розмістити 500 гостей.", synonyms: ["house"], difficulty: .b2),
        Word(id: "b2_011", original: "accomplish", translation: "виконувати", transcription: "/əˈkʌmplɪʃ/", exampleSentence: "Accomplish a mission.", exampleTranslation: "Виконай місію.", synonyms: ["achieve"], difficulty: .b2),
        Word(id: "b2_012", original: "accord", translation: "угода", transcription: "/əˈkɔːrd/", exampleSentence: "In accord with principles.", exampleTranslation: "Відповідно до принципів.", synonyms: ["agreement"], difficulty: .b2),
        Word(id: "b2_013", original: "accountability", translation: "підзвітність", transcription: "/əˌkaʊntəˈbɪləti/", exampleSentence: "Government accountability.", exampleTranslation: "Підзвітність уряду.", synonyms: ["responsibility"], difficulty: .b2),
        Word(id: "b2_014", original: "accumulate", translation: "накопичувати", transcription: "/əˈkjuːmjəleɪt/", exampleSentence: "Accumulate wealth over time.", exampleTranslation: "Накопичуй багатство з часом.", synonyms: ["gather"], difficulty: .b2),
        Word(id: "b2_015", original: "accuracy", translation: "точність", transcription: "/ˈækjərəsi/", exampleSentence: "Scientific accuracy.", exampleTranslation: "Наукова точність.", synonyms: ["precision"], difficulty: .b2),
        Word(id: "b2_016", original: "accusation", translation: "звинувачення", transcription: "/ˌækjuˈzeɪʃn/", exampleSentence: "False accusation.", exampleTranslation: "Хибне звинувачення.", synonyms: ["charge"], difficulty: .b2),
        Word(id: "b2_017", original: "accustomed", translation: "звиклий", transcription: "/əˈkʌstəmd/", exampleSentence: "Accustomed to hard work.", exampleTranslation: "Звиклий до важкої роботи.", synonyms: ["used to"], difficulty: .b2),
        Word(id: "b2_018", original: "achievement", translation: "досягнення", transcription: "/əˈtʃiːvmənt/", exampleSentence: "A remarkable achievement.", exampleTranslation: "Визначне досягнення.", synonyms: ["accomplishment"], difficulty: .b2),
        Word(id: "b2_019", original: "acknowledge", translation: "визнавати", transcription: "/əkˈnɑːlɪdʒ/", exampleSentence: "Acknowledge the problem.", exampleTranslation: "Визнай проблему.", synonyms: ["admit"], difficulty: .b2),
        Word(id: "b2_020", original: "acquaintance", translation: "знайомий", transcription: "/əˈkweɪntəns/", exampleSentence: "A casual acquaintance.", exampleTranslation: "Випадковий знайомий.", synonyms: ["contact"], difficulty: .b2),
        Word(id: "b2_021", original: "acquire", translation: "набувати", transcription: "/əˈkwaɪər/", exampleSentence: "Acquire new skills.", exampleTranslation: "Набувай нові навички.", synonyms: ["obtain"], difficulty: .b2),
        Word(id: "b2_022", original: "adaptation", translation: "адаптація", transcription: "/ˌædæpˈteɪʃn/", exampleSentence: "Adaptation to climate change.", exampleTranslation: "Адаптація до зміни клімату.", synonyms: ["adjustment"], difficulty: .b2),
        Word(id: "b2_023", original: "adequate", translation: "адекватний", transcription: "/ˈædɪkwət/", exampleSentence: "Adequate preparation.", exampleTranslation: "Адекватна підготовка.", synonyms: ["sufficient"], difficulty: .b2),
        Word(id: "b2_024", original: "adjustment", translation: "налаштування", transcription: "/əˈdʒʌstmənt/", exampleSentence: "Make necessary adjustments.", exampleTranslation: "Зроби необхідні налаштування.", synonyms: ["modification"], difficulty: .b2),
        Word(id: "b2_025", original: "administer", translation: "адмініструвати", transcription: "/ədˈmɪnɪstər/", exampleSentence: "Administer first aid.", exampleTranslation: "Надай першу допомогу.", synonyms: ["manage"], difficulty: .b2),
        Word(id: "b2_026", original: "admiration", translation: "захоплення", transcription: "/ˌædməˈreɪʃn/", exampleSentence: "Great admiration.", exampleTranslation: "Велике захоплення.", synonyms: ["respect"], difficulty: .b2),
        Word(id: "b2_027", original: "admission", translation: "вступ", transcription: "/ədˈmɪʃn/", exampleSentence: "Admission requirements.", exampleTranslation: "Вимоги до вступу.", synonyms: ["entry"], difficulty: .b2),
        Word(id: "b2_028", original: "adolescent", translation: "підліток", transcription: "/ˌædəˈlesnt/", exampleSentence: "Adolescent behavior.", exampleTranslation: "Підліткова поведінка.", synonyms: ["teenager"], difficulty: .b2),
        Word(id: "b2_029", original: "adoption", translation: "усиновлення", transcription: "/əˈdɑːpʃn/", exampleSentence: "International adoption.", exampleTranslation: "Міжнародне усиновлення.", synonyms: [], difficulty: .b2),
        Word(id: "b2_030", original: "advantageous", translation: "вигідний", transcription: "/ˌædvənˈteɪdʒəs/", exampleSentence: "Advantageous position.", exampleTranslation: "Вигідна позиція.", synonyms: ["beneficial"], difficulty: .b2),
        Word(id: "b2_031", original: "adventure", translation: "пригода", transcription: "/ədˈventʃər/", exampleSentence: "Spirit of adventure.", exampleTranslation: "Дух пригод.", synonyms: ["venture"], difficulty: .b2),
        Word(id: "b2_032", original: "adversary", translation: "супротивник", transcription: "/ˈædvərseri/", exampleSentence: "Political adversary.", exampleTranslation: "Політичний супротивник.", synonyms: ["opponent"], difficulty: .b2),
        Word(id: "b2_033", original: "adverse", translation: "несприятливий", transcription: "/ədˈvɜːrs/", exampleSentence: "Adverse weather conditions.", exampleTranslation: "Несприятливі погодні умови.", synonyms: ["unfavorable"], difficulty: .b2),
        Word(id: "b2_034", original: "advocate", translation: "адвокат", transcription: "/ˈædvəkeɪt/", exampleSentence: "Advocate for human rights.", exampleTranslation: "Адвокат прав людини.", synonyms: ["champion"], difficulty: .b2),
        Word(id: "b2_035", original: "aesthetic", translation: "естетичний", transcription: "/esˈθetɪk/", exampleSentence: "Aesthetic appeal.", exampleTranslation: "Естетична привабливість.", synonyms: ["artistic"], difficulty: .b2),
        Word(id: "b2_036", original: "affair", translation: "справа", transcription: "/əˈfer/", exampleSentence: "State of affairs.", exampleTranslation: "Стан справ.", synonyms: ["matter"], difficulty: .b2),
        Word(id: "b2_037", original: "affection", translation: "прихильність", transcription: "/əˈfekʃn/", exampleSentence: "Deep affection.", exampleTranslation: "Глибока прихильність.", synonyms: ["fondness"], difficulty: .b2),
        Word(id: "b2_038", original: "affiliate", translation: "філія", transcription: "/əˈfɪlieɪt/", exampleSentence: "Business affiliate.", exampleTranslation: "Бізнес-філія.", synonyms: ["associate"], difficulty: .b2),
        Word(id: "b2_039", original: "affirm", translation: "стверджувати", transcription: "/əˈfɜːrm/", exampleSentence: "Affirm the decision.", exampleTranslation: "Підтверди рішення.", synonyms: ["confirm"], difficulty: .b2),
        Word(id: "b2_040", original: "afflict", translation: "докучати", transcription: "/əˈflɪkt/", exampleSentence: "Afflict the population.", exampleTranslation: "Докучати населенню.", synonyms: ["trouble"], difficulty: .b2),
        Word(id: "b2_041", original: "affluent", translation: "заможний", transcription: "/ˈæfluənt/", exampleSentence: "Affluent society.", exampleTranslation: "Заможне суспільство.", synonyms: ["wealthy"], difficulty: .b2),
        Word(id: "b2_042", original: "aftermath", translation: "наслідок", transcription: "/ˈæftərmæθ/", exampleSentence: "In the aftermath of war.", exampleTranslation: "Внаслідок війни.", synonyms: ["consequence"], difficulty: .b2),
        Word(id: "b2_043", original: "agency", translation: "агентство", transcription: "/ˈeɪdʒənsi/", exampleSentence: "Government agency.", exampleTranslation: "Урядове агентство.", synonyms: ["bureau"], difficulty: .b2),
        Word(id: "b2_044", original: "agenda", translation: "порядок денний", transcription: "/əˈdʒendə/", exampleSentence: "Political agenda.", exampleTranslation: "Політичний порядок денний.", synonyms: ["plan"], difficulty: .b2),
        Word(id: "b2_045", original: "aggravate", translation: "погіршувати", transcription: "/ˈæɡrəveɪt/", exampleSentence: "Aggravate the situation.", exampleTranslation: "Погірш ситуацію.", synonyms: ["worsen"], difficulty: .b2),
        Word(id: "b2_046", original: "aggregate", translation: "сукупний", transcription: "/ˈæɡrɪɡət/", exampleSentence: "Aggregate data.", exampleTranslation: "Сукупні дані.", synonyms: ["total"], difficulty: .b2),
        Word(id: "b2_047", original: "aggression", translation: "агресія", transcription: "/əˈɡreʃn/", exampleSentence: "Act of aggression.", exampleTranslation: "Акт агресії.", synonyms: ["hostility"], difficulty: .b2),
        Word(id: "b2_048", original: "agricultural", translation: "сільськогосподарський", transcription: "/ˌæɡrɪˈkʌltʃərəl/", exampleSentence: "Agricultural land.", exampleTranslation: "Сільськогосподарська земля.", synonyms: ["farming"], difficulty: .b2),
        Word(id: "b2_049", original: "aid", translation: "допомога", transcription: "/eɪd/", exampleSentence: "Foreign aid.", exampleTranslation: "Зовнішня допомога.", synonyms: ["assistance"], difficulty: .b2),
        Word(id: "b2_050", original: "albeit", translation: "хоча", transcription: "/ˌɔːlˈbiːɪt/", exampleSentence: "Albeit slowly.", exampleTranslation: "Хоча й повільно.", synonyms: ["although"], difficulty: .b2),
        Word(id: "b2_051", original: "alert", translation: "тривога", transcription: "/əˈlɜːrt/", exampleSentence: "On high alert.", exampleTranslation: "У стані підвищеної готовності.", synonyms: ["warning"], difficulty: .b2),
        Word(id: "b2_052", original: "alien", translation: "інопланетянин", transcription: "/ˈeɪliən/", exampleSentence: "Illegal alien.", exampleTranslation: "Нелегальний мігрант.", synonyms: ["foreigner"], difficulty: .b2),
        Word(id: "b2_053", original: "align", translation: "вирівнювати", transcription: "/əˈlaɪn/", exampleSentence: "Align with goals.", exampleTranslation: "Вирівняй з цілями.", synonyms: ["adjust"], difficulty: .b2),
        Word(id: "b2_054", original: "alike", translation: "однаковий", transcription: "/əˈlaɪk/", exampleSentence: "Great minds think alike.", exampleTranslation: "Великі уми думають однаково.", synonyms: ["similar"], difficulty: .b2),
        Word(id: "b2_055", original: "allegation", translation: "звинувачення", transcription: "/ˌæləˈɡeɪʃn/", exampleSentence: "Serious allegations.", exampleTranslation: "Серйозні звинувачення.", synonyms: ["claim"], difficulty: .b2),
        Word(id: "b2_056", original: "allege", translation: "стверджувати", transcription: "/əˈledʒ/", exampleSentence: "Allege corruption.", exampleTranslation: "Стверджувати про корупцію.", synonyms: ["claim"], difficulty: .b2),
        Word(id: "b2_057", original: "alleviate", translation: "полегшувати", transcription: "/əˈliːvieɪt/", exampleSentence: "Alleviate poverty.", exampleTranslation: "Полегш бідність.", synonyms: ["ease"], difficulty: .b2),
        Word(id: "b2_058", original: "alliance", translation: "альянс", transcription: "/əˈlaɪəns/", exampleSentence: "Strategic alliance.", exampleTranslation: "Стратегічний альянс.", synonyms: ["partnership"], difficulty: .b2),
        Word(id: "b2_059", original: "allocate", translation: "розподіляти", transcription: "/ˈæləkeɪt/", exampleSentence: "Allocate resources.", exampleTranslation: "Розподіли ресурси.", synonyms: ["assign"], difficulty: .b2),
        Word(id: "b2_060", original: "allowance", translation: "карманні гроші", transcription: "/əˈlaʊəns/", exampleSentence: "Weekly allowance.", exampleTranslation: "Щотижневі карманні гроші.", synonyms: ["pocket money"], difficulty: .b2),
        Word(id: "b2_061", original: "ally", translation: "союзник", transcription: "/ˈælaɪ/", exampleSentence: "Trusted ally.", exampleTranslation: "Довірений союзник.", synonyms: ["partner"], difficulty: .b2),
        Word(id: "b2_062", original: "alter", translation: "змінювати", transcription: "/ˈɔːltər/", exampleSentence: "Alter the plan.", exampleTranslation: "Зміни план.", synonyms: ["change"], difficulty: .b2),
        Word(id: "b2_063", original: "alternative", translation: "альтернатива", transcription: "/ɔːlˈtɜːrnətɪv/", exampleSentence: "Alternative energy.", exampleTranslation: "Альтернативна енергія.", synonyms: ["option"], difficulty: .b2),
        Word(id: "b2_064", original: "ambiguous", translation: "двозначний", transcription: "/æmˈbɪɡjuəs/", exampleSentence: "Ambiguous statement.", exampleTranslation: "Двозначна заява.", synonyms: ["unclear"], difficulty: .b2),
        Word(id: "b2_065", original: "ambition", translation: "амбіція", transcription: "/æmˈbɪʃn/", exampleSentence: "Political ambition.", exampleTranslation: "Політична амбіція.", synonyms: ["aspiration"], difficulty: .b2),
        Word(id: "b2_066", original: "ambitious", translation: "амбіційний", transcription: "/æmˈbɪʃəs/", exampleSentence: "Ambitious project.", exampleTranslation: "Амбіційний проект.", synonyms: ["determined"], difficulty: .b2),
        Word(id: "b2_067", original: "amend", translation: "виправляти", transcription: "/əˈmend/", exampleSentence: "Amend the constitution.", exampleTranslation: "Внеси поправки до конституції.", synonyms: ["revise"], difficulty: .b2),
        Word(id: "b2_068", original: "amendment", translation: "поправка", transcription: "/əˈmendmənt/", exampleSentence: "Constitutional amendment.", exampleTranslation: "Конституційна поправка.", synonyms: ["change"], difficulty: .b2),
        Word(id: "b2_069", original: "amid", translation: "серед", transcription: "/əˈmɪd/", exampleSentence: "Amid the chaos.", exampleTranslation: "Серед хаосу.", synonyms: ["among"], difficulty: .b2),
        Word(id: "b2_070", original: "ample", translation: "достатній", transcription: "/ˈæmpl/", exampleSentence: "Ample evidence.", exampleTranslation: "Достатні докази.", synonyms: ["plentiful"], difficulty: .b2),
        Word(id: "b2_071", original: "amuse", translation: "розважати", transcription: "/əˈmjuːz/", exampleSentence: "Amuse the children.", exampleTranslation: "Розваж дітей.", synonyms: ["entertain"], difficulty: .b2),
        Word(id: "b2_072", original: "analogy", translation: "аналогія", transcription: "/əˈnælədʒi/", exampleSentence: "Use an analogy.", exampleTranslation: "Використай аналогію.", synonyms: ["comparison"], difficulty: .b2),
        Word(id: "b2_073", original: "analyze", translation: "аналізувати", transcription: "/ˈænəlaɪz/", exampleSentence: "Analyze the data.", exampleTranslation: "Проаналізуй дані.", synonyms: ["examine"], difficulty: .b2),
        Word(id: "b2_074", original: "ancestor", translation: "предок", transcription: "/ˈænsestər/", exampleSentence: "Our ancestors.", exampleTranslation: "Наші предки.", synonyms: ["forefather"], difficulty: .b2),
        Word(id: "b2_075", original: "anchor", translation: "якір", transcription: "/ˈæŋkər/", exampleSentence: "Drop the anchor.", exampleTranslation: "Кинь якір.", synonyms: [], difficulty: .b2),
        Word(id: "b2_076", original: "ancient", translation: "давній", transcription: "/ˈeɪnʃənt/", exampleSentence: "Ancient civilization.", exampleTranslation: "Давня цивілізація.", synonyms: ["old"], difficulty: .b2),
        Word(id: "b2_077", original: "anecdote", translation: "анекдот", transcription: "/ˈænɪkdoʊt/", exampleSentence: "Tell an anecdote.", exampleTranslation: "Розкажи анекдот.", synonyms: ["story"], difficulty: .b2),
        Word(id: "b2_078", original: "anniversary", translation: "річниця", transcription: "/ˌænɪˈvɜːrsəri/", exampleSentence: "Wedding anniversary.", exampleTranslation: "Річниця весілля.", synonyms: [], difficulty: .b2),
        Word(id: "b2_079", original: "announcement", translation: "оголошення", transcription: "/əˈnaʊnsmənt/", exampleSentence: "Important announcement.", exampleTranslation: "Важливе оголошення.", synonyms: ["declaration"], difficulty: .b2),
        Word(id: "b2_080", original: "annoy", translation: "дратувати", transcription: "/əˈnɔɪ/", exampleSentence: "Don't annoy me.", exampleTranslation: "Не дратуй мене.", synonyms: ["irritate"], difficulty: .b2),
        Word(id: "b2_081", original: "annual", translation: "щорічний", transcription: "/ˈænjuəl/", exampleSentence: "Annual report.", exampleTranslation: "Щорічний звіт.", synonyms: ["yearly"], difficulty: .b2),
        Word(id: "b2_082", original: "anonymous", translation: "анонімний", transcription: "/əˈnɑːnɪməs/", exampleSentence: "Anonymous letter.", exampleTranslation: "Анонімний лист.", synonyms: ["nameless"], difficulty: .b2),
        Word(id: "b2_083", original: "anticipate", translation: "передбачати", transcription: "/ænˈtɪsɪpeɪt/", exampleSentence: "Anticipate problems.", exampleTranslation: "Передбач проблеми.", synonyms: ["expect"], difficulty: .b2),
        Word(id: "b2_084", original: "anxiety", translation: "тривога", transcription: "/æŋˈzaɪəti/", exampleSentence: "Social anxiety.", exampleTranslation: "Соціальна тривога.", synonyms: ["worry"], difficulty: .b2),
        Word(id: "b2_085", original: "apology", translation: "вибачення", transcription: "/əˈpɑːlədʒi/", exampleSentence: "Accept my apology.", exampleTranslation: "Прийми мої вибачення.", synonyms: ["regret"], difficulty: .b2),
        Word(id: "b2_086", original: "apparatus", translation: "апарат", transcription: "/ˌæpəˈrætəs/", exampleSentence: "Scientific apparatus.", exampleTranslation: "Науковий апарат.", synonyms: ["equipment"], difficulty: .b2),
        Word(id: "b2_087", original: "apparent", translation: "очевидний", transcription: "/əˈpærənt/", exampleSentence: "Apparent contradiction.", exampleTranslation: "Очевидна суперечність.", synonyms: ["clear"], difficulty: .b2),
        Word(id: "b2_088", original: "appeal", translation: "апеляція", transcription: "/əˈpiːl/", exampleSentence: "File an appeal.", exampleTranslation: "Подай апеляцію.", synonyms: ["request"], difficulty: .b2),
        Word(id: "b2_089", original: "appearance", translation: "зовнішність", transcription: "/əˈpɪrəns/", exampleSentence: "Physical appearance.", exampleTranslation: "Фізична зовнішність.", synonyms: ["look"], difficulty: .b2),
        Word(id: "b2_090", original: "appetite", translation: "апетит", transcription: "/ˈæpɪtaɪt/", exampleSentence: "Healthy appetite.", exampleTranslation: "Здоровий апетит.", synonyms: ["hunger"], difficulty: .b2),
        Word(id: "b2_091", original: "applaud", translation: "аплодувати", transcription: "/əˈplɔːd/", exampleSentence: "Applaud the performance.", exampleTranslation: "Аплодуй виступу.", synonyms: ["clap"], difficulty: .b2),
        Word(id: "b2_092", original: "applicant", translation: "кандидат", transcription: "/ˈæplɪkənt/", exampleSentence: "Job applicant.", exampleTranslation: "Кандидат на роботу.", synonyms: ["candidate"], difficulty: .b2),
        Word(id: "b2_093", original: "application", translation: "застосування", transcription: "/ˌæplɪˈkeɪʃn/", exampleSentence: "Practical application.", exampleTranslation: "Практичне застосування.", synonyms: ["use"], difficulty: .b2),
        Word(id: "b2_094", original: "appoint", translation: "призначати", transcription: "/əˈpɔɪnt/", exampleSentence: "Appoint a manager.", exampleTranslation: "Признач менеджера.", synonyms: ["assign"], difficulty: .b2),
        Word(id: "b2_095", original: "appreciate", translation: "цінувати", transcription: "/əˈpriːʃieɪt/", exampleSentence: "I appreciate your help.", exampleTranslation: "Я ціную твою допомогу.", synonyms: ["value"], difficulty: .b2),
        Word(id: "b2_096", original: "approach", translation: "підхід", transcription: "/əˈproʊtʃ/", exampleSentence: "New approach.", exampleTranslation: "Новий підхід.", synonyms: ["method"], difficulty: .b2),
        Word(id: "b2_097", original: "appropriate", translation: "відповідний", transcription: "/əˈproʊpriət/", exampleSentence: "Appropriate behavior.", exampleTranslation: "Відповідна поведінка.", synonyms: ["suitable"], difficulty: .b2),
        Word(id: "b2_098", original: "approval", translation: "схвалення", transcription: "/əˈpruːvl/", exampleSentence: "Seek approval.", exampleTranslation: "Шукай схвалення.", synonyms: ["acceptance"], difficulty: .b2),
        Word(id: "b2_099", original: "approve", translation: "схвалювати", transcription: "/əˈpruːv/", exampleSentence: "Approve the plan.", exampleTranslation: "Схвали план.", synonyms: ["accept"], difficulty: .b2),
        Word(id: "b2_100", original: "approximate", translation: "приблизний", transcription: "/əˈprɑːksɪmət/", exampleSentence: "Approximate cost.", exampleTranslation: "Приблизна вартість.", synonyms: ["estimated"], difficulty: .b2)
    ]
    
    // C1 — 200 слів
    static let c1Words: [Word] = [
        Word(id: "c1_001", original: "aberration", translation: "відхилення", transcription: "/ˌæbəˈreɪʃn/", exampleSentence: "A temporary aberration.", exampleTranslation: "Тимчасове відхилення.", synonyms: ["anomaly", "deviation"], difficulty: .c1),
        Word(id: "c1_002", original: "abhor", translation: "ненавидіти", transcription: "/əbˈhɔːr/", exampleSentence: "I abhor violence.", exampleTranslation: "Я ненавиджу насильство.", synonyms: ["detest", "loathe"], difficulty: .c1),
        Word(id: "c1_003", original: "abide", translation: "дотримуватися", transcription: "/əˈbaɪd/", exampleSentence: "Abide by the rules.", exampleTranslation: "Дотримуйся правил.", synonyms: ["follow", "obey"], difficulty: .c1),
        Word(id: "c1_004", original: "abject", translation: "жалюгідний", transcription: "/ˈæbdʒekt/", exampleSentence: "Abject poverty.", exampleTranslation: "Жалюгідна бідність.", synonyms: ["wretched", "miserable"], difficulty: .c1),
        Word(id: "c1_005", original: "abolish", translation: "скасовувати", transcription: "/əˈbɑːlɪʃ/", exampleSentence: "Abolish slavery.", exampleTranslation: "Скасуй рабство.", synonyms: ["eliminate", "end"], difficulty: .c1),
        Word(id: "c1_006", original: "abound", translation: "бути в достатку", transcription: "/əˈbaʊnd/", exampleSentence: "Wildlife abounds here.", exampleTranslation: "Тут багато дикої природи.", synonyms: ["teem", "overflow"], difficulty: .c1),
        Word(id: "c1_007", original: "abrasive", translation: "абразивний", transcription: "/əˈbreɪsɪv/", exampleSentence: "Abrasive personality.", exampleTranslation: "Абразивна особистість.", synonyms: ["harsh", "rough"], difficulty: .c1),
        Word(id: "c1_008", original: "abreast", translation: "поруч", transcription: "/əˈbrest/", exampleSentence: "Keep abreast of news.", exampleTranslation: "Будь в курсі новин.", synonyms: ["informed", "up-to-date"], difficulty: .c1),
        Word(id: "c1_009", original: "abridge", translation: "скорочувати", transcription: "/əˈbrɪdʒ/", exampleSentence: "Abridge the text.", exampleTranslation: "Скороти текст.", synonyms: ["shorten", "condense"], difficulty: .c1),
        Word(id: "c1_010", original: "abrogate", translation: "анулювати", transcription: "/ˈæbrəɡeɪt/", exampleSentence: "Abrogate the treaty.", exampleTranslation: "Анулюй договір.", synonyms: ["repeal", "cancel"], difficulty: .c1),
        Word(id: "c1_011", original: "abscond", translation: "втікати", transcription: "/əbˈskɑːnd/", exampleSentence: "Abscond with the money.", exampleTranslation: "Втечи з грошима.", synonyms: ["flee", "escape"], difficulty: .c1),
        Word(id: "c1_012", original: "abstain", translation: "утримуватися", transcription: "/əbˈsteɪn/", exampleSentence: "Abstain from voting.", exampleTranslation: "Утримайся від голосування.", synonyms: ["refrain", "forgo"], difficulty: .c1),
        Word(id: "c1_013", original: "abstract", translation: "абстрактний", transcription: "/ˈæbstrækt/", exampleSentence: "Abstract philosophy.", exampleTranslation: "Абстрактна філософія.", synonyms: ["theoretical"], difficulty: .c1),
        Word(id: "c1_014", original: "abstruse", translation: "заплутаний", transcription: "/əbˈstruːs/", exampleSentence: "Abstruse theory.", exampleTranslation: "Заплутана теорія.", synonyms: ["obscure", "complex"], difficulty: .c1),
        Word(id: "c1_015", original: "abundant", translation: "багатий", transcription: "/əˈbʌndənt/", exampleSentence: "Abundant resources.", exampleTranslation: "Багаті ресурси.", synonyms: ["plentiful", "ample"], difficulty: .c1),
        Word(id: "c1_016", original: "abuse", translation: "зловживання", transcription: "/əˈbjuːs/", exampleSentence: "Substance abuse.", exampleTranslation: "Зловживання речовинами.", synonyms: ["misuse"], difficulty: .c1),
        Word(id: "c1_017", original: "abut", translation: "межувати", transcription: "/əˈbʌt/", exampleSentence: "The land abuts the river.", exampleTranslation: "Земля межує з річкою.", synonyms: ["border", "adjoin"], difficulty: .c1),
        Word(id: "c1_018", original: "abysmal", translation: "жахливий", transcription: "/əˈbɪzməl/", exampleSentence: "Abysmal performance.", exampleTranslation: "Жахлива продуктивність.", synonyms: ["terrible", "dreadful"], difficulty: .c1),
        Word(id: "c1_019", original: "academic", translation: "академічний", transcription: "/ˌækəˈdemɪk/", exampleSentence: "Academic discourse.", exampleTranslation: "Академічний дискурс.", synonyms: ["scholarly"], difficulty: .c1),
        Word(id: "c1_020", original: "accede", translation: "погоджуватися", transcription: "/əkˈsiːd/", exampleSentence: "Accede to demands.", exampleTranslation: "Погодься на вимоги.", synonyms: ["agree", "consent"], difficulty: .c1),
        Word(id: "c1_021", original: "accelerate", translation: "прискорювати", transcription: "/əkˈseləreɪt/", exampleSentence: "Accelerate development.", exampleTranslation: "Прискор розвиток.", synonyms: ["speed up"], difficulty: .c1),
        Word(id: "c1_022", original: "accentuate", translation: "підкреслювати", transcription: "/əkˈsentʃueɪt/", exampleSentence: "Accentuate the positive.", exampleTranslation: "Підкресли позитивне.", synonyms: ["emphasize"], difficulty: .c1),
        Word(id: "c1_023", original: "accessible", translation: "доступний", transcription: "/əkˈsesəbl/", exampleSentence: "Easily accessible.", exampleTranslation: "Легко доступний.", synonyms: ["available"], difficulty: .c1),
        Word(id: "c1_024", original: "accessory", translation: "аксесуар", transcription: "/əkˈsesəri/", exampleSentence: "Fashion accessory.", exampleTranslation: "Модний аксесуар.", synonyms: ["addition"], difficulty: .c1),
        Word(id: "c1_025", original: "acclaim", translation: "визнання", transcription: "/əˈkleɪm/", exampleSentence: "Critical acclaim.", exampleTranslation: "Визнання критиків.", synonyms: ["praise"], difficulty: .c1),
        Word(id: "c1_026", original: "acclimate", translation: "акліматизуватися", transcription: "/ˈækləmeɪt/", exampleSentence: "Acclimate to new conditions.", exampleTranslation: "Акліматизуйся до нових умов.", synonyms: ["adapt"], difficulty: .c1),
        Word(id: "c1_027", original: "accomplice", translation: "спільник", transcription: "/əˈkʌmplɪs/", exampleSentence: "An accomplice to the crime.", exampleTranslation: "Спільник злочину.", synonyms: ["associate"], difficulty: .c1),
        Word(id: "c1_028", original: "accord", translation: "угода", transcription: "/əˈkɔːrd/", exampleSentence: "Peace accord.", exampleTranslation: "Мирна угода.", synonyms: ["agreement"], difficulty: .c1),
        Word(id: "c1_029", original: "accost", translation: "зачіпати", transcription: "/əˈkɔːst/", exampleSentence: "Accost a stranger.", exampleTranslation: "Зачепи незнайомця.", synonyms: ["approach"], difficulty: .c1),
        Word(id: "c1_030", original: "accountable", translation: "підзвітний", transcription: "/əˈkaʊntəbl/", exampleSentence: "Hold accountable.", exampleTranslation: "Тримай підзвітним.", synonyms: ["responsible"], difficulty: .c1),
        Word(id: "c1_031", original: "accrue", translation: "нараховуватися", transcription: "/əˈkruː/", exampleSentence: "Interest accrues.", exampleTranslation: "Відсотки нараховуються.", synonyms: ["accumulate"], difficulty: .c1),
        Word(id: "c1_032", original: "acerbic", translation: "їдкий", transcription: "/əˈsɜːrbɪk/", exampleSentence: "Acerbic wit.", exampleTranslation: "Їдкий гумор.", synonyms: ["sharp", "biting"], difficulty: .c1),
        Word(id: "c1_033", original: "acknowledge", translation: "визнавати", transcription: "/əkˈnɑːlɪdʒ/", exampleSentence: "Acknowledge receipt.", exampleTranslation: "Визнай отримання.", synonyms: ["admit"], difficulty: .c1),
        Word(id: "c1_034", original: "acme", translation: "вершина", transcription: "/ˈækmi/", exampleSentence: "The acme of perfection.", exampleTranslation: "Вершина досконалості.", synonyms: ["peak", "summit"], difficulty: .c1),
        Word(id: "c1_035", original: "acquiesce", translation: "поступатися", transcription: "/ˌækwiˈes/", exampleSentence: "Acquiesce to demands.", exampleTranslation: "Поступись вимогам.", synonyms: ["agree"], difficulty: .c1),
        Word(id: "c1_036", original: "acquire", translation: "набувати", transcription: "/əˈkwaɪər/", exampleSentence: "Acquire knowledge.", exampleTranslation: "Набувай знань.", synonyms: ["obtain"], difficulty: .c1),
        Word(id: "c1_037", original: "acquit", translation: "виправдовувати", transcription: "/əˈkwɪt/", exampleSentence: "Acquit of all charges.", exampleTranslation: "Виправдай за всіма звинуваченнями.", synonyms: ["clear"], difficulty: .c1),
        Word(id: "c1_038", original: "acrid", translation: "гострий", transcription: "/ˈækrɪd/", exampleSentence: "Acrid smell.", exampleTranslation: "Гострий запах.", synonyms: ["pungent"], difficulty: .c1),
        Word(id: "c1_039", original: "acrimonious", translation: "запальний", transcription: "/ˌækrɪˈmoʊniəs/", exampleSentence: "Acrimonious debate.", exampleTranslation: "Запальна дебати.", synonyms: ["bitter"], difficulty: .c1),
        Word(id: "c1_040", original: "acumen", translation: "проникливість", transcription: "/ˈækjəmən/", exampleSentence: "Business acumen.", exampleTranslation: "Ділова проникливість.", synonyms: ["insight"], difficulty: .c1),
        Word(id: "c1_041", original: "acute", translation: "гострий", transcription: "/əˈkjuːt/", exampleSentence: "Acute awareness.", exampleTranslation: "Гостра обізнаність.", synonyms: ["keen"], difficulty: .c1),
        Word(id: "c1_042", original: "adamant", translation: "непохитний", transcription: "/ˈædəmənt/", exampleSentence: "Adamant refusal.", exampleTranslation: "Непохитна відмова.", synonyms: ["firm"], difficulty: .c1),
        Word(id: "c1_043", original: "adapt", translation: "адаптувати", transcription: "/əˈdæpt/", exampleSentence: "Adapt to circumstances.", exampleTranslation: "Адаптуйся до обставин.", synonyms: ["adjust"], difficulty: .c1),
        Word(id: "c1_044", original: "adept", translation: "вмілий", transcription: "/əˈdept/", exampleSentence: "Adept at negotiation.", exampleTranslation: "Вмілий у переговорах.", synonyms: ["skilled"], difficulty: .c1),
        Word(id: "c1_045", original: "adhere", translation: "дотримуватися", transcription: "/ədˈhɪr/", exampleSentence: "Adhere to principles.", exampleTranslation: "Дотримуйся принципів.", synonyms: ["stick to"], difficulty: .c1),
        Word(id: "c1_046", original: "adjacent", translation: "сусідній", transcription: "/əˈdʒeɪsnt/", exampleSentence: "Adjacent rooms.", exampleTranslation: "Сусідні кімнати.", synonyms: ["neighboring"], difficulty: .c1),
        Word(id: "c1_047", original: "adjoin", translation: "прилягати", transcription: "/əˈdʒɔɪn/", exampleSentence: "The rooms adjoin.", exampleTranslation: "Кімнати прилягають.", synonyms: ["border"], difficulty: .c1),
        Word(id: "c1_048", original: "adjourn", translation: "переносити", transcription: "/əˈdʒɜːrn/", exampleSentence: "Adjourn the meeting.", exampleTranslation: "Перенеси зустріч.", synonyms: ["postpone"], difficulty: .c1),
        Word(id: "c1_049", original: "adjunct", translation: "додаток", transcription: "/ˈædʒʌŋkt/", exampleSentence: "An adjunct professor.", exampleTranslation: "Доцент.", synonyms: ["addition"], difficulty: .c1),
        Word(id: "c1_050", original: "admonish", translation: "дорікати", transcription: "/ədˈmɑːnɪʃ/", exampleSentence: "Admonish for mistakes.", exampleTranslation: "Дорікай за помилки.", synonyms: ["rebuke"], difficulty: .c1),
        Word(id: "c1_051", original: "adorn", translation: "прикрашати", transcription: "/əˈdɔːrn/", exampleSentence: "Adorn with flowers.", exampleTranslation: "Прикрась квітами.", synonyms: ["decorate"], difficulty: .c1),
        Word(id: "c1_052", original: "adroit", translation: "вправний", transcription: "/əˈdrɔɪt/", exampleSentence: "Adroit handling.", exampleTranslation: "Вправне керування.", synonyms: ["skillful"], difficulty: .c1),
        Word(id: "c1_053", original: "adulterate", translation: "фальсифікувати", transcription: "/əˈdʌltəreɪt/", exampleSentence: "Adulterate the product.", exampleTranslation: "Фальсифікуй продукт.", synonyms: ["contaminate"], difficulty: .c1),
        Word(id: "c1_054", original: "adumbrate", translation: "намітити", transcription: "/ˈædʌmbreɪt/", exampleSentence: "Adumbrate plans.", exampleTranslation: "Наміть плани.", synonyms: ["outline"], difficulty: .c1),
        Word(id: "c1_055", original: "adverse", translation: "несприятливий", transcription: "/ədˈvɜːrs/", exampleSentence: "Adverse conditions.", exampleTranslation: "Несприятливі умови.", synonyms: ["unfavorable"], difficulty: .c1),
        Word(id: "c1_056", original: "advocate", translation: "адвокат", transcription: "/ˈædvəkeɪt/", exampleSentence: "Advocate for change.", exampleTranslation: "Адвокат змін.", synonyms: ["champion"], difficulty: .c1),
        Word(id: "c1_057", original: "aesthetic", translation: "естетичний", transcription: "/esˈθetɪk/", exampleSentence: "Aesthetic judgment.", exampleTranslation: "Естетичний судження.", synonyms: ["artistic"], difficulty: .c1),
        Word(id: "c1_058", original: "affable", translation: "привітний", transcription: "/ˈæfəbl/", exampleSentence: "Affable manner.", exampleTranslation: "Привітна манера.", synonyms: ["friendly"], difficulty: .c1),
        Word(id: "c1_059", original: "affectation", translation: "манірність", transcription: "/ˌæfekˈteɪʃn/", exampleSentence: "Without affectation.", exampleTranslation: "Без манірності.", synonyms: ["pretense"], difficulty: .c1),
        Word(id: "c1_060", original: "affinity", translation: "спорідненість", transcription: "/əˈfɪnəti/", exampleSentence: "Natural affinity.", exampleTranslation: "Природна спорідненість.", synonyms: ["liking"], difficulty: .c1),
        Word(id: "c1_061", original: "affirm", translation: "стверджувати", transcription: "/əˈfɜːrm/", exampleSentence: "Affirm commitment.", exampleTranslation: "Ствердь зобов'язання.", synonyms: ["confirm"], difficulty: .c1),
        Word(id: "c1_062", original: "afflict", translation: "докучати", transcription: "/əˈflɪkt/", exampleSentence: "Afflict the nation.", exampleTranslation: "Докучай нації.", synonyms: ["trouble"], difficulty: .c1),
        Word(id: "c1_063", original: "affluent", translation: "заможний", transcription: "/ˈæfluənt/", exampleSentence: "Affluent neighborhood.", exampleTranslation: "Заможний район.", synonyms: ["wealthy"], difficulty: .c1),
        Word(id: "c1_064", original: "affront", translation: "образа", transcription: "/əˈfrʌnt/", exampleSentence: "An affront to dignity.", exampleTranslation: "Образа гідності.", synonyms: ["insult"], difficulty: .c1),
        Word(id: "c1_065", original: "agenda", translation: "порядок денний", transcription: "/əˈdʒendə/", exampleSentence: "Hidden agenda.", exampleTranslation: "Прихований порядок денний.", synonyms: ["plan"], difficulty: .c1),
        Word(id: "c1_066", original: "aggrandize", translation: "збільшувати", transcription: "/əˈɡrændaɪz/", exampleSentence: "Aggrandize one's power.", exampleTranslation: "Збільш свою владу.", synonyms: ["exaggerate"], difficulty: .c1),
        Word(id: "c1_067", original: "aggravate", translation: "погіршувати", transcription: "/ˈæɡrəveɪt/", exampleSentence: "Aggravate the injury.", exampleTranslation: "Погірш травму.", synonyms: ["worsen"], difficulty: .c1),
        Word(id: "c1_068", original: "aggregate", translation: "сукупний", transcription: "/ˈæɡrɪɡət/", exampleSentence: "Aggregate demand.", exampleTranslation: "Сукупний попит.", synonyms: ["total"], difficulty: .c1),
        Word(id: "c1_069", original: "agile", translation: "спритний", transcription: "/ˈædʒl/", exampleSentence: "Agile mind.", exampleTranslation: "Спритний розум.", synonyms: ["nimble"], difficulty: .c1),
        Word(id: "c1_070", original: "agitate", translation: "збуджувати", transcription: "/ˈædʒɪteɪt/", exampleSentence: "Agitate for reform.", exampleTranslation: "Збуджуй до реформ.", synonyms: ["stir up"], difficulty: .c1),
        Word(id: "c1_071", original: "agnostic", translation: "агностик", transcription: "/æɡˈnɑːstɪk/", exampleSentence: "Agnostic viewpoint.", exampleTranslation: "Агностична точка зору.", synonyms: ["doubter"], difficulty: .c1),
        Word(id: "c1_072", original: "alacrity", translation: "готовність", transcription: "/əˈlækrəti/", exampleSentence: "With alacrity.", exampleTranslation: "З готовністю.", synonyms: ["eagerness"], difficulty: .c1),
        Word(id: "c1_073", original: "albeit", translation: "хоча", transcription: "/ˌɔːlˈbiːɪt/", exampleSentence: "Successful, albeit slowly.", exampleTranslation: "Успішно, хоча й повільно.", synonyms: ["although"], difficulty: .c1),
        Word(id: "c1_074", original: "alchemy", translation: "алхімія", transcription: "/ˈælkəmi/", exampleSentence: "Modern alchemy.", exampleTranslation: "Сучасна алхімія.", synonyms: ["magic"], difficulty: .c1),
        Word(id: "c1_075", original: "alias", translation: "псевдонім", transcription: "/ˈeɪliəs/", exampleSentence: "Travel under an alias.", exampleTranslation: "Подорожуй під псевдонімом.", synonyms: ["pseudonym"], difficulty: .c1),
        Word(id: "c1_076", original: "alienate", translation: "віддаляти", transcription: "/ˈeɪliəneɪt/", exampleSentence: "Alienate supporters.", exampleTranslation: "Віддаляй прихильників.", synonyms: ["estrange"], difficulty: .c1),
        Word(id: "c1_077", original: "allege", translation: "стверджувати", transcription: "/əˈledʒ/", exampleSentence: "Allege corruption.", exampleTranslation: "Стверджуй про корупцію.", synonyms: ["claim"], difficulty: .c1),
        Word(id: "c1_078", original: "allegiance", translation: "вірність", transcription: "/əˈliːdʒəns/", exampleSentence: "Pledge allegiance.", exampleTranslation: "Присягни на вірність.", synonyms: ["loyalty"], difficulty: .c1),
        Word(id: "c1_079", original: "alleviate", translation: "полегшувати", transcription: "/əˈliːvieɪt/", exampleSentence: "Alleviate suffering.", exampleTranslation: "Полегш страждання.", synonyms: ["ease"], difficulty: .c1),
        Word(id: "c1_080", original: "allocate", translation: "розподіляти", transcription: "/ˈæləkeɪt/", exampleSentence: "Allocate funds.", exampleTranslation: "Розподіли кошти.", synonyms: ["assign"], difficulty: .c1),
        Word(id: "c1_081", original: "allude", translation: "натякати", transcription: "/əˈluːd/", exampleSentence: "Allude to the past.", exampleTranslation: "Натякай на минуле.", synonyms: ["refer"], difficulty: .c1),
        Word(id: "c1_082", original: "aloof", translation: "віддалений", transcription: "/əˈluːf/", exampleSentence: "Remain aloof.", exampleTranslation: "Залишайся віддаленим.", synonyms: ["distant"], difficulty: .c1),
        Word(id: "c1_083", original: "altercation", translation: "сварка", transcription: "/ˌɔːltərˈkeɪʃn/", exampleSentence: "A heated altercation.", exampleTranslation: "Гаряча сварка.", synonyms: ["dispute"], difficulty: .c1),
        Word(id: "c1_084", original: "ambiguous", translation: "двозначний", transcription: "/æmˈbɪɡjuəs/", exampleSentence: "Ambiguous statement.", exampleTranslation: "Двозначна заява.", synonyms: ["unclear"], difficulty: .c1),
        Word(id: "c1_085", original: "ambivalent", translation: "амбівалентний", transcription: "/æmˈbɪvələnt/", exampleSentence: "Feel ambivalent.", exampleTranslation: "Відчувай амбівалентність.", synonyms: ["uncertain"], difficulty: .c1),
        Word(id: "c1_086", original: "ameliorate", translation: "покращувати", transcription: "/əˈmiːliəreɪt/", exampleSentence: "Ameliorate conditions.", exampleTranslation: "Покращ умови.", synonyms: ["improve"], difficulty: .c1),
        Word(id: "c1_087", original: "amenable", translation: "поступливий", transcription: "/əˈmiːnəbl/", exampleSentence: "Amenable to suggestion.", exampleTranslation: "Поступливий до пропозиції.", synonyms: ["responsive"], difficulty: .c1),
        Word(id: "c1_088", original: "amend", translation: "виправляти", transcription: "/əˈmend/", exampleSentence: "Amend the law.", exampleTranslation: "Виправ закон.", synonyms: ["revise"], difficulty: .c1),
        Word(id: "c1_089", original: "amiable", translation: "приємний", transcription: "/ˈeɪmiəbl/", exampleSentence: "Amiable personality.", exampleTranslation: "Приємна особистість.", synonyms: ["friendly"], difficulty: .c1),
        Word(id: "c1_090", original: "amicable", translation: "дружній", transcription: "/ˈæmɪkəbl/", exampleSentence: "Amicable settlement.", exampleTranslation: "Дружнє врегулювання.", synonyms: ["peaceful"], difficulty: .c1),
        Word(id: "c1_091", original: "amnesty", translation: "амністія", transcription: "/ˈæmnəsti/", exampleSentence: "Grant amnesty.", exampleTranslation: "Надай амністію.", synonyms: ["pardon"], difficulty: .c1),
        Word(id: "c1_092", original: "amorphous", translation: "аморфний", transcription: "/əˈmɔːrfəs/", exampleSentence: "Amorphous mass.", exampleTranslation: "Аморфна маса.", synonyms: ["shapeless"], difficulty: .c1),
        Word(id: "c1_093", original: "ample", translation: "достатній", transcription: "/ˈæmpl/", exampleSentence: "Ample opportunity.", exampleTranslation: "Достатня можливість.", synonyms: ["plentiful"], difficulty: .c1),
        Word(id: "c1_094", original: "amplify", translation: "підсилювати", transcription: "/ˈæmplɪfaɪ/", exampleSentence: "Amplify the sound.", exampleTranslation: "Підсиль звук.", synonyms: ["intensify"], difficulty: .c1),
        Word(id: "c1_095", original: "anachronism", translation: "анахронізм", transcription: "/əˈnækrənɪzəm/", exampleSentence: "Historical anachronism.", exampleTranslation: "Історичний анахронізм.", synonyms: [], difficulty: .c1),
        Word(id: "c1_096", original: "analgesic", translation: "знеболююче", transcription: "/ˌænəlˈdʒiːzɪk/", exampleSentence: "Take an analgesic.", exampleTranslation: "Прийми знеболююче.", synonyms: ["painkiller"], difficulty: .c1),
        Word(id: "c1_097", original: "analogous", translation: "аналогічний", transcription: "/əˈnæləɡəs/", exampleSentence: "Analogous situation.", exampleTranslation: "Аналогічна ситуація.", synonyms: ["similar"], difficulty: .c1),
        Word(id: "c1_098", original: "anarchy", translation: "анархія", transcription: "/ˈænərki/", exampleSentence: "Political anarchy.", exampleTranslation: "Політична анархія.", synonyms: ["chaos"], difficulty: .c1),
        Word(id: "c1_099", original: "anathema", translation: "анафема", transcription: "/əˈnæθəmə/", exampleSentence: "Anathema to tradition.", exampleTranslation: "Анафема традиції.", synonyms: ["curse"], difficulty: .c1),
        Word(id: "c1_100", original: "ancillary", translation: "допоміжний", transcription: "/ˈænsəleri/", exampleSentence: "Ancillary services.", exampleTranslation: "Допоміжні послуги.", synonyms: ["auxiliary"], difficulty: .c1),
        Word(id: "c1_101", original: "anecdote", translation: "анекдот", transcription: "/ˈænɪkdoʊt/", exampleSentence: "Tell an anecdote.", exampleTranslation: "Розкажи анекдот.", synonyms: ["story"], difficulty: .c1),
        Word(id: "c1_102", original: "anemia", translation: "анемія", transcription: "/əˈniːmiə/", exampleSentence: "Suffer from anemia.", exampleTranslation: "Страждай від анемії.", synonyms: [], difficulty: .c1),
        Word(id: "c1_103", original: "animate", translation: "оживляти", transcription: "/ˈænɪmeɪt/", exampleSentence: "Animate the discussion.", exampleTranslation: "Оживи обговорення.", synonyms: ["enliven"], difficulty: .c1),
        Word(id: "c1_104", original: "animosity", translation: "ворожнеча", transcription: "/ˌænɪˈmɑːsəti/", exampleSentence: "Feel animosity.", exampleTranslation: "Відчувай ворожнечу.", synonyms: ["hostility"], difficulty: .c1),
        Word(id: "c1_105", original: "annals", translation: "літопис", transcription: "/ˈænlz/", exampleSentence: "Historical annals.", exampleTranslation: "Історичний літопис.", synonyms: ["records"], difficulty: .c1),
        Word(id: "c1_106", original: "annex", translation: "приєднувати", transcription: "/əˈneks/", exampleSentence: "Annex territory.", exampleTranslation: "Приєднай територію.", synonyms: ["acquire"], difficulty: .c1),
        Word(id: "c1_107", original: "annihilate", translation: "знищувати", transcription: "/əˈnaɪəleɪt/", exampleSentence: "Annihilate the enemy.", exampleTranslation: "Знищ ворога.", synonyms: ["destroy"], difficulty: .c1),
        Word(id: "c1_108", original: "annotate", translation: "коментувати", transcription: "/ˈænəteɪt/", exampleSentence: "Annotate the text.", exampleTranslation: "Прокоментуй текст.", synonyms: ["explain"], difficulty: .c1),
        Word(id: "c1_109", original: "annuity", translation: "річна рента", transcription: "/əˈnuːəti/", exampleSentence: "Life annuity.", exampleTranslation: "Довічна рента.", synonyms: [], difficulty: .c1),
        Word(id: "c1_110", original: "anoint", translation: "помазувати", transcription: "/əˈnɔɪnt/", exampleSentence: "Anoint the king.", exampleTranslation: "Помаж короля.", synonyms: ["consecrate"], difficulty: .c1),
        Word(id: "c1_111", original: "anomalous", translation: "аномальний", transcription: "/əˈnɑːmələs/", exampleSentence: "Anomalous result.", exampleTranslation: "Аномальний результат.", synonyms: ["abnormal"], difficulty: .c1),
        Word(id: "c1_112", original: "anomaly", translation: "аномалія", transcription: "/əˈnɑːməli/", exampleSentence: "Statistical anomaly.", exampleTranslation: "Статистична аномалія.", synonyms: ["irregularity"], difficulty: .c1),
        Word(id: "c1_113", original: "antagonism", translation: "антагонізм", transcription: "/ænˈtæɡənɪzəm/", exampleSentence: "Feel antagonism.", exampleTranslation: "Відчувай антагонізм.", synonyms: ["hostility"], difficulty: .c1),
        Word(id: "c1_114", original: "antagonist", translation: "антагоніст", transcription: "/ænˈtæɡənɪst/", exampleSentence: "The main antagonist.", exampleTranslation: "Головний антагоніст.", synonyms: ["opponent"], difficulty: .c1),
        Word(id: "c1_115", original: "antecedent", translation: "попередник", transcription: "/ˌæntɪˈsiːdənt/", exampleSentence: "Historical antecedent.", exampleTranslation: "Історичний попередник.", synonyms: ["predecessor"], difficulty: .c1),
        Word(id: "c1_116", original: "antediluvian", translation: "допотопний", transcription: "/ˌæntɪdɪˈluːviən/", exampleSentence: "Antediluvian ideas.", exampleTranslation: "Допотопні ідеї.", synonyms: ["ancient"], difficulty: .c1),
        Word(id: "c1_117", original: "anthology", translation: "антологія", transcription: "/ænˈθɑːlədʒi/", exampleSentence: "Poetry anthology.", exampleTranslation: "Поетична антологія.", synonyms: ["collection"], difficulty: .c1),
        Word(id: "c1_118", original: "anthropology", translation: "антропологія", transcription: "/ˌænθrəˈpɑːlədʒi/", exampleSentence: "Study anthropology.", exampleTranslation: "Вивчай антропологію.", synonyms: [], difficulty: .c1)
    ]
    
        static let c2Words: [Word] = [
            Word(id: "c2_001", original: "abate", translation: "зменшуватися", transcription: "/əˈbeɪt/", exampleSentence: "The storm began to abate.", exampleTranslation: "Буря почала стихати.", synonyms: ["subside", "diminish"], difficulty: .c2),
            Word(id: "c2_002", original: "aberration", translation: "відхилення", transcription: "/ˌæbəˈreɪʃn/", exampleSentence: "A temporary aberration from the norm.", exampleTranslation: "Тимчасове відхилення від норми.", synonyms: ["anomaly", "deviation"], difficulty: .c2),
            Word(id: "c2_003", original: "abeyance", translation: "відкладення", transcription: "/əˈbeɪəns/", exampleSentence: "The project is in abeyance.", exampleTranslation: "Проект відкладено.", synonyms: ["suspension", "postponement"], difficulty: .c2),
            Word(id: "c2_004", original: "abhorrent", translation: "огидний", transcription: "/əbˈhɔːrənt/", exampleSentence: "Abhorrent cruelty.", exampleTranslation: "Огидна жорстокість.", synonyms: ["detestable", "repugnant"], difficulty: .c2),
            Word(id: "c2_005", original: "abjure", translation: "відректися", transcription: "/əbˈdʒʊr/", exampleSentence: "Abjure one's allegiance.", exampleTranslation: "Відректися від вірності.", synonyms: ["renounce", "repudiate"], difficulty: .c2),
            Word(id: "c2_006", original: "ablution", translation: "омовіння", transcription: "/əˈbluːʃn/", exampleSentence: "Perform ablutions.", exampleTranslation: "Виконати омовіння.", synonyms: ["washing", "cleansing"], difficulty: .c2),
            Word(id: "c2_007", original: "abnegation", translation: "зречення", transcription: "/ˌæbnɪˈɡeɪʃn/", exampleSentence: "Self-abnegation.", exampleTranslation: "Самозречення.", synonyms: ["renunciation", "denial"], difficulty: .c2),
            Word(id: "c2_008", original: "abrogate", translation: "анулювати", transcription: "/ˈæbrəɡeɪt/", exampleSentence: "Abrogate a law.", exampleTranslation: "Анулювати закон.", synonyms: ["repeal", "nullify"], difficulty: .c2),
            Word(id: "c2_009", original: "abscond", translation: "втікати", transcription: "/əbˈskɑːnd/", exampleSentence: "Abscond with the funds.", exampleTranslation: "Втекти з коштами.", synonyms: ["flee", "escape"], difficulty: .c2),
            Word(id: "c2_010", original: "abstemious", translation: "поміркований", transcription: "/əbˈstiːmiəs/", exampleSentence: "Abstemious lifestyle.", exampleTranslation: "Поміркований спосіб життя.", synonyms: ["temperate", "moderate"], difficulty: .c2),
            Word(id: "c2_011", original: "abstruse", translation: "заплутаний", transcription: "/əbˈstruːs/", exampleSentence: "Abstruse philosophical concepts.", exampleTranslation: "Заплутані філософські концепції.", synonyms: ["obscure", "recondite"], difficulty: .c2),
            Word(id: "c2_012", original: "accede", translation: "погоджуватися", transcription: "/əkˈsiːd/", exampleSentence: "Accede to the throne.", exampleTranslation: "Зійти на трон.", synonyms: ["assent", "agree"], difficulty: .c2),
            Word(id: "c2_013", original: "acclamation", translation: "вигуки схвалення", transcription: "/ˌækləˈmeɪʃn/", exampleSentence: "Elected by acclamation.", exampleTranslation: "Обраний вигуками схвалення.", synonyms: ["applause", "ovation"], difficulty: .c2),
            Word(id: "c2_014", original: "accolade", translation: "нагорода", transcription: "/ˈækəleɪd/", exampleSentence: "Receive accolades.", exampleTranslation: "Отримати нагороди.", synonyms: ["honor", "award"], difficulty: .c2),
            Word(id: "c2_015", original: "accoutrement", translation: "спорядження", transcription: "/əˈkuːtrəmənt/", exampleSentence: "Military accoutrements.", exampleTranslation: "Військове спорядження.", synonyms: ["equipment", "gear"], difficulty: .c2),
            Word(id: "c2_016", original: "accretion", translation: "наростання", transcription: "/əˈkriːʃn/", exampleSentence: "Accretion of wealth.", exampleTranslation: "Наростання багатства.", synonyms: ["accumulation", "growth"], difficulty: .c2),
            Word(id: "c2_017", original: "acerbic", translation: "їдкий", transcription: "/əˈsɜːrbɪk/", exampleSentence: "Acerbic wit.", exampleTranslation: "Їдкий гумор.", synonyms: ["caustic", "biting"], difficulty: .c2),
            Word(id: "c2_018", original: "acquiesce", translation: "поступатися", transcription: "/ˌækwiˈes/", exampleSentence: "Acquiesce to demands.", exampleTranslation: "Поступитися вимогам.", synonyms: ["comply", "assent"], difficulty: .c2),
            Word(id: "c2_019", original: "acrimony", translation: "злоба", transcription: "/ˈækrɪmoʊni/", exampleSentence: "Bitter acrimony.", exampleTranslation: "Гірка злоба.", synonyms: ["bitterness", "resentment"], difficulty: .c2),
            Word(id: "c2_020", original: "adage", translation: "прислів'я", transcription: "/ˈædɪdʒ/", exampleSentence: "Old adage.", exampleTranslation: "Старе прислів'я.", synonyms: ["proverb", "maxim"], difficulty: .c2),
            Word(id: "c2_021", original: "adamant", translation: "непохитний", transcription: "/ˈædəmənt/", exampleSentence: "Adamant refusal.", exampleTranslation: "Непохитна відмова.", synonyms: ["unyielding", "inflexible"], difficulty: .c2),
            Word(id: "c2_022", original: "admonish", translation: "дорікати", transcription: "/ədˈmɑːnɪʃ/", exampleSentence: "Admonish sternly.", exampleTranslation: "Суворо дорікати.", synonyms: ["rebuke", "reprimand"], difficulty: .c2),
            Word(id: "c2_023", original: "adroit", translation: "вправний", transcription: "/əˈdrɔɪt/", exampleSentence: "Adroit negotiation.", exampleTranslation: "Вправні переговори.", synonyms: ["skillful", "dexterous"], difficulty: .c2),
            Word(id: "c2_024", original: "adulation", translation: "обожнювання", transcription: "/ˌædʒuˈleɪʃn/", exampleSentence: "Blind adulation.", exampleTranslation: "Сліпе обожнювання.", synonyms: ["flattery", "worship"], difficulty: .c2),
            Word(id: "c2_025", original: "adulterate", translation: "фальсифікувати", transcription: "/əˈdʌltəreɪt/", exampleSentence: "Adulterate food products.", exampleTranslation: "Фальсифікувати харчові продукти.", synonyms: ["contaminate", "debase"], difficulty: .c2),
            Word(id: "c2_026", original: "adumbrate", translation: "намітити", transcription: "/ˈædʌmbreɪt/", exampleSentence: "Adumbrate future plans.", exampleTranslation: "Намітити майбутні плани.", synonyms: ["outline", "sketch"], difficulty: .c2),
            Word(id: "c2_027", original: "aestheticism", translation: "естетизм", transcription: "/esˈθetɪsɪzəm/", exampleSentence: "Philosophy of aestheticism.", exampleTranslation: "Філософія естетизму.", synonyms: ["art for art's sake"], difficulty: .c2),
            Word(id: "c2_028", original: "affable", translation: "привітний", transcription: "/ˈæfəbl/", exampleSentence: "Affable host.", exampleTranslation: "Привітний господар.", synonyms: ["amiable", "genial"], difficulty: .c2),
            Word(id: "c2_029", original: "affinity", translation: "спорідненість", transcription: "/əˈfɪnəti/", exampleSentence: "Natural affinity.", exampleTranslation: "Природна спорідненість.", synonyms: ["kinship", "rapport"], difficulty: .c2),
            Word(id: "c2_030", original: "affluent", translation: "заможний", transcription: "/ˈæfluənt/", exampleSentence: "Affluent society.", exampleTranslation: "Заможне суспільство.", synonyms: ["wealthy", "prosperous"], difficulty: .c2),
            Word(id: "c2_031", original: "aggrandize", translation: "збільшувати", transcription: "/əˈɡrændaɪz/", exampleSentence: "Aggrandize one's power.", exampleTranslation: "Збільшити свою владу.", synonyms: ["exaggerate", "magnify"], difficulty: .c2),
            Word(id: "c2_032", original: "alacrity", translation: "готовність", transcription: "/əˈlækrəti/", exampleSentence: "Respond with alacrity.", exampleTranslation: "Відповісти з готовністю.", synonyms: ["eagerness", "promptness"], difficulty: .c2),
            Word(id: "c2_033", original: "alchemy", translation: "алхімія", transcription: "/ˈælkəmi/", exampleSentence: "Practice alchemy.", exampleTranslation: "Займатися алхімією.", synonyms: ["transmutation"], difficulty: .c2),
            Word(id: "c2_034", original: "allay", translation: "заспокоювати", transcription: "/əˈleɪ/", exampleSentence: "Allay fears.", exampleTranslation: "Заспокоїти страхи.", synonyms: ["soothe", "mitigate"], difficulty: .c2),
            Word(id: "c2_035", original: "allege", translation: "стверджувати", transcription: "/əˈledʒ/", exampleSentence: "Allege misconduct.", exampleTranslation: "Стверджувати про неправомірну поведінку.", synonyms: ["assert", "claim"], difficulty: .c2),
            Word(id: "c2_036", original: "alleviate", translation: "полегшувати", transcription: "/əˈliːvieɪt/", exampleSentence: "Alleviate suffering.", exampleTranslation: "Полегшити страждання.", synonyms: ["ease", "relieve"], difficulty: .c2),
            Word(id: "c2_037", original: "allocate", translation: "розподіляти", transcription: "/ˈæləkeɪt/", exampleSentence: "Allocate resources wisely.", exampleTranslation: "Мудро розподіляти ресурси.", synonyms: ["assign", "distribute"], difficulty: .c2),
            Word(id: "c2_038", original: "allude", translation: "натякати", transcription: "/əˈluːd/", exampleSentence: "Allude to the scandal.", exampleTranslation: "Натякати на скандал.", synonyms: ["hint", "imply"], difficulty: .c2),
            Word(id: "c2_039", original: "aloof", translation: "віддалений", transcription: "/əˈluːf/", exampleSentence: "Remain aloof.", exampleTranslation: "Залишатися віддаленим.", synonyms: ["distant", "reserved"], difficulty: .c2),
            Word(id: "c2_040", original: "altercation", translation: "сварка", transcription: "/ˌɔːltərˈkeɪʃn/", exampleSentence: "Heated altercation.", exampleTranslation: "Гаряча сварка.", synonyms: ["dispute", "quarrel"], difficulty: .c2),
            Word(id: "c2_041", original: "altruism", translation: "альтруїзм", transcription: "/ˈæltruɪzəm/", exampleSentence: "Pure altruism.", exampleTranslation: "Чистий альтруїзм.", synonyms: ["selflessness"], difficulty: .c2),
            Word(id: "c2_042", original: "amalgamate", translation: "об'єднувати", transcription: "/əˈmælɡəmeɪt/", exampleSentence: "Amalgamate companies.", exampleTranslation: "Об'єднати компанії.", synonyms: ["merge", "combine"], difficulty: .c2),
            Word(id: "c2_043", original: "ambivalent", translation: "амбівалентний", transcription: "/æmˈbɪvələnt/", exampleSentence: "Feel ambivalent.", exampleTranslation: "Відчувати амбівалентність.", synonyms: ["conflicted", "uncertain"], difficulty: .c2),
            Word(id: "c2_044", original: "ameliorate", translation: "покращувати", transcription: "/əˈmiːliəreɪt/", exampleSentence: "Ameliorate conditions.", exampleTranslation: "Покращити умови.", synonyms: ["improve", "better"], difficulty: .c2),
            Word(id: "c2_045", original: "amenable", translation: "поступливий", transcription: "/əˈmiːnəbl/", exampleSentence: "Amenable to reason.", exampleTranslation: "Поступливий до розуму.", synonyms: ["responsive", "agreeable"], difficulty: .c2),
            Word(id: "c2_046", original: "amiable", translation: "приємний", transcription: "/ˈeɪmiəbl/", exampleSentence: "Amiable disposition.", exampleTranslation: "Приємний характер.", synonyms: ["friendly", "pleasant"], difficulty: .c2),
            Word(id: "c2_047", original: "amicable", translation: "дружній", transcription: "/ˈæmɪkəbl/", exampleSentence: "Amicable divorce.", exampleTranslation: "Дружній розлучення.", synonyms: ["peaceful", "cordial"], difficulty: .c2),
            Word(id: "c2_048", original: "amnesty", translation: "амністія", transcription: "/ˈæmnəsti/", exampleSentence: "Grant amnesty.", exampleTranslation: "Надати амністію.", synonyms: ["pardon", "forgiveness"], difficulty: .c2),
            Word(id: "c2_049", original: "amorphous", translation: "аморфний", transcription: "/əˈmɔːrfəs/", exampleSentence: "Amorphous structure.", exampleTranslation: "Аморфна структура.", synonyms: ["shapeless", "formless"], difficulty: .c2),
            Word(id: "c2_050", original: "anachronism", translation: "анахронізм", transcription: "/əˈnækrənɪzəm/", exampleSentence: "Historical anachronism.", exampleTranslation: "Історичний анахронізм.", synonyms: ["misdating"], difficulty: .c2),
            Word(id: "c2_051", original: "analgesic", translation: "знеболююче", transcription: "/ˌænəlˈdʒiːzɪk/", exampleSentence: "Strong analgesic.", exampleTranslation: "Сильне знеболююче.", synonyms: ["painkiller"], difficulty: .c2),
            Word(id: "c2_052", original: "analogous", translation: "аналогічний", transcription: "/əˈnæləɡəs/", exampleSentence: "Analogous situation.", exampleTranslation: "Аналогічна ситуація.", synonyms: ["similar", "comparable"], difficulty: .c2),
            Word(id: "c2_053", original: "anarchy", translation: "анархія", transcription: "/ˈænərki/", exampleSentence: "Political anarchy.", exampleTranslation: "Політична анархія.", synonyms: ["chaos", "disorder"], difficulty: .c2),
            Word(id: "c2_054", original: "anathema", translation: "анафема", transcription: "/əˈnæθəmə/", exampleSentence: "Anathema to progress.", exampleTranslation: "Анафема прогресу.", synonyms: ["curse", "abomination"], difficulty: .c2),
            Word(id: "c2_055", original: "ancillary", translation: "допоміжний", transcription: "/ˈænsəleri/", exampleSentence: "Ancillary staff.", exampleTranslation: "Допоміжний персонал.", synonyms: ["auxiliary", "subsidiary"], difficulty: .c2),
            Word(id: "c2_056", original: "anecdote", translation: "анекдот", transcription: "/ˈænɪkdoʊt/", exampleSentence: "Amusing anecdote.", exampleTranslation: "Смішний анекдот.", synonyms: ["story", "tale"], difficulty: .c2),
            Word(id: "c2_057", original: "animosity", translation: "ворожнеча", transcription: "/ˌænɪˈmɑːsəti/", exampleSentence: "Deep animosity.", exampleTranslation: "Глибока ворожнеча.", synonyms: ["hostility", "antagonism"], difficulty: .c2),
            Word(id: "c2_058", original: "annals", translation: "літопис", transcription: "/ˈænlz/", exampleSentence: "Historical annals.", exampleTranslation: "Історичний літопис.", synonyms: ["chronicles", "records"], difficulty: .c2),
            Word(id: "c2_059", original: "annex", translation: "приєднувати", transcription: "/əˈneks/", exampleSentence: "Annex territory.", exampleTranslation: "Приєднати територію.", synonyms: ["acquire", "appropriate"], difficulty: .c2),
            Word(id: "c2_060", original: "annihilate", translation: "знищувати", transcription: "/əˈnaɪəleɪt/", exampleSentence: "Annihilate completely.", exampleTranslation: "Знищити повністю.", synonyms: ["destroy", "obliterate"], difficulty: .c2),
            Word(id: "c2_061", original: "annotate", translation: "коментувати", transcription: "/ˈænəteɪt/", exampleSentence: "Annotate extensively.", exampleTranslation: "Детально коментувати.", synonyms: ["explain", "elucidate"], difficulty: .c2),
            Word(id: "c2_062", original: "anomalous", translation: "аномальний", transcription: "/əˈnɑːmələs/", exampleSentence: "Anomalous behavior.", exampleTranslation: "Аномальна поведінка.", synonyms: ["abnormal", "irregular"], difficulty: .c2),
            Word(id: "c2_063", original: "antagonism", translation: "антагонізм", transcription: "/ænˈtæɡənɪzəm/", exampleSentence: "Mutual antagonism.", exampleTranslation: "Взаємний антагонізм.", synonyms: ["hostility", "opposition"], difficulty: .c2),
            Word(id: "c2_064", original: "antagonist", translation: "антагоніст", transcription: "/ænˈtæɡənɪst/", exampleSentence: "Chief antagonist.", exampleTranslation: "Головний антагоніст.", synonyms: ["opponent", "adversary"], difficulty: .c2),
            Word(id: "c2_065", original: "antecedent", translation: "попередник", transcription: "/ˌæntɪˈsiːdənt/", exampleSentence: "Historical antecedent.", exampleTranslation: "Історичний попередник.", synonyms: ["predecessor", "forerunner"], difficulty: .c2),
            Word(id: "c2_066", original: "antediluvian", translation: "допотопний", transcription: "/ˌæntɪdɪˈluːviən/", exampleSentence: "Antediluvian attitudes.", exampleTranslation: "Допотопні погляди.", synonyms: ["ancient", "archaic"], difficulty: .c2),
            Word(id: "c2_067", original: "anthology", translation: "антологія", transcription: "/ænˈθɑːlədʒi/", exampleSentence: "Literary anthology.", exampleTranslation: "Літературна антологія.", synonyms: ["collection", "compilation"], difficulty: .c2),
            Word(id: "c2_068", original: "anthropology", translation: "антропологія", transcription: "/ˌænθrəˈpɑːlədʒi/", exampleSentence: "Cultural anthropology.", exampleTranslation: "Культурна антропологія.", synonyms: [], difficulty: .c2),
            Word(id: "c2_069", original: "anticipate", translation: "передбачати", transcription: "/ænˈtɪsɪpeɪt/", exampleSentence: "Anticipate problems.", exampleTranslation: "Передбачити проблеми.", synonyms: ["expect", "foresee"], difficulty: .c2),
            Word(id: "c2_070", original: "antipathy", translation: "антипатія", transcription: "/ænˈtɪpəθi/", exampleSentence: "Strong antipathy.", exampleTranslation: "Сильна антипатія.", synonyms: ["aversion", "dislike"], difficulty: .c2),
            Word(id: "c2_071", original: "antiquated", translation: "застарілий", transcription: "/ˈæntɪkweɪtɪd/", exampleSentence: "Antiquated system.", exampleTranslation: "Застаріла система.", synonyms: ["obsolete", "outdated"], difficulty: .c2),
            Word(id: "c2_072", original: "antithesis", translation: "антитеза", transcription: "/ænˈtɪθəsɪs/", exampleSentence: "Direct antithesis.", exampleTranslation: "Пряма антитеза.", synonyms: ["opposite", "contrast"], difficulty: .c2),
            Word(id: "c2_073", original: "apathetic", translation: "апатичний", transcription: "/ˌæpəˈθetɪk/", exampleSentence: "Apathetic response.", exampleTranslation: "Апатична відповідь.", synonyms: ["indifferent", "unconcerned"], difficulty: .c2),
            Word(id: "c2_074", original: "apocryphal", translation: "апокрифічний", transcription: "/əˈpɑːkrɪfl/", exampleSentence: "Apocryphal story.", exampleTranslation: "Апокрифічна історія.", synonyms: ["dubious", "questionable"], difficulty: .c2),
            Word(id: "c2_075", original: "apotheosis", translation: "апофеоз", transcription: "/əˌpɑːθiˈoʊsɪs/", exampleSentence: "Apotheosis of virtue.", exampleTranslation: "Апофеоз чесноти.", synonyms: ["culmination", "peak"], difficulty: .c2),
            Word(id: "c2_076", original: "appall", translation: "жахати", transcription: "/əˈpɔːl/", exampleSentence: "Appalling conditions.", exampleTranslation: "Жахливі умови.", synonyms: ["horrify", "shock"], difficulty: .c2),
            Word(id: "c2_077", original: "appease", translation: "заспокоювати", transcription: "/əˈpiːz/", exampleSentence: "Appease the crowd.", exampleTranslation: "Заспокоїти натовп.", synonyms: ["pacify", "placate"], difficulty: .c2),
            Word(id: "c2_078", original: "appellation", translation: "назва", transcription: "/ˌæpəˈleɪʃn/", exampleSentence: "Formal appellation.", exampleTranslation: "Офіційна назва.", synonyms: ["name", "title"], difficulty: .c2),
            Word(id: "c2_079", original: "append", translation: "додавати", transcription: "/əˈpend/", exampleSentence: "Append a note.", exampleTranslation: "Додати примітку.", synonyms: ["attach", "add"], difficulty: .c2),
            Word(id: "c2_080", original: "apportion", translation: "розподіляти", transcription: "/əˈpɔːrʃn/", exampleSentence: "Apportion blame.", exampleTranslation: "Розподілити провину.", synonyms: ["allocate", "distribute"], difficulty: .c2),
            Word(id: "c2_081", original: "apposite", translation: "доречний", transcription: "/ˈæpəzɪt/", exampleSentence: "Apposite remark.", exampleTranslation: "Доречне зауваження.", synonyms: ["appropriate", "apt"], difficulty: .c2),
            Word(id: "c2_082", original: "apprehend", translation: "затримувати", transcription: "/ˌæprɪˈhend/", exampleSentence: "Apprehend the suspect.", exampleTranslation: "Затримати підозрюваного.", synonyms: ["arrest", "capture"], difficulty: .c2),
            Word(id: "c2_083", original: "apprehensive", translation: "тривожний", transcription: "/ˌæprɪˈhensɪv/", exampleSentence: "Feel apprehensive.", exampleTranslation: "Відчувати тривогу.", synonyms: ["anxious", "worried"], difficulty: .c2),
            Word(id: "c2_084", original: "apprise", translation: "інформувати", transcription: "/əˈpraɪz/", exampleSentence: "Apprise of the situation.", exampleTranslation: "Проінформувати про ситуацію.", synonyms: ["inform", "notify"], difficulty: .c2),
            Word(id: "c2_085", original: "approbation", translation: "схвалення", transcription: "/ˌæprəˈbeɪʃn/", exampleSentence: "Official approbation.", exampleTranslation: "Офіційне схвалення.", synonyms: ["approval", "praise"], difficulty: .c2),
            Word(id: "c2_086", original: "appropriate", translation: "привласнювати", transcription: "/əˈproʊprieɪt/", exampleSentence: "Appropriate funds.", exampleTranslation: "Привласнити кошти.", synonyms: ["seize", "take"], difficulty: .c2),
            Word(id: "c2_087", original: "apropos", translation: "доречно", transcription: "/ˌæprəˈpoʊ/", exampleSentence: "Apropos of nothing.", exampleTranslation: "Доречно ні до чого.", synonyms: ["relevant", "pertinent"], difficulty: .c2),
            Word(id: "c2_088", original: "arbiter", translation: "арбітр", transcription: "/ˈɑːrbɪtər/", exampleSentence: "Final arbiter.", exampleTranslation: "Остаточний арбітр.", synonyms: ["judge", "authority"], difficulty: .c2),
            Word(id: "c2_089", original: "arbitrary", translation: "довільний", transcription: "/ˈɑːrbətreri/", exampleSentence: "Arbitrary decision.", exampleTranslation: "Довільне рішення.", synonyms: ["random", "capricious"], difficulty: .c2),
            Word(id: "c2_090", original: "arcane", translation: "таємний", transcription: "/ɑːrˈkeɪn/", exampleSentence: "Arcane knowledge.", exampleTranslation: "Таємні знання.", synonyms: ["mysterious", "esoteric"], difficulty: .c2),
            Word(id: "c2_091", original: "archaic", translation: "архаїчний", transcription: "/ɑːrˈkeɪɪk/", exampleSentence: "Archaic language.", exampleTranslation: "Архаїчна мова.", synonyms: ["ancient", "antiquated"], difficulty: .c2),
            Word(id: "c2_092", original: "archetype", translation: "архетип", transcription: "/ˈɑːrkitaɪp/", exampleSentence: "Classic archetype.", exampleTranslation: "Класичний архетип.", synonyms: ["prototype", "model"], difficulty: .c2),
            Word(id: "c2_093", original: "ardent", translation: "палкий", transcription: "/ˈɑːrdnt/", exampleSentence: "Ardent supporter.", exampleTranslation: "Палкий прихильник.", synonyms: ["passionate", "fervent"], difficulty: .c2),
            Word(id: "c2_094", original: "arduous", translation: "важкий", transcription: "/ˈɑːrdʒuəs/", exampleSentence: "Arduous task.", exampleTranslation: "Важке завдання.", synonyms: ["difficult", "strenuous"], difficulty: .c2),
            Word(id: "c2_095", original: "argot", translation: "жаргон", transcription: "/ˈɑːrɡoʊ/", exampleSentence: "Professional argot.", exampleTranslation: "Професійний жаргон.", synonyms: ["jargon", "slang"], difficulty: .c2),
            Word(id: "c2_096", original: "arid", translation: "посушливий", transcription: "/ˈærɪd/", exampleSentence: "Arid climate.", exampleTranslation: "Посушливий клімат.", synonyms: ["dry", "barren"], difficulty: .c2),
            Word(id: "c2_097", original: "arrogate", translation: "привласнювати", transcription: "/ˈærəɡeɪt/", exampleSentence: "Arrogate power.", exampleTranslation: "Привласнити владу.", synonyms: ["claim", "seize"], difficulty: .c2),
            Word(id: "c2_098", original: "articulate", translation: "чітко висловлювати", transcription: "/ɑːrˈtɪkjuleɪt/", exampleSentence: "Articulate clearly.", exampleTranslation: "Чітко висловлювати.", synonyms: ["express", "enunciate"], difficulty: .c2),
            Word(id: "c2_099", original: "artifact", translation: "артефакт", transcription: "/ˈɑːrtɪfækt/", exampleSentence: "Ancient artifact.", exampleTranslation: "Стародавній артефакт.", synonyms: ["relic", "remnant"], difficulty: .c2),
            Word(id: "c2_100", original: "artifice", translation: "хитрість", transcription: "/ˈɑːrtɪfɪs/", exampleSentence: "Clever artifice.", exampleTranslation: "Розумна хитрість.", synonyms: ["trickery", "deception"], difficulty: .c2),
            Word(id: "c2_101", original: "artless", translation: "невинний", transcription: "/ˈɑːrtləs/", exampleSentence: "Artless sincerity.", exampleTranslation: "Невинна щирість.", synonyms: ["naive", "genuine"], difficulty: .c2),
            Word(id: "c2_102", original: "ascendancy", translation: "перевага", transcription: "/əˈsendənsi/", exampleSentence: "Gain ascendancy.", exampleTranslation: "Отримати перевагу.", synonyms: ["dominance", "supremacy"], difficulty: .c2),
            Word(id: "c2_103", original: "ascertain", translation: "з'ясовувати", transcription: "/ˌæsərˈteɪn/", exampleSentence: "Ascertain the facts.", exampleTranslation: "З'ясувати факти.", synonyms: ["determine", "discover"], difficulty: .c2),
            Word(id: "c2_104", original: "ascetic", translation: "аскетичний", transcription: "/əˈsetɪk/", exampleSentence: "Ascetic lifestyle.", exampleTranslation: "Аскетичний спосіб життя.", synonyms: ["austere", "rigorous"], difficulty: .c2),
            Word(id: "c2_105", original: "ascribe", translation: "приписувати", transcription: "/əˈskraɪb/", exampleSentence: "Ascribe to causes.", exampleTranslation: "Приписувати причинам.", synonyms: ["attribute", "assign"], difficulty: .c2),
            Word(id: "c2_106", original: "asperity", translation: "суворість", transcription: "/əˈsperəti/", exampleSentence: "Asperity of manner.", exampleTranslation: "Суворість манер.", synonyms: ["harshness", "severity"], difficulty: .c2),
            Word(id: "c2_107", original: "aspersion", translation: "наклеп", transcription: "/əˈspɜːrʒn/", exampleSentence: "Cast aspersions.", exampleTranslation: "Розпускати наклепи.", synonyms: ["slander", "defamation"], difficulty: .c2),
            Word(id: "c2_108", original: "aspirant", translation: "претендент", transcription: "/ˈæspərənt/", exampleSentence: "Presidential aspirant.", exampleTranslation: "Претендент на президентство.", synonyms: ["candidate", "seeker"], difficulty: .c2),
            Word(id: "c2_109", original: "assail", translation: "нападати", transcription: "/əˈseɪl/", exampleSentence: "Assail vigorously.", exampleTranslation: "Енергійно нападати.", synonyms: ["attack", "assault"], difficulty: .c2),
            Word(id: "c2_110", original: "assay", translation: "аналіз", transcription: "/əˈseɪ/", exampleSentence: "Assay the ore.", exampleTranslation: "Проаналізувати руду.", synonyms: ["test", "evaluate"], difficulty: .c2),
            Word(id: "c2_111", original: "assiduous", translation: "старанний", transcription: "/əˈsɪdʒuəs/", exampleSentence: "Assiduous effort.", exampleTranslation: "Старанні зусилля.", synonyms: ["diligent", "persevering"], difficulty: .c2),
            Word(id: "c2_112", original: "assuage", translation: "заспокоювати", transcription: "/əˈsweɪdʒ/", exampleSentence: "Assuage grief.", exampleTranslation: "Заспокоїти горе.", synonyms: ["soothe", "alleviate"], difficulty: .c2),
            Word(id: "c2_113", original: "astringent", translation: "в'яжучий", transcription: "/əˈstrɪndʒənt/", exampleSentence: "Astringent criticism.", exampleTranslation: "В'яжуча критика.", synonyms: ["severe", "harsh"], difficulty: .c2),
            Word(id: "c2_114", original: "asylum", translation: "притулок", transcription: "/əˈsaɪləm/", exampleSentence: "Seek asylum.", exampleTranslation: "Шукати притулок.", synonyms: ["refuge", "sanctuary"], difficulty: .c2),
            Word(id: "c2_115", original: "atone", translation: "спокутувати", transcription: "/əˈtoʊn/", exampleSentence: "Atone for sins.", exampleTranslation: "Спокутувати гріхи.", synonyms: ["make amends", "expiate"], difficulty: .c2),
            Word(id: "c2_116", original: "atrocity", translation: "звірство", transcription: "/əˈtrɑːsəti/", exampleSentence: "War atrocity.", exampleTranslation: "Воєнне звірство.", synonyms: ["brutality", "cruelty"], difficulty: .c2),
            Word(id: "c2_117", original: "atrophy", translation: "атрофія", transcription: "/ˈætrəfi/", exampleSentence: "Muscle atrophy.", exampleTranslation: "М'язова атрофія.", synonyms: ["degeneration", "decline"], difficulty: .c2),
            Word(id: "c2_118", original: "attain", translation: "досягати", transcription: "/əˈteɪn/", exampleSentence: "Attain perfection.", exampleTranslation: "Досягти досконалості.", synonyms: ["achieve", "accomplish"], difficulty: .c2),
            Word(id: "c2_119", original: "attest", translation: "засвідчувати", transcription: "/əˈtest/", exampleSentence: "Attest to the truth.", exampleTranslation: "Засвідчити правду.", synonyms: ["certify", "verify"], difficulty: .c2),
            Word(id: "c2_120", original: "attribute", translation: "приписувати", transcription: "/əˈtrɪbjuːt/", exampleSentence: "Attribute to causes.", exampleTranslation: "Приписувати причинам.", synonyms: ["ascribe", "assign"], difficulty: .c2),
            Word(id: "c2_121", original: "attrition", translation: "виснаження", transcription: "/əˈtrɪʃn/", exampleSentence: "War of attrition.", exampleTranslation: "Війна на виснаження.", synonyms: ["wear and tear", "erosion"], difficulty: .c2),
            Word(id: "c2_122", original: "atypical", translation: "нетиповий", transcription: "/eɪˈtɪpɪkl/", exampleSentence: "Atypical behavior.", exampleTranslation: "Нетипова поведінка.", synonyms: ["unusual", "abnormal"], difficulty: .c2),
            Word(id: "c2_123", original: "audacious", translation: "сміливий", transcription: "/ɔːˈdeɪʃəs/", exampleSentence: "Audacious plan.", exampleTranslation: "Сміливий план.", synonyms: ["bold", "daring"], difficulty: .c2),
            Word(id: "c2_124", original: "august", translation: "величний", transcription: "/ɔːˈɡʌst/", exampleSentence: "August presence.", exampleTranslation: "Велична присутність.", synonyms: ["majestic", "dignified"], difficulty: .c2),
            Word(id: "c2_125", original: "auspices", translation: "покровительство", transcription: "/ˈɔːspɪsɪz/", exampleSentence: "Under the auspices.", exampleTranslation: "Під покровительством.", synonyms: ["patronage", "sponsorship"], difficulty: .c2),
            Word(id: "c2_126", original: "austere", translation: "суворий", transcription: "/ɔːˈstɪr/", exampleSentence: "Austere conditions.", exampleTranslation: "Суворі умови.", synonyms: ["severe", "strict"], difficulty: .c2),
            Word(id: "c2_127", original: "autonomous", translation: "автономний", transcription: "/ɔːˈtɑːnəməs/", exampleSentence: "Autonomous region.", exampleTranslation: "Автономний регіон.", synonyms: ["independent", "self-governing"], difficulty: .c2),
            Word(id: "c2_128", original: "avarice", translation: "жадібність", transcription: "/ˈævərɪs/", exampleSentence: "Insatiable avarice.", exampleTranslation: "Ненаситна жадібність.", synonyms: ["greed", "cupidity"], difficulty: .c2),
            Word(id: "c2_129", original: "aver", translation: "стверджувати", transcription: "/əˈvɜːr/", exampleSentence: "Aver the truth.", exampleTranslation: "Стверджувати правду.", synonyms: ["assert", "affirm"], difficulty: .c2),
            Word(id: "c2_130", original: "aversion", translation: "відраза", transcription: "/əˈvɜːrʒn/", exampleSentence: "Strong aversion.", exampleTranslation: "Сильна відраза.", synonyms: ["dislike", "antipathy"], difficulty: .c2),
            Word(id: "c2_131", original: "avid", translation: "запальний", transcription: "/ˈævɪd/", exampleSentence: "Avid reader.", exampleTranslation: "Запальний читач.", synonyms: ["eager", "enthusiastic"], difficulty: .c2),
            Word(id: "c2_132", original: "avow", translation: "визнавати", transcription: "/əˈvaʊ/", exampleSentence: "Avow one's beliefs.", exampleTranslation: "Визнати свої переконання.", synonyms: ["admit", "confess"], difficulty: .c2),
            Word(id: "c2_133", original: "awry", translation: "криво", transcription: "/əˈraɪ/", exampleSentence: "Go awry.", exampleTranslation: "Піти криво.", synonyms: ["wrong", "amiss"], difficulty: .c2),
            Word(id: "c2_134", original: "axiom", translation: "аксіома", transcription: "/ˈæksiəm/", exampleSentence: "Fundamental axiom.", exampleTranslation: "Фундаментальна аксіома.", synonyms: ["maxim", "truth"], difficulty: .c2),
            Word(id: "c2_135", original: "azure", translation: "лазурний", transcription: "/ˈæʒər/", exampleSentence: "Azure sky.", exampleTranslation: "Лазурне небо.", synonyms: ["sky-blue", "cerulean"], difficulty: .c2),
            Word(id: "c2_136", original: "babble", translation: "бурмотіти", transcription: "/ˈbæbl/", exampleSentence: "Babble incoherently.", exampleTranslation: "Бурмотіти невнятно.", synonyms: ["prattle", "chatter"], difficulty: .c2),
            Word(id: "c2_137", original: "baleful", translation: "зловісний", transcription: "/ˈbeɪlfl/", exampleSentence: "Baleful glance.", exampleTranslation: "Зловісний погляд.", synonyms: ["menacing", "sinister"], difficulty: .c2),
            Word(id: "c2_138", original: "balk", translation: "зупинятися", transcription: "/bɔːk/", exampleSentence: "Balk at the price.", exampleTranslation: "Зупинитися через ціну.", synonyms: ["hesitate", "refuse"], difficulty: .c2),
            Word(id: "c2_139", original: "banal", translation: "банальний", transcription: "/bəˈnɑːl/", exampleSentence: "Banal remark.", exampleTranslation: "Банальне зауваження.", synonyms: ["trite", "commonplace"], difficulty: .c2),
            Word(id: "c2_140", original: "bane", translation: "загибель", transcription: "/beɪn/", exampleSentence: "The bane of existence.", exampleTranslation: "Загибель існування.", synonyms: ["curse", "ruin"], difficulty: .c2),
            Word(id: "c2_141", original: "banter", translation: "жарти", transcription: "/ˈbæntər/", exampleSentence: "Playful banter.", exampleTranslation: "Грайливі жарти.", synonyms: ["teasing", "raillery"], difficulty: .c2),
            Word(id: "c2_142", original: "baroque", translation: "бароко", transcription: "/bəˈroʊk/", exampleSentence: "Baroque architecture.", exampleTranslation: "Барокова архітектура.", synonyms: ["ornate", "elaborate"], difficulty: .c2),
            Word(id: "c2_143", original: "barrage", translation: "бар'єр", transcription: "/bəˈrɑːʒ/", exampleSentence: "A barrage of questions.", exampleTranslation: "Потік питань.", synonyms: ["bombardment", "deluge"], difficulty: .c2),
            Word(id: "c2_144", original: "barren", translation: "безплідний", transcription: "/ˈbærən/", exampleSentence: "Barren land.", exampleTranslation: "Безплідна земля.", synonyms: ["sterile", "arid"], difficulty: .c2),
            Word(id: "c2_145", original: "bastion", translation: "бастіон", transcription: "/ˈbæstiən/", exampleSentence: "Last bastion.", exampleTranslation: "Останній бастіон.", synonyms: ["stronghold", "citadel"], difficulty: .c2),
            Word(id: "c2_146", original: "bay", translation: "загнати в кут", transcription: "/beɪ/", exampleSentence: "Keep at bay.", exampleTranslation: "Тримати на відстані.", synonyms: ["restrain", "check"], difficulty: .c2),
            Word(id: "c2_147", original: "beatific", translation: "блаженний", transcription: "/ˌbiːəˈtɪfɪk/", exampleSentence: "Beatific smile.", exampleTranslation: "Блаженна посмішка.", synonyms: ["blissful", "serene"], difficulty: .c2),
            Word(id: "c2_148", original: "bedlam", translation: "пекло", transcription: "/ˈbedləm/", exampleSentence: "Complete bedlam.", exampleTranslation: "Повне пекло.", synonyms: ["chaos", "pandemonium"], difficulty: .c2),
            Word(id: "c2_149", original: "befuddle", translation: "збивати з пантелику", transcription: "/bɪˈfʌdl/", exampleSentence: "Befuddle completely.", exampleTranslation: "Повністю збити з пантелику.", synonyms: ["confuse", "bewilder"], difficulty: .c2),
            Word(id: "c2_150", original: "beget", translation: "породжувати", transcription: "/bɪˈɡet/", exampleSentence: "Beget violence.", exampleTranslation: "Породжувати насильство.", synonyms: ["produce", "generate"], difficulty: .c2),
            Word(id: "c2_151", original: "begrudge", translation: "заздрити", transcription: "/bɪˈɡrʌdʒ/", exampleSentence: "Begrudge success.", exampleTranslation: "Заздрити успіху.", synonyms: ["resent", "envy"], difficulty: .c2),
            Word(id: "c2_152", original: "beguile", translation: "зачаровувати", transcription: "/bɪˈɡaɪl/", exampleSentence: "Beguile the time.", exampleTranslation: "Зачарувати час.", synonyms: ["charm", "enchant"], difficulty: .c2),
            Word(id: "c2_153", original: "behemoth", translation: "чудовисько", transcription: "/bɪˈhiːməθ/", exampleSentence: "Corporate behemoth.", exampleTranslation: "Корпоративне чудовисько.", synonyms: ["giant", "leviathan"], difficulty: .c2),
            Word(id: "c2_154", original: "belie", translation: "спростовувати", transcription: "/bɪˈlaɪ/", exampleSentence: "Belie the appearance.", exampleTranslation: "Спростовувати зовнішність.", synonyms: ["contradict", "misrepresent"], difficulty: .c2),
            Word(id: "c2_155", original: "belittle", translation: "принижувати", transcription: "/bɪˈlɪtl/", exampleSentence: "Belittle achievements.", exampleTranslation: "Принижувати досягнення.", synonyms: ["disparage", "diminish"], difficulty: .c2),
            Word(id: "c2_156", original: "bellicose", translation: "войовничий", transcription: "/ˈbelɪkoʊs/", exampleSentence: "Bellicose rhetoric.", exampleTranslation: "Войовнича риторика.", synonyms: ["aggressive", "pugnacious"], difficulty: .c2),
            Word(id: "c2_157", original: "belligerent", translation: "бойовий", transcription: "/bəˈlɪdʒərənt/", exampleSentence: "Belligerent attitude.", exampleTranslation: "Бойова позиція.", synonyms: ["hostile", "combative"], difficulty: .c2),
            Word(id: "c2_158", original: "bemoan", translation: "оплакувати", transcription: "/bɪˈmoʊn/", exampleSentence: "Bemoan fate.", exampleTranslation: "Оплакувати долю.", synonyms: ["lament", "bewail"], difficulty: .c2),
            Word(id: "c2_159", original: "bemused", translation: "збентежений", transcription: "/bɪˈmjuːzd/", exampleSentence: "Bemused expression.", exampleTranslation: "Збентежений вираз.", synonyms: ["confused", "puzzled"], difficulty: .c2),
            Word(id: "c2_160", original: "benefactor", translation: "благодійник", transcription: "/ˈbenɪfæktər/", exampleSentence: "Generous benefactor.", exampleTranslation: "Щедрий благодійник.", synonyms: ["patron", "donor"], difficulty: .c2),
            Word(id: "c2_161", original: "benevolent", translation: "доброзичливий", transcription: "/bəˈnevələnt/", exampleSentence: "Benevolent dictator.", exampleTranslation: "Доброзичливий диктатор.", synonyms: ["kind", "charitable"], difficulty: .c2),
            Word(id: "c2_162", original: "benign", translation: "доброякісний", transcription: "/bɪˈnaɪn/", exampleSentence: "Benign tumor.", exampleTranslation: "Доброякісна пухлина.", synonyms: ["harmless", "favorable"], difficulty: .c2),
            Word(id: "c2_163", original: "bequeath", translation: "заповіщати", transcription: "/bɪˈkwiːð/", exampleSentence: "Bequeath fortune.", exampleTranslation: "Заповіщати статок.", synonyms: ["leave", "will"], difficulty: .c2),
            Word(id: "c2_164", original: "berate", translation: "лагодити", transcription: "/bɪˈreɪt/", exampleSentence: "Berate harshly.", exampleTranslation: "Суворо лаяти.", synonyms: ["scold", "rebuke"], difficulty: .c2),
            Word(id: "c2_165", original: "bereft", translation: "позбавлений", transcription: "/bɪˈreft/", exampleSentence: "Bereft of hope.", exampleTranslation: "Позбавлений надії.", synonyms: ["deprived", "lacking"], difficulty: .c2),
            Word(id: "c2_166", original: "beseech", translation: "благати", transcription: "/bɪˈsiːtʃ/", exampleSentence: "Beseech earnestly.", exampleTranslation: "Щиро благати.", synonyms: ["implore", "plead"], difficulty: .c2),
            Word(id: "c2_167", original: "besmirch", translation: "плямувати", transcription: "/bɪˈsmɜːrtʃ/", exampleSentence: "Besmirch reputation.", exampleTranslation: "Плямувати репутацію.", synonyms: ["sully", "tarnish"], difficulty: .c2)
            ]
    
    
    // MARK: - Category Words Arrays (sorted alphabetically)

    static let foodWords: [Word] = [
        Word(id: "food_001", original: "apple", translation: "яблуко", transcription: "/ˈæpl/", exampleSentence: "I eat an apple every day.", exampleTranslation: "Я їм яблуко щодня.", synonyms: ["fruit"], difficulty: .a1, category: .food),
        Word(id: "food_002", original: "banana", translation: "банан", transcription: "/bəˈnænə/", exampleSentence: "She likes bananas.", exampleTranslation: "Вона любить банани.", synonyms: ["fruit"], difficulty: .a1, category: .food),
        Word(id: "food_003", original: "beef", translation: "яловичина", transcription: "/biːf/", exampleSentence: "I prefer beef to pork.", exampleTranslation: "Я віддаю перевагу яловичині перед свининою.", synonyms: ["meat"], difficulty: .a1, category: .food),
        Word(id: "food_004", original: "beer", translation: "пиво", transcription: "/bɪər/", exampleSentence: "Would you like a beer?", exampleTranslation: "Хочеш пива?", synonyms: ["alcohol"], difficulty: .a1, category: .food),
        Word(id: "food_005", original: "bread", translation: "хліб", transcription: "/bred/", exampleSentence: "Fresh bread smells amazing.", exampleTranslation: "Свіжий хліб пахне чудово.", synonyms: ["baked"], difficulty: .a1, category: .food),
        Word(id: "food_006", original: "butter", translation: "вершкове масло", transcription: "/ˈbʌtər/", exampleSentence: "Pass me the butter, please.", exampleTranslation: "Передай мені масло, будь ласка.", synonyms: ["dairy"], difficulty: .a1, category: .food),
        Word(id: "food_007", original: "cake", translation: "торт", transcription: "/keɪk/", exampleSentence: "She baked a chocolate cake.", exampleTranslation: "Вона спекла шоколадний торт.", synonyms: ["dessert"], difficulty: .a1, category: .food),
        Word(id: "food_008", original: "cheese", translation: "сир", transcription: "/tʃiːz/", exampleSentence: "I love cheese on pizza.", exampleTranslation: "Я люблю сир на піці.", synonyms: ["dairy"], difficulty: .a1, category: .food),
        Word(id: "food_009", original: "chicken", translation: "курка", transcription: "/ˈtʃɪkɪn/", exampleSentence: "We had chicken for dinner.", exampleTranslation: "Ми їли курку на вечерю.", synonyms: ["meat", "poultry"], difficulty: .a1, category: .food),
        Word(id: "food_010", original: "chocolate", translation: "шоколад", transcription: "/ˈtʃɔːklət/", exampleSentence: "Dark chocolate is healthy.", exampleTranslation: "Чорний шоколад корисний.", synonyms: ["sweet"], difficulty: .a1, category: .food),
        Word(id: "food_011", original: "coffee", translation: "кава", transcription: "/ˈkɔːfi/", exampleSentence: "I need a cup of coffee.", exampleTranslation: "Мені потрібна чашка кави.", synonyms: ["drink", "beverage"], difficulty: .a1, category: .food),
        Word(id: "food_012", original: "cookie", translation: "печиво", transcription: "/ˈkʊki/", exampleSentence: "The kids love cookies.", exampleTranslation: "Діти люблять печиво.", synonyms: ["dessert", "sweet"], difficulty: .a1, category: .food),
        Word(id: "food_013", original: "cream", translation: "вершки", transcription: "/kriːm/", exampleSentence: "Add some cream to your coffee.", exampleTranslation: "Додай трохи вершків до кави.", synonyms: ["dairy"], difficulty: .a1, category: .food),
        Word(id: "food_014", original: "egg", translation: "яйце", transcription: "/eɡ/", exampleSentence: "I had boiled eggs for breakfast.", exampleTranslation: "Я зʼїв варені яйця на сніданок.", synonyms: ["protein"], difficulty: .a1, category: .food),
        Word(id: "food_015", original: "fish", translation: "риба", transcription: "/fɪʃ/", exampleSentence: "Fish is good for your health.", exampleTranslation: "Риба корисна для здоровʼя.", synonyms: ["seafood"], difficulty: .a1, category: .food),
        Word(id: "food_016", original: "flour", translation: "борошно", transcription: "/ˈflaʊər/", exampleSentence: "We need flour to make bread.", exampleTranslation: "Нам потрібне борошно, щоб пекти хліб.", synonyms: ["ingredient"], difficulty: .a1, category: .food),
        Word(id: "food_017", original: "grape", translation: "виноград", transcription: "/ɡreɪp/", exampleSentence: "Grapes are my favorite fruit.", exampleTranslation: "Виноград — мій улюблений фрукт.", synonyms: ["fruit"], difficulty: .a1, category: .food),
        Word(id: "food_018", original: "honey", translation: "мед", transcription: "/ˈhʌni/", exampleSentence: "Add some honey to your tea.", exampleTranslation: "Додай трохи меду до чаю.", synonyms: ["sweetener"], difficulty: .a1, category: .food),
        Word(id: "food_019", original: "ice cream", translation: "морозиво", transcription: "/ˈaɪs kriːm/", exampleSentence: "I love vanilla ice cream.", exampleTranslation: "Я люблю ванільне морозиво.", synonyms: ["dessert"], difficulty: .a1, category: .food),
        Word(id: "food_020", original: "juice", translation: "сік", transcription: "/dʒuːs/", exampleSentence: "Orange juice is refreshing.", exampleTranslation: "Апельсиновий сік освіжає.", synonyms: ["drink"], difficulty: .a1, category: .food),
        Word(id: "food_021", original: "lemon", translation: "лимон", transcription: "/ˈlemən/", exampleSentence: "Add lemon to your water.", exampleTranslation: "Додай лимон до води.", synonyms: ["fruit", "citrus"], difficulty: .a1, category: .food),
        Word(id: "food_022", original: "meat", translation: "м'ясо", transcription: "/miːt/", exampleSentence: "I do not eat red meat.", exampleTranslation: "Я не їм червоне мʼясо.", synonyms: ["protein"], difficulty: .a1, category: .food),
        Word(id: "food_023", original: "milk", translation: "молоко", transcription: "/mɪlk/", exampleSentence: "Drink your milk, it is good for you.", exampleTranslation: "Пий молоко, воно корисне для тебе.", synonyms: ["dairy"], difficulty: .a1, category: .food),
        Word(id: "food_024", original: "oil", translation: "олія", transcription: "/ɔɪl/", exampleSentence: "Fry the onions in oil.", exampleTranslation: "Смаж цибулю на олії.", synonyms: ["cooking"], difficulty: .a1, category: .food),
        Word(id: "food_025", original: "orange", translation: "апельсин", transcription: "/ˈɔːrɪndʒ/", exampleSentence: "Oranges are full of vitamin C.", exampleTranslation: "Апельсини повні вітаміну C.", synonyms: ["fruit", "citrus"], difficulty: .a1, category: .food),
        Word(id: "food_026", original: "pasta", translation: "паста", transcription: "/ˈpæstə/", exampleSentence: "Italian pasta is delicious.", exampleTranslation: "Італійська паста смачна.", synonyms: ["carbs"], difficulty: .a1, category: .food),
        Word(id: "food_027", original: "pepper", translation: "перець", transcription: "/ˈpepər/", exampleSentence: "Add salt and pepper.", exampleTranslation: "Додай сіль і перець.", synonyms: ["spice"], difficulty: .a1, category: .food),
        Word(id: "food_028", original: "pizza", translation: "піца", transcription: "/ˈpiːtsə/", exampleSentence: "Let us order pizza tonight.", exampleTranslation: "Давай замовимо піцу сьогодні ввечері.", synonyms: ["italian"], difficulty: .a1, category: .food),
        Word(id: "food_029", original: "pork", translation: "свинина", transcription: "/pɔːrk/", exampleSentence: "Pork chops are tasty.", exampleTranslation: "Свинячі відбивні смачні.", synonyms: ["meat"], difficulty: .a1, category: .food),
        Word(id: "food_030", original: "potato", translation: "картопля", transcription: "/pəˈteɪtoʊ/", exampleSentence: "Mashed potatoes are my favorite.", exampleTranslation: "Картопляне пюре — моє улюблене.", synonyms: ["vegetable"], difficulty: .a1, category: .food),
        Word(id: "food_031", original: "rice", translation: "рис", transcription: "/raɪs/", exampleSentence: "We eat rice almost every day.", exampleTranslation: "Ми їмо рис майже щодня.", synonyms: ["grain"], difficulty: .a1, category: .food),
        Word(id: "food_032", original: "salad", translation: "салат", transcription: "/ˈsæləd/", exampleSentence: "I will have a Caesar salad.", exampleTranslation: "Я візьму салат Цезар.", synonyms: ["healthy"], difficulty: .a1, category: .food),
        Word(id: "food_033", original: "salt", translation: "сіль", transcription: "/sɔːlt/", exampleSentence: "Too much salt is bad for you.", exampleTranslation: "Занадто багато солі шкідливо.", synonyms: ["seasoning"], difficulty: .a1, category: .food),
        Word(id: "food_034", original: "sandwich", translation: "бутерброд", transcription: "/ˈsænwɪtʃ/", exampleSentence: "I made a turkey sandwich.", exampleTranslation: "Я зробив бутерброд з індичкою.", synonyms: ["lunch"], difficulty: .a1, category: .food),
        Word(id: "food_035", original: "soup", translation: "суп", transcription: "/suːp/", exampleSentence: "Chicken soup is good when you are sick.", exampleTranslation: "Курячий суп корисний, коли ти хворий.", synonyms: ["warm"], difficulty: .a1, category: .food),
        Word(id: "food_036", original: "steak", translation: "стейк", transcription: "/steɪk/", exampleSentence: "He ordered a rare steak.", exampleTranslation: "Він замовив стейк з кровʼю.", synonyms: ["meat", "beef"], difficulty: .a1, category: .food),
        Word(id: "food_037", original: "strawberry", translation: "полуниця", transcription: "/ˈstrɔːberi/", exampleSentence: "Strawberries are sweet.", exampleTranslation: "Полуниця солодка.", synonyms: ["fruit", "berry"], difficulty: .a1, category: .food),
        Word(id: "food_038", original: "sugar", translation: "цукор", transcription: "/ˈʃʊɡər/", exampleSentence: "Do you take sugar in your coffee?", exampleTranslation: "Ти кладеш цукор у каву?", synonyms: ["sweetener"], difficulty: .a1, category: .food),
        Word(id: "food_039", original: "tea", translation: "чай", transcription: "/tiː/", exampleSentence: "Would you like some tea?", exampleTranslation: "Хочеш чаю?", synonyms: ["drink", "beverage"], difficulty: .a1, category: .food),
        Word(id: "food_040", original: "tomato", translation: "помідор", transcription: "/təˈmeɪtoʊ/", exampleSentence: "Add tomatoes to the salad.", exampleTranslation: "Додай помідори до салату.", synonyms: ["vegetable"], difficulty: .a1, category: .food),
        Word(id: "food_041", original: "vegetable", translation: "овоч", transcription: "/ˈvedʒtəbl/", exampleSentence: "Eat your vegetables!", exampleTranslation: "Їж свої овочі!", synonyms: ["healthy"], difficulty: .a1, category: .food),
        Word(id: "food_042", original: "water", translation: "вода", transcription: "/ˈwɔːtər/", exampleSentence: "Can I have some water, please?", exampleTranslation: "Можна мені води, будь ласка?", synonyms: ["drink"], difficulty: .a1, category: .food),
        Word(id: "food_043", original: "wine", translation: "вино", transcription: "/waɪn/", exampleSentence: "A glass of red wine, please.", exampleTranslation: "Чашка червоного вина, будь ласка.", synonyms: ["alcohol"], difficulty: .a1, category: .food),
        Word(id: "food_044", original: "yogurt", translation: "йогурт", transcription: "/ˈjoʊɡərt/", exampleSentence: "I eat yogurt for breakfast.", exampleTranslation: "Я їм йогурт на сніданок.", synonyms: ["dairy"], difficulty: .a1, category: .food),
    ]

    static let travelWords: [Word] = [
        Word(id: "travel_001", original: "airport", translation: "аеропорт", transcription: "/ˈerpɔːrt/", exampleSentence: "We arrived at the airport early.", exampleTranslation: "Ми приїхали в аеропорт рано.", synonyms: ["terminal"], difficulty: .a1, category: .travel),
        Word(id: "travel_002", original: "baggage", translation: "багаж", transcription: "/ˈbæɡɪdʒ/", exampleSentence: "Where is the baggage claim?", exampleTranslation: "Де отримання багажу?", synonyms: ["luggage"], difficulty: .a1, category: .travel),
        Word(id: "travel_003", original: "boarding pass", translation: "посадковий талон", transcription: "/ˈbɔːrdɪŋ pæs/", exampleSentence: "Show your boarding pass at the gate.", exampleTranslation: "Покажіть посадковий талон біля виходу.", synonyms: ["ticket"], difficulty: .a1, category: .travel),
        Word(id: "travel_004", original: "bus", translation: "автобус", transcription: "/bʌs/", exampleSentence: "Take bus number 10.", exampleTranslation: "Сідайте на автобус номер 10.", synonyms: ["transport"], difficulty: .a1, category: .travel),
        Word(id: "travel_005", original: "camera", translation: "камера", transcription: "/ˈkæmərə/", exampleSentence: "Do not forget your camera.", exampleTranslation: "Не забудь свою камеру.", synonyms: ["photo"], difficulty: .a1, category: .travel),
        Word(id: "travel_006", original: "check-in", translation: "реєстрація", transcription: "/ˈtʃek ɪn/", exampleSentence: "Check-in opens two hours before departure.", exampleTranslation: "Реєстрація відкривається за дві години до вильоту.", synonyms: ["airport"], difficulty: .a1, category: .travel),
        Word(id: "travel_007", original: "customs", translation: "митниця", transcription: "/ˈkʌstəmz/", exampleSentence: "We went through customs quickly.", exampleTranslation: "Ми швидко пройшли митницю.", synonyms: ["border"], difficulty: .a1, category: .travel),
        Word(id: "travel_008", original: "delay", translation: "затримка", transcription: "/dɪˈleɪ/", exampleSentence: "Our flight has a two-hour delay.", exampleTranslation: "Наш рейс має двогодинну затримку.", synonyms: ["late"], difficulty: .a1, category: .travel),
        Word(id: "travel_009", original: "departure", translation: "відправлення", transcription: "/dɪˈpɑːrtʃər/", exampleSentence: "The departure is at 3 PM.", exampleTranslation: "Відправлення о 15:00.", synonyms: ["leaving"], difficulty: .a1, category: .travel),
        Word(id: "travel_010", original: "destination", translation: "пункт призначення", transcription: "/ˌdestɪˈneɪʃn/", exampleSentence: "What is your final destination?", exampleTranslation: "Який ваш кінцевий пункт призначення?", synonyms: ["goal"], difficulty: .a1, category: .travel),
        Word(id: "travel_011", original: "flight", translation: "рейс", transcription: "/flaɪt/", exampleSentence: "Our flight was cancelled.", exampleTranslation: "Наш рейс скасували.", synonyms: ["air travel"], difficulty: .a1, category: .travel),
        Word(id: "travel_012", original: "gate", translation: "вихід", transcription: "/ɡeɪt/", exampleSentence: "Go to gate 12.", exampleTranslation: "Йдіть до виходу 12.", synonyms: ["terminal"], difficulty: .a1, category: .travel),
        Word(id: "travel_013", original: "guide", translation: "гід", transcription: "/ɡaɪd/", exampleSentence: "The tour guide was very knowledgeable.", exampleTranslation: "Екскурсовод був дуже обізнаним.", synonyms: ["tour"], difficulty: .a1, category: .travel),
        Word(id: "travel_014", original: "hotel", translation: "готель", transcription: "/hoʊˈtel/", exampleSentence: "We stayed at a nice hotel.", exampleTranslation: "Ми зупинилися в гарному готелі.", synonyms: ["accommodation"], difficulty: .a1, category: .travel),
        Word(id: "travel_015", original: "journey", translation: "подорож", transcription: "/ˈdʒɜːrni/", exampleSentence: "It was a long journey.", exampleTranslation: "Це була довга подорож.", synonyms: ["trip"], difficulty: .a1, category: .travel),
        Word(id: "travel_016", original: "luggage", translation: "багаж", transcription: "/ˈlʌɡɪdʒ/", exampleSentence: "Do not leave your luggage unattended.", exampleTranslation: "Не залишайте свій багаж без нагляду.", synonyms: ["bags"], difficulty: .a1, category: .travel),
        Word(id: "travel_017", original: "map", translation: "карта", transcription: "/mæp/", exampleSentence: "I need a map of the city.", exampleTranslation: "Мені потрібна карта міста.", synonyms: ["navigation"], difficulty: .a1, category: .travel),
        Word(id: "travel_018", original: "passenger", translation: "пасажир", transcription: "/ˈpæsɪndʒər/", exampleSentence: "All passengers must fasten seat belts.", exampleTranslation: "Усі пасажири повинні пристебнути ремені.", synonyms: ["traveler"], difficulty: .a1, category: .travel),
        Word(id: "travel_019", original: "passport", translation: "паспорт", transcription: "/ˈpæspɔːrt/", exampleSentence: "Do not forget your passport.", exampleTranslation: "Не забудь свій паспорт.", synonyms: ["ID"], difficulty: .a1, category: .travel),
        Word(id: "travel_020", original: "platform", translation: "платформа", transcription: "/ˈplætfɔːrm/", exampleSentence: "The train leaves from platform 3.", exampleTranslation: "Поїзд відправляється з платформи 3.", synonyms: ["station"], difficulty: .a1, category: .travel),
        Word(id: "travel_021", original: "reservation", translation: "бронювання", transcription: "/ˌrezərˈveɪʃn/", exampleSentence: "I have a reservation for two nights.", exampleTranslation: "У мене бронювання на дві ночі.", synonyms: ["booking"], difficulty: .a1, category: .travel),
        Word(id: "travel_022", original: "restaurant", translation: "ресторан", transcription: "/ˈrestərɑːnt/", exampleSentence: "Let us find a good restaurant.", exampleTranslation: "Давай знайдемо хороший ресторан.", synonyms: ["dining"], difficulty: .a1, category: .travel),
        Word(id: "travel_023", original: "souvenir", translation: "сувенір", transcription: "/ˌsuːvəˈnɪr/", exampleSentence: "I bought a souvenir for my mom.", exampleTranslation: "Я купив сувенір для мами.", synonyms: ["gift"], difficulty: .a1, category: .travel),
        Word(id: "travel_024", original: "station", translation: "станція", transcription: "/ˈsteɪʃn/", exampleSentence: "The bus station is downtown.", exampleTranslation: "Автобусна станція в центрі міста.", synonyms: ["stop"], difficulty: .a1, category: .travel),
        Word(id: "travel_025", original: "subway", translation: "метро", transcription: "/ˈsʌbweɪ/", exampleSentence: "Take the subway to get there faster.", exampleTranslation: "Їдьте метро, щоб швидше дістатися.", synonyms: ["metro", "underground"], difficulty: .a1, category: .travel),
        Word(id: "travel_026", original: "taxi", translation: "таксі", transcription: "/ˈtæksi/", exampleSentence: "Let us take a taxi.", exampleTranslation: "Давай візьмемо таксі.", synonyms: ["cab"], difficulty: .a1, category: .travel),
        Word(id: "travel_027", original: "ticket", translation: "квиток", transcription: "/ˈtɪkɪt/", exampleSentence: "I lost my train ticket.", exampleTranslation: "Я загубив свій квиток на поїзд.", synonyms: ["pass"], difficulty: .a1, category: .travel),
        Word(id: "travel_028", original: "tour", translation: "тур", transcription: "/tʊr/", exampleSentence: "We went on a city tour.", exampleTranslation: "Ми пішли на екскурсію по місту.", synonyms: ["trip"], difficulty: .a1, category: .travel),
        Word(id: "travel_029", original: "tourist", translation: "турист", transcription: "/ˈtʊrɪst/", exampleSentence: "The city is full of tourists.", exampleTranslation: "Місто повне туристів.", synonyms: ["visitor"], difficulty: .a1, category: .travel),
        Word(id: "travel_030", original: "train", translation: "поїзд", transcription: "/treɪn/", exampleSentence: "The train is arriving now.", exampleTranslation: "Поїзд зараз прибуває.", synonyms: ["railway"], difficulty: .a1, category: .travel),
        Word(id: "travel_031", original: "transfer", translation: "пересадка", transcription: "/ˈtrænsfɜːr/", exampleSentence: "You need to make a transfer at the next station.", exampleTranslation: "Вам потрібно зробити пересадку на наступній станції.", synonyms: ["connection"], difficulty: .a1, category: .travel),
        Word(id: "travel_032", original: "translate", translation: "перекладати", transcription: "/trænsˈleɪt/", exampleSentence: "Can you translate this for me?", exampleTranslation: "Можеш перекласти це для мене?", synonyms: ["interpret"], difficulty: .a1, category: .travel),
        Word(id: "travel_033", original: "transport", translation: "транспорт", transcription: "/ˈtrænspɔːrt/", exampleSentence: "Public transport is convenient.", exampleTranslation: "Громадський транспорт зручний.", synonyms: ["transit"], difficulty: .a1, category: .travel),
        Word(id: "travel_034", original: "trip", translation: "поїздка", transcription: "/trɪp/", exampleSentence: "We planned a weekend trip.", exampleTranslation: "Ми запланували поїздку на вихідні.", synonyms: ["journey"], difficulty: .a1, category: .travel),
        Word(id: "travel_035", original: "vacation", translation: "відпустка", transcription: "/veɪˈkeɪʃn/", exampleSentence: "I am on vacation next week.", exampleTranslation: "Я у відпустці наступного тижня.", synonyms: ["holiday"], difficulty: .a1, category: .travel),
        Word(id: "travel_036", original: "visa", translation: "віза", transcription: "/ˈviːzə/", exampleSentence: "Do I need a visa to visit?", exampleTranslation: "Чи потрібна мені віза для відвідування?", synonyms: ["permit"], difficulty: .a1, category: .travel),
        Word(id: "travel_037", original: "visit", translation: "відвідувати", transcription: "/ˈvɪzɪt/", exampleSentence: "I want to visit Paris.", exampleTranslation: "Я хочу відвідати Париж.", synonyms: ["see"], difficulty: .a1, category: .travel),
    ]

    static let workWords: [Word] = [
        Word(id: "work_001", original: "application", translation: "заявка", transcription: "/ˌæplɪˈkeɪʃn/", exampleSentence: "I submitted my job application.", exampleTranslation: "Я подав заявку на роботу.", synonyms: ["form"], difficulty: .a1, category: .work),
        Word(id: "work_002", original: "boss", translation: "начальник", transcription: "/bɔːs/", exampleSentence: "My boss is very demanding.", exampleTranslation: "Мій начальник дуже вимогливий.", synonyms: ["manager"], difficulty: .a1, category: .work),
        Word(id: "work_003", original: "career", translation: "карʼєра", transcription: "/kəˈrɪr/", exampleSentence: "She has a successful career.", exampleTranslation: "Вона має успішну карʼєру.", synonyms: ["profession"], difficulty: .a1, category: .work),
        Word(id: "work_004", original: "client", translation: "клієнт", transcription: "/ˈklaɪənt/", exampleSentence: "We have a new client today.", exampleTranslation: "У нас сьогодні новий клієнт.", synonyms: ["customer"], difficulty: .a1, category: .work),
        Word(id: "work_005", original: "colleague", translation: "колега", transcription: "/ˈkɑːliːɡ/", exampleSentence: "My colleague helped me with the project.", exampleTranslation: "Мій колега допоміг мені з проєктом.", synonyms: ["coworker"], difficulty: .a1, category: .work),
        Word(id: "work_006", original: "company", translation: "компанія", transcription: "/ˈkʌmpəni/", exampleSentence: "I work for a tech company.", exampleTranslation: "Я працюю в технологічній компанії.", synonyms: ["firm"], difficulty: .a1, category: .work),
        Word(id: "work_007", original: "contract", translation: "контракт", transcription: "/ˈkɑːntrækt/", exampleSentence: "I signed a new contract.", exampleTranslation: "Я підписав новий контракт.", synonyms: ["agreement"], difficulty: .a1, category: .work),
        Word(id: "work_008", original: "deadline", translation: "дедлайн", transcription: "/ˈdedlaɪn/", exampleSentence: "The deadline is tomorrow.", exampleTranslation: "Дедлайн завтра.", synonyms: ["due date"], difficulty: .a1, category: .work),
        Word(id: "work_009", original: "department", translation: "відділ", transcription: "/dɪˈpɑːrtmənt/", exampleSentence: "I work in the marketing department.", exampleTranslation: "Я працюю у відділі маркетингу.", synonyms: ["division"], difficulty: .a1, category: .work),
        Word(id: "work_010", original: "employee", translation: "співробітник", transcription: "/ɪmˈplɔɪiː/", exampleSentence: "The company has 100 employees.", exampleTranslation: "У компанії 100 співробітників.", synonyms: ["worker"], difficulty: .a1, category: .work),
        Word(id: "work_011", original: "employer", translation: "роботодавець", transcription: "/ɪmˈplɔɪər/", exampleSentence: "My employer offers good benefits.", exampleTranslation: "Мій роботодавець пропонує хороші пільги.", synonyms: ["boss"], difficulty: .a1, category: .work),
        Word(id: "work_012", original: "experience", translation: "досвід", transcription: "/ɪkˈspɪriəns/", exampleSentence: "I have five years of experience.", exampleTranslation: "У мене пʼять років досвіду.", synonyms: ["knowledge"], difficulty: .a1, category: .work),
        Word(id: "work_013", original: "fire", translation: "звільняти", transcription: "/ˈfaɪər/", exampleSentence: "He was fired for being late.", exampleTranslation: "Його звільнили за запізнення.", synonyms: ["dismiss"], difficulty: .a1, category: .work),
        Word(id: "work_014", original: "hire", translation: "наймати", transcription: "/ˈhaɪər/", exampleSentence: "We need to hire more people.", exampleTranslation: "Нам потрібно найняти більше людей.", synonyms: ["employ"], difficulty: .a1, category: .work),
        Word(id: "work_015", original: "interview", translation: "співбесіда", transcription: "/ˈɪntərvjuː/", exampleSentence: "I have a job interview tomorrow.", exampleTranslation: "У мене завтра співбесіда.", synonyms: ["meeting"], difficulty: .a1, category: .work),
        Word(id: "work_016", original: "job", translation: "робота", transcription: "/dʒɑːb/", exampleSentence: "I am looking for a new job.", exampleTranslation: "Я шукаю нову роботу.", synonyms: ["work"], difficulty: .a1, category: .work),
        Word(id: "work_017", original: "meeting", translation: "зустріч", transcription: "/ˈmiːtɪŋ/", exampleSentence: "We have a meeting at 10 AM.", exampleTranslation: "У нас зустріч о 10:00.", synonyms: ["conference"], difficulty: .a1, category: .work),
        Word(id: "work_018", original: "office", translation: "офіс", transcription: "/ˈɔːfɪs/", exampleSentence: "I work in a modern office.", exampleTranslation: "Я працюю в сучасному офісі.", synonyms: ["workplace"], difficulty: .a1, category: .work),
        Word(id: "work_019", original: "overtime", translation: "понаднормово", transcription: "/ˈoʊvərtaɪm/", exampleSentence: "I worked overtime last night.", exampleTranslation: "Я працював понаднормово вчора ввечері.", synonyms: ["extra hours"], difficulty: .a1, category: .work),
        Word(id: "work_020", original: "position", translation: "посада", transcription: "/pəˈzɪʃn/", exampleSentence: "What position are you applying for?", exampleTranslation: "На яку посаду ви подаєте заявку?", synonyms: ["role"], difficulty: .a1, category: .work),
        Word(id: "work_021", original: "project", translation: "проєкт", transcription: "/ˈprɑːdʒekt/", exampleSentence: "We are working on a new project.", exampleTranslation: "Ми працюємо над новим проєктом.", synonyms: ["task"], difficulty: .a1, category: .work),
        Word(id: "work_022", original: "promotion", translation: "просування", transcription: "/prəˈmoʊʃn/", exampleSentence: "I got a promotion last month.", exampleTranslation: "Мене підвищили минулого місяця.", synonyms: ["advancement"], difficulty: .a1, category: .work),
        Word(id: "work_023", original: "quit", translation: "звільнятися", transcription: "/kwɪt/", exampleSentence: "I decided to quit my job.", exampleTranslation: "Я вирішив звільнитися.", synonyms: ["resign"], difficulty: .a1, category: .work),
        Word(id: "work_024", original: "report", translation: "звіт", transcription: "/rɪˈpɔːrt/", exampleSentence: "I need to finish this report.", exampleTranslation: "Мені потрібно закінчити цей звіт.", synonyms: ["document"], difficulty: .a1, category: .work),
        Word(id: "work_025", original: "resign", translation: "подати у відставку", transcription: "/rɪˈzaɪn/", exampleSentence: "She resigned from her position.", exampleTranslation: "Вона подала у відставку зі своєї посади.", synonyms: ["quit"], difficulty: .a1, category: .work),
        Word(id: "work_026", original: "salary", translation: "зарплата", transcription: "/ˈsæləri/", exampleSentence: "My salary increased this year.", exampleTranslation: "Моя зарплата зросла цього року.", synonyms: ["pay"], difficulty: .a1, category: .work),
        Word(id: "work_027", original: "schedule", translation: "графік", transcription: "/ˈskedʒuːl/", exampleSentence: "Check my schedule for next week.", exampleTranslation: "Перевір мій графік на наступний тиждень.", synonyms: ["timetable"], difficulty: .a1, category: .work),
        Word(id: "work_028", original: "skill", translation: "навичка", transcription: "/skɪl/", exampleSentence: "Communication is an important skill.", exampleTranslation: "Комунікація — важлива навичка.", synonyms: ["ability"], difficulty: .a1, category: .work),
        Word(id: "work_029", original: "task", translation: "завдання", transcription: "/tæsk/", exampleSentence: "I have many tasks to complete.", exampleTranslation: "У мене багато завдань для виконання.", synonyms: ["job"], difficulty: .a1, category: .work),
        Word(id: "work_030", original: "team", translation: "команда", transcription: "/tiːm/", exampleSentence: "I work with a great team.", exampleTranslation: "Я працюю з чудовою командою.", synonyms: ["group"], difficulty: .a1, category: .work),
        Word(id: "work_031", original: "training", translation: "навчання", transcription: "/ˈtreɪnɪŋ/", exampleSentence: "We have training next week.", exampleTranslation: "У нас навчання наступного тижня.", synonyms: ["education"], difficulty: .a1, category: .work),
        Word(id: "work_032", original: "wage", translation: "заробітна плата", transcription: "/weɪdʒ/", exampleSentence: "The minimum wage has increased.", exampleTranslation: "Мінімальна заробітна плата зросла.", synonyms: ["pay"], difficulty: .a1, category: .work),
    ]

    static let emotionsWords: [Word] = [
        Word(id: "emotion_001", original: "afraid", translation: "наляканий", transcription: "/əˈfreɪd/", exampleSentence: "I am afraid of spiders.", exampleTranslation: "Я боюся павуків.", synonyms: ["scared"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_002", original: "angry", translation: "злий", transcription: "/ˈæŋɡri/", exampleSentence: "Do not be angry with me.", exampleTranslation: "Не сердься на мене.", synonyms: ["mad"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_003", original: "annoyed", translation: "роздратований", transcription: "/əˈnɔɪd/", exampleSentence: "I am annoyed by the noise.", exampleTranslation: "Я роздратований шумом.", synonyms: ["irritated"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_004", original: "anxious", translation: "тривожний", transcription: "/ˈæŋkʃəs/", exampleSentence: "I feel anxious about the exam.", exampleTranslation: "Я відчуваю тривогу через іспит.", synonyms: ["worried"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_005", original: "bored", translation: "нудьгуючий", transcription: "/bɔːrd/", exampleSentence: "I am bored at home.", exampleTranslation: "Мені нудно вдома.", synonyms: ["uninterested"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_006", original: "calm", translation: "спокійний", transcription: "/kɑːm/", exampleSentence: "Stay calm and breathe.", exampleTranslation: "Залишайся спокійним і дихай.", synonyms: ["relaxed"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_007", original: "confident", translation: "впевнений", transcription: "/ˈkɑːnfɪdənt/", exampleSentence: "I feel confident today.", exampleTranslation: "Я почуваюся впевнено сьогодні.", synonyms: ["sure"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_008", original: "confused", translation: "збентежений", transcription: "/kənˈfjuːzd/", exampleSentence: "I am confused about what to do.", exampleTranslation: "Я збентежений, що робити.", synonyms: ["puzzled"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_009", original: "curious", translation: "цікавий", transcription: "/ˈkjʊriəs/", exampleSentence: "I am curious about your story.", exampleTranslation: "Мені цікава твоя історія.", synonyms: ["interested"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_010", original: "disappointed", translation: "розчарований", transcription: "/ˌdɪsəˈpɔɪntɪd/", exampleSentence: "I am disappointed with the results.", exampleTranslation: "Я розчарований результатами.", synonyms: ["let down"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_011", original: "embarrassed", translation: "збентежений", transcription: "/ɪmˈbærəst/", exampleSentence: "I felt embarrassed.", exampleTranslation: "Я почувався збентежено.", synonyms: ["ashamed"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_012", original: "excited", translation: "схвильований", transcription: "/ɪkˈsaɪtɪd/", exampleSentence: "I am excited about the trip.", exampleTranslation: "Я схвильований поїздкою.", synonyms: ["thrilled"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_013", original: "frustrated", translation: "розчарований", transcription: "/ˈfrʌstreɪtɪd/", exampleSentence: "I am frustrated with this problem.", exampleTranslation: "Я розчарований цією проблемою.", synonyms: ["upset"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_014", original: "grateful", translation: "вдячний", transcription: "/ˈɡreɪtfl/", exampleSentence: "I am grateful for your help.", exampleTranslation: "Я вдячний за твою допомогу.", synonyms: ["thankful"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_015", original: "happy", translation: "щасливий", transcription: "/ˈhæpi/", exampleSentence: "I am so happy today!", exampleTranslation: "Я такий щасливий сьогодні!", synonyms: ["glad"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_016", original: "hopeful", translation: "сповнений надії", transcription: "/ˈhoʊpfl/", exampleSentence: "I am hopeful about the future.", exampleTranslation: "Я сповнений надії щодо майбутнього.", synonyms: ["optimistic"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_017", original: "jealous", translation: "ревнивий", transcription: "/ˈdʒeləs/", exampleSentence: "Do not be jealous of others.", exampleTranslation: "Не ревнуй до інших.", synonyms: ["envious"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_018", original: "lonely", translation: "самотній", transcription: "/ˈloʊnli/", exampleSentence: "I feel lonely sometimes.", exampleTranslation: "Іноді я почуваюся самотньо.", synonyms: ["alone"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_019", original: "love", translation: "любов", transcription: "/lʌv/", exampleSentence: "I feel love for my family.", exampleTranslation: "Я відчуваю любов до своєї сімʼї.", synonyms: ["affection"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_020", original: "nervous", translation: "нервовий", transcription: "/ˈnɜːrvəs/", exampleSentence: "I am nervous about the presentation.", exampleTranslation: "Я нервую через презентацію.", synonyms: ["anxious"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_021", original: "proud", translation: "гордий", transcription: "/praʊd/", exampleSentence: "I am proud of my achievements.", exampleTranslation: "Я пишаюся своїми досягненнями.", synonyms: ["pleased"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_022", original: "relaxed", translation: "розслаблений", transcription: "/rɪˈlækst/", exampleSentence: "I feel relaxed after yoga.", exampleTranslation: "Я почуваюся розслабленим після йоги.", synonyms: ["calm"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_023", original: "sad", translation: "сумний", transcription: "/sæd/", exampleSentence: "Why are you so sad?", exampleTranslation: "Чому ти такий сумний?", synonyms: ["unhappy"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_024", original: "scared", translation: "наляканий", transcription: "/skerd/", exampleSentence: "I am scared of the dark.", exampleTranslation: "Я боюся темряви.", synonyms: ["afraid"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_025", original: "shocked", translation: "шокований", transcription: "/ʃɑːkt/", exampleSentence: "I was shocked by the news.", exampleTranslation: "Я був шокований новинами.", synonyms: ["surprised"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_026", original: "stressed", translation: "напружений", transcription: "/strest/", exampleSentence: "I am stressed about work.", exampleTranslation: "Я напружений через роботу.", synonyms: ["tense"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_027", original: "surprised", translation: "здивований", transcription: "/sərˈpraɪzd/", exampleSentence: "I was surprised to see you.", exampleTranslation: "Я був здивований бачити тебе.", synonyms: ["amazed"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_028", original: "tired", translation: "втомлений", transcription: "/ˈtaɪərd/", exampleSentence: "I am so tired after work.", exampleTranslation: "Я так втомився після роботи.", synonyms: ["exhausted"], difficulty: .a1, category: .emotions),
        Word(id: "emotion_029", original: "worried", translation: "стурбований", transcription: "/ˈwʌrid/", exampleSentence: "I am worried about you.", exampleTranslation: "Я стурбований тобою.", synonyms: ["concerned"], difficulty: .a1, category: .emotions),
    ]

    static let familyWords: [Word] = [
        Word(id: "family_001", original: "aunt", translation: "тітка", transcription: "/ænt/", exampleSentence: "My aunt lives in Canada.", exampleTranslation: "Моя тітка живе в Канаді.", synonyms: ["relative"], difficulty: .a1, category: .family),
        Word(id: "family_002", original: "baby", translation: "немовля", transcription: "/ˈbeɪbi/", exampleSentence: "The baby is sleeping.", exampleTranslation: "Немовля спить.", synonyms: ["infant"], difficulty: .a1, category: .family),
        Word(id: "family_003", original: "brother", translation: "брат", transcription: "/ˈbrʌðər/", exampleSentence: "I have one brother.", exampleTranslation: "У мене один брат.", synonyms: ["sibling"], difficulty: .a1, category: .family),
        Word(id: "family_004", original: "child", translation: "дитина", transcription: "/tʃaɪld/", exampleSentence: "The child is playing.", exampleTranslation: "Дитина грається.", synonyms: ["kid"], difficulty: .a1, category: .family),
        Word(id: "family_005", original: "cousin", translation: "кузен/кузина", transcription: "/ˈkʌzn/", exampleSentence: "My cousin is coming to visit.", exampleTranslation: "Мій кузен приїжджає в гості.", synonyms: ["relative"], difficulty: .a1, category: .family),
        Word(id: "family_006", original: "dad", translation: "тато", transcription: "/dæd/", exampleSentence: "My dad is a teacher.", exampleTranslation: "Мій тато вчитель.", synonyms: ["father"], difficulty: .a1, category: .family),
        Word(id: "family_007", original: "daughter", translation: "донька", transcription: "/ˈdɔːtər/", exampleSentence: "My daughter is five years old.", exampleTranslation: "Моїй доньці пʼять років.", synonyms: ["girl"], difficulty: .a1, category: .family),
        Word(id: "family_008", original: "family", translation: "сімʼя", transcription: "/ˈfæməli/", exampleSentence: "I love my family.", exampleTranslation: "Я люблю свою сімʼю.", synonyms: ["relatives"], difficulty: .a1, category: .family),
        Word(id: "family_009", original: "father", translation: "батько", transcription: "/ˈfɑːðər/", exampleSentence: "His father works in a bank.", exampleTranslation: "Його батько працює в банку.", synonyms: ["dad"], difficulty: .a1, category: .family),
        Word(id: "family_010", original: "grandchild", translation: "онук/онука", transcription: "/ˈɡræntʃaɪld/", exampleSentence: "My grandchild is adorable.", exampleTranslation: "Мій онук чарівний.", synonyms: ["grandkid"], difficulty: .a1, category: .family),
        Word(id: "family_011", original: "granddaughter", translation: "онука", transcription: "/ˈɡrændɔːtər/", exampleSentence: "My granddaughter loves to dance.", exampleTranslation: "Моя онука любить танцювати.", synonyms: ["grandchild"], difficulty: .a1, category: .family),
        Word(id: "family_012", original: "grandfather", translation: "дідусь", transcription: "/ˈɡrænfɑːðər/", exampleSentence: "My grandfather tells great stories.", exampleTranslation: "Мій дідусь розповідає чудові історії.", synonyms: ["grandpa"], difficulty: .a1, category: .family),
        Word(id: "family_013", original: "grandmother", translation: "бабуся", transcription: "/ˈɡrænmʌðər/", exampleSentence: "My grandmother bakes delicious cookies.", exampleTranslation: "Моя бабуся пече смачне печиво.", synonyms: ["grandma"], difficulty: .a1, category: .family),
        Word(id: "family_014", original: "grandson", translation: "онук", transcription: "/ˈɡrænsʌn/", exampleSentence: "My grandson plays football.", exampleTranslation: "Мій онук грає у футбол.", synonyms: ["grandchild"], difficulty: .a1, category: .family),
        Word(id: "family_015", original: "husband", translation: "чоловік", transcription: "/ˈhʌzbənd/", exampleSentence: "My husband is very supportive.", exampleTranslation: "Мій чоловік дуже підтримує.", synonyms: ["spouse"], difficulty: .a1, category: .family),
        Word(id: "family_016", original: "mom", translation: "мама", transcription: "/mɑːm/", exampleSentence: "My mom is a doctor.", exampleTranslation: "Моя мама лікар.", synonyms: ["mother"], difficulty: .a1, category: .family),
        Word(id: "family_017", original: "mother", translation: "мати", transcription: "/ˈmʌðər/", exampleSentence: "Her mother is very kind.", exampleTranslation: "Її мати дуже добра.", synonyms: ["mom"], difficulty: .a1, category: .family),
        Word(id: "family_018", original: "nephew", translation: "племінник", transcription: "/ˈnefjuː/", exampleSentence: "My nephew is in college.", exampleTranslation: "Мій племінник у коледжі.", synonyms: ["relative"], difficulty: .a1, category: .family),
        Word(id: "family_019", original: "niece", translation: "племінниця", transcription: "/niːs/", exampleSentence: "My niece loves drawing.", exampleTranslation: "Моя племінниця любить малювати.", synonyms: ["relative"], difficulty: .a1, category: .family),
        Word(id: "family_020", original: "parent", translation: "батько", transcription: "/ˈperənt/", exampleSentence: "My parents are very proud.", exampleTranslation: "Мої батьки дуже пишаються.", synonyms: ["mother", "father"], difficulty: .a1, category: .family),
        Word(id: "family_021", original: "relative", translation: "родич", transcription: "/ˈrelətɪv/", exampleSentence: "I have many relatives.", exampleTranslation: "У мене багато родичів.", synonyms: ["family"], difficulty: .a1, category: .family),
        Word(id: "family_022", original: "sibling", translation: "рідний брат/сестра", transcription: "/ˈsɪblɪŋ/", exampleSentence: "I have three siblings.", exampleTranslation: "У мене троє рідних братів і сестер.", synonyms: ["brother", "sister"], difficulty: .a1, category: .family),
        Word(id: "family_023", original: "sister", translation: "сестра", transcription: "/ˈsɪstər/", exampleSentence: "My sister is younger than me.", exampleTranslation: "Моя сестра молодша за мене.", synonyms: ["sibling"], difficulty: .a1, category: .family),
        Word(id: "family_024", original: "son", translation: "син", transcription: "/sʌn/", exampleSentence: "My son is in high school.", exampleTranslation: "Мій син у старшій школі.", synonyms: ["boy"], difficulty: .a1, category: .family),
        Word(id: "family_025", original: "uncle", translation: "дядько", transcription: "/ˈʌŋkl/", exampleSentence: "My uncle lives nearby.", exampleTranslation: "Мій дядько живе поруч.", synonyms: ["relative"], difficulty: .a1, category: .family),
        Word(id: "family_026", original: "wife", translation: "дружина", transcription: "/waɪf/", exampleSentence: "My wife is an engineer.", exampleTranslation: "Моя дружина інженер.", synonyms: ["spouse"], difficulty: .a1, category: .family),
    ]

    static let shoppingWords: [Word] = [
        Word(id: "shopping_001", original: "basket", translation: "кошик", transcription: "/ˈbæskɪt/", exampleSentence: "Put the items in your basket.", exampleTranslation: "Поклади товари в свій кошик.", synonyms: ["cart"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_002", original: "bill", translation: "рахунок", transcription: "/bɪl/", exampleSentence: "Can I have the bill, please?", exampleTranslation: "Можна мені рахунок, будь ласка?", synonyms: ["invoice"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_003", original: "cash", translation: "готівка", transcription: "/kæʃ/", exampleSentence: "Do you have enough cash?", exampleTranslation: "У тебе достатньо готівки?", synonyms: ["money"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_004", original: "cashier", translation: "касир", transcription: "/kæˈʃɪr/", exampleSentence: "Pay at the cashier.", exampleTranslation: "Плати на касі.", synonyms: ["checkout"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_005", original: "change", translation: "решта", transcription: "/tʃeɪndʒ/", exampleSentence: "Keep the change.", exampleTranslation: "Залиште решту собі.", synonyms: ["coins"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_006", original: "cheap", translation: "дешевий", transcription: "/tʃiːp/", exampleSentence: "This shirt is very cheap.", exampleTranslation: "Ця сорочка дуже дешева.", synonyms: ["inexpensive"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_007", original: "checkout", translation: "каса", transcription: "/ˈtʃekaʊt/", exampleSentence: "Please proceed to checkout.", exampleTranslation: "Будь ласка, пройдіть до каси.", synonyms: ["cashier"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_008", original: "coupon", translation: "купон", transcription: "/ˈkuːpɑːn/", exampleSentence: "I have a coupon for 20% off.", exampleTranslation: "У мене купон на 20% знижки.", synonyms: ["voucher"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_009", original: "customer", translation: "клієнт", transcription: "/ˈkʌstəmər/", exampleSentence: "The customer is always right.", exampleTranslation: "Клієнт завжди правий.", synonyms: ["shopper"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_010", original: "discount", translation: "знижка", transcription: "/ˈdɪskaʊnt/", exampleSentence: "Is there a discount?", exampleTranslation: "Чи є знижка?", synonyms: ["sale"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_011", original: "expensive", translation: "дорогий", transcription: "/ɪkˈspensɪv/", exampleSentence: "This bag is too expensive.", exampleTranslation: "Ця сумка занадто дорога.", synonyms: ["costly"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_012", original: "fitting room", translation: "примірочна", transcription: "/ˈfɪtɪŋ ruːm/", exampleSentence: "Where is the fitting room?", exampleTranslation: "Де примірочна?", synonyms: ["changing room"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_013", original: "gift", translation: "подарунок", transcription: "/ɡɪft/", exampleSentence: "I bought a gift for my friend.", exampleTranslation: "Я купив подарунок для друга.", synonyms: ["present"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_014", original: "mall", translation: "торговий центр", transcription: "/mɔːl/", exampleSentence: "Let us go to the mall.", exampleTranslation: "Підемо в торговий центр.", synonyms: ["shopping center"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_015", original: "market", translation: "ринок", transcription: "/ˈmɑːrkɪt/", exampleSentence: "I bought fresh vegetables at the market.", exampleTranslation: "Я купив свіжі овочі на ринку.", synonyms: ["bazaar"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_016", original: "price", translation: "ціна", transcription: "/praɪs/", exampleSentence: "What is the price of this?", exampleTranslation: "Яка ціна цього?", synonyms: ["cost"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_017", original: "product", translation: "товар", transcription: "/ˈprɑːdʌkt/", exampleSentence: "This product is on sale.", exampleTranslation: "Цей товар у розпродажі.", synonyms: ["item"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_018", original: "receipt", translation: "чек", transcription: "/rɪˈsiːt/", exampleSentence: "Can I get a receipt?", exampleTranslation: "Можна мені чек?", synonyms: ["bill"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_019", original: "refund", translation: "повернення грошей", transcription: "/ˈriːfʌnd/", exampleSentence: "I would like a refund.", exampleTranslation: "Я хотів би повернення грошей.", synonyms: ["return"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_020", original: "sale", translation: "розпродаж", transcription: "/seɪl/", exampleSentence: "There is a big sale this weekend.", exampleTranslation: "Цими вихідними великий розпродаж.", synonyms: ["discount"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_021", original: "shop", translation: "магазин", transcription: "/ʃɑːp/", exampleSentence: "I need to go to the shop.", exampleTranslation: "Мені потрібно піти в магазин.", synonyms: ["store"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_022", original: "shopper", translation: "покупець", transcription: "/ˈʃɑːpər/", exampleSentence: "The mall was full of shoppers.", exampleTranslation: "Торговий центр був повний покупців.", synonyms: ["customer"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_023", original: "shopping", translation: "шопінг", transcription: "/ˈʃɑːpɪŋ/", exampleSentence: "I love shopping for clothes.", exampleTranslation: "Я люблю шопінг одягу.", synonyms: ["buying"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_024", original: "size", translation: "розмір", transcription: "/saɪz/", exampleSentence: "What size do you wear?", exampleTranslation: "Який розмір ти носиш?", synonyms: ["measurement"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_025", original: "store", translation: "магазин", transcription: "/stɔːr/", exampleSentence: "This store has great deals.", exampleTranslation: "Цей магазин має чудові пропозиції.", synonyms: ["shop"], difficulty: .a1, category: .shopping),
        Word(id: "shopping_026", original: "wallet", translation: "гаманець", transcription: "/ˈwɑːlɪt/", exampleSentence: "I forgot my wallet at home.", exampleTranslation: "Я забув свій гаманець вдома.", synonyms: ["purse"], difficulty: .a1, category: .shopping),
    ]

    static let healthWords: [Word] = [
        Word(id: "health_001", original: "appointment", translation: "прийом", transcription: "/əˈpɔɪntmənt/", exampleSentence: "I have a doctor appointment.", exampleTranslation: "У мене прийом у лікаря.", synonyms: ["meeting"], difficulty: .a1, category: .health),
        Word(id: "health_002", original: "blood", translation: "кров", transcription: "/blʌd/", exampleSentence: "The doctor took a blood sample.", exampleTranslation: "Лікар взяв зразок крові.", synonyms: ["fluid"], difficulty: .a1, category: .health),
        Word(id: "health_003", original: "cough", translation: "кашель", transcription: "/kɔːf/", exampleSentence: "I have a bad cough.", exampleTranslation: "У мене сильний кашель.", synonyms: ["hack"], difficulty: .a1, category: .health),
        Word(id: "health_004", original: "dentist", translation: "стоматолог", transcription: "/ˈdentɪst/", exampleSentence: "I need to see a dentist.", exampleTranslation: "Мені потрібно до стоматолога.", synonyms: ["doctor"], difficulty: .a1, category: .health),
        Word(id: "health_005", original: "doctor", translation: "лікар", transcription: "/ˈdɑːktər/", exampleSentence: "The doctor prescribed medicine.", exampleTranslation: "Лікар виписав ліки.", synonyms: ["physician"], difficulty: .a1, category: .health),
        Word(id: "health_006", original: "emergency", translation: "надзвичайна ситуація", transcription: "/ɪˈmɜːrdʒənsi/", exampleSentence: "Call emergency services.", exampleTranslation: "Викличте швидку допомогу.", synonyms: ["urgency"], difficulty: .a1, category: .health),
        Word(id: "health_007", original: "exercise", translation: "вправа", transcription: "/ˈeksərsaɪz/", exampleSentence: "Exercise is good for your health.", exampleTranslation: "Вправи корисні для здоровʼя.", synonyms: ["workout"], difficulty: .a1, category: .health),
        Word(id: "health_008", original: "fever", translation: "лихоманка", transcription: "/ˈfiːvər/", exampleSentence: "I have a high fever.", exampleTranslation: "У мене висока температура.", synonyms: ["temperature"], difficulty: .a1, category: .health),
        Word(id: "health_009", original: "flu", translation: "грип", transcription: "/fluː/", exampleSentence: "I caught the flu.", exampleTranslation: "Я підхопив грип.", synonyms: ["influenza"], difficulty: .a1, category: .health),
        Word(id: "health_010", original: "headache", translation: "головний біль", transcription: "/ˈhedeɪk/", exampleSentence: "I have a terrible headache.", exampleTranslation: "У мене жахливий головний біль.", synonyms: ["pain"], difficulty: .a1, category: .health),
        Word(id: "health_011", original: "health", translation: "здоровʼя", transcription: "/helθ/", exampleSentence: "Your health is important.", exampleTranslation: "Ваше здоровʼя важливе.", synonyms: ["wellness"], difficulty: .a1, category: .health),
        Word(id: "health_012", original: "heart", translation: "серце", transcription: "/hɑːrt/", exampleSentence: "My heart is beating fast.", exampleTranslation: "Моє серце бʼється швидко.", synonyms: ["organ"], difficulty: .a1, category: .health),
        Word(id: "health_013", original: "hospital", translation: "лікарня", transcription: "/ˈhɑːspɪtl/", exampleSentence: "She was taken to the hospital.", exampleTranslation: "Її забрали до лікарні.", synonyms: ["clinic"], difficulty: .a1, category: .health),
        Word(id: "health_014", original: "ill", translation: "хворий", transcription: "/ɪl/", exampleSentence: "I feel ill today.", exampleTranslation: "Я почуваюся хворим сьогодні.", synonyms: ["sick"], difficulty: .a1, category: .health),
        Word(id: "health_015", original: "injury", translation: "травма", transcription: "/ˈɪndʒəri/", exampleSentence: "He suffered a leg injury.", exampleTranslation: "Він отримав травму ноги.", synonyms: ["wound"], difficulty: .a1, category: .health),
        Word(id: "health_016", original: "medicine", translation: "лікарство", transcription: "/ˈmedɪsn/", exampleSentence: "Take your medicine three times a day.", exampleTranslation: "Приймайте ліки тричі на день.", synonyms: ["medication"], difficulty: .a1, category: .health),
        Word(id: "health_017", original: "nurse", translation: "медсестра", transcription: "/nɜːrs/", exampleSentence: "The nurse was very kind.", exampleTranslation: "Медсестра була дуже доброю.", synonyms: ["caregiver"], difficulty: .a1, category: .health),
        Word(id: "health_018", original: "pain", translation: "біль", transcription: "/peɪn/", exampleSentence: "I am in a lot of pain.", exampleTranslation: "У мене сильний біль.", synonyms: ["ache"], difficulty: .a1, category: .health),
        Word(id: "health_019", original: "patient", translation: "пацієнт", transcription: "/ˈpeɪʃnt/", exampleSentence: "The patient is recovering well.", exampleTranslation: "Пацієнт добре одужує.", synonyms: ["sick person"], difficulty: .a1, category: .health),
        Word(id: "health_020", original: "pharmacy", translation: "аптека", transcription: "/ˈfɑːrməsi/", exampleSentence: "I need to go to the pharmacy.", exampleTranslation: "Мені потрібно піти в аптеку.", synonyms: ["drugstore"], difficulty: .a1, category: .health),
        Word(id: "health_021", original: "pill", translation: "пігулка", transcription: "/pɪl/", exampleSentence: "Take this pill with water.", exampleTranslation: "Візьміть цю пігулку з водою.", synonyms: ["tablet"], difficulty: .a1, category: .health),
        Word(id: "health_022", original: "prescription", translation: "рецепт", transcription: "/prɪˈskrɪpʃn/", exampleSentence: "I need to fill my prescription.", exampleTranslation: "Мені потрібно отримати ліки за рецептом.", synonyms: ["script"], difficulty: .a1, category: .health),
        Word(id: "health_023", original: "sick", translation: "хворий", transcription: "/sɪk/", exampleSentence: "I am staying home because I am sick.", exampleTranslation: "Я залишаюся вдома, бо я хворий.", synonyms: ["ill"], difficulty: .a1, category: .health),
        Word(id: "health_024", original: "sleep", translation: "сон", transcription: "/sliːp/", exampleSentence: "I need more sleep.", exampleTranslation: "Мені потрібно більше спати.", synonyms: ["rest"], difficulty: .a1, category: .health),
        Word(id: "health_025", original: "stomach", translation: "шлунок", transcription: "/ˈstʌmək/", exampleSentence: "I have a stomach ache.", exampleTranslation: "У мене болить шлунок.", synonyms: ["belly"], difficulty: .a1, category: .health),
        Word(id: "health_026", original: "stress", translation: "стрес", transcription: "/stres/", exampleSentence: "Stress can affect your health.", exampleTranslation: "Стрес може впливати на ваше здоровʼя.", synonyms: ["tension"], difficulty: .a1, category: .health),
        Word(id: "health_027", original: "symptom", translation: "симптом", transcription: "/ˈsɪmptəm/", exampleSentence: "What are your symptoms?", exampleTranslation: "Які у вас симптоми?", synonyms: ["sign"], difficulty: .a1, category: .health),
        Word(id: "health_028", original: "treatment", translation: "лікування", transcription: "/ˈtriːtmənt/", exampleSentence: "The treatment was successful.", exampleTranslation: "Лікування було успішним.", synonyms: ["therapy"], difficulty: .a1, category: .health),
        Word(id: "health_029", original: "vitamin", translation: "вітамін", transcription: "/ˈvaɪtəmɪn/", exampleSentence: "I take vitamins every day.", exampleTranslation: "Я приймаю вітаміни щодня.", synonyms: ["supplement"], difficulty: .a1, category: .health),
        Word(id: "health_030", original: "wellness", translation: "благополуччя", transcription: "/ˈwelnəs/", exampleSentence: "Wellness is about balance.", exampleTranslation: "Благополуччя — це про баланс.", synonyms: ["health"], difficulty: .a1, category: .health),
        Word(id: "health_031", original: "yoga", translation: "йога", transcription: "/ˈjoʊɡə/", exampleSentence: "Yoga helps me relax.", exampleTranslation: "Йога допомагає мені розслабитися.", synonyms: ["exercise"], difficulty: .a1, category: .health),
    ]

    static let technologyWords: [Word] = [
        Word(id: "tech_001", original: "app", translation: "додаток", transcription: "/æp/", exampleSentence: "Download this app.", exampleTranslation: "Завантаж цей додаток.", synonyms: ["application"], difficulty: .a1, category: .technology),
        Word(id: "tech_002", original: "battery", translation: "батарея", transcription: "/ˈbætəri/", exampleSentence: "My phone battery is low.", exampleTranslation: "Батарея мого телефону сідає.", synonyms: ["power"], difficulty: .a1, category: .technology),
        Word(id: "tech_003", original: "blog", translation: "блог", transcription: "/blɔːɡ/", exampleSentence: "I write a travel blog.", exampleTranslation: "Я веду туристичний блог.", synonyms: ["website"], difficulty: .a1, category: .technology),
        Word(id: "tech_004", original: "browser", translation: "браузер", transcription: "/ˈbraʊzər/", exampleSentence: "Open your web browser.", exampleTranslation: "Відкрий свій веб-браузер.", synonyms: ["explorer"], difficulty: .a1, category: .technology),
        Word(id: "tech_005", original: "button", translation: "кнопка", transcription: "/ˈbʌtn/", exampleSentence: "Press the red button.", exampleTranslation: "Натисни червону кнопку.", synonyms: ["switch"], difficulty: .a1, category: .technology),
        Word(id: "tech_006", original: "camera", translation: "камера", transcription: "/ˈkæmərə/", exampleSentence: "The camera on this phone is great.", exampleTranslation: "Камера на цьому телефоні чудова.", synonyms: ["lens"], difficulty: .a1, category: .technology),
        Word(id: "tech_007", original: "charger", translation: "зарядний пристрій", transcription: "/ˈtʃɑːrdʒər/", exampleSentence: "I forgot my phone charger.", exampleTranslation: "Я забув свій зарядний пристрій для телефону.", synonyms: ["adapter"], difficulty: .a1, category: .technology),
        Word(id: "tech_008", original: "click", translation: "клік", transcription: "/klɪk/", exampleSentence: "Click on the link.", exampleTranslation: "Клікни на посилання.", synonyms: ["press"], difficulty: .a1, category: .technology),
        Word(id: "tech_009", original: "computer", translation: "компʼютер", transcription: "/kəmˈpjuːtər/", exampleSentence: "I work on a computer all day.", exampleTranslation: "Я працюю за компʼютером цілий день.", synonyms: ["PC"], difficulty: .a1, category: .technology),
        Word(id: "tech_010", original: "data", translation: "дані", transcription: "/ˈdeɪtə/", exampleSentence: "Store your data in the cloud.", exampleTranslation: "Зберігай свої дані в хмарі.", synonyms: ["information"], difficulty: .a1, category: .technology),
        Word(id: "tech_011", original: "device", translation: "пристрій", transcription: "/dɪˈvaɪs/", exampleSentence: "This device is not compatible.", exampleTranslation: "Цей пристрій несумісний.", synonyms: ["gadget"], difficulty: .a1, category: .technology),
        Word(id: "tech_012", original: "download", translation: "завантажувати", transcription: "/ˌdaʊnˈloʊd/", exampleSentence: "Download the file here.", exampleTranslation: "Завантаж файл тут.", synonyms: ["save"], difficulty: .a1, category: .technology),
        Word(id: "tech_013", original: "email", translation: "електронна пошта", transcription: "/ˈiːmeɪl/", exampleSentence: "Send me an email.", exampleTranslation: "Надішли мені листа.", synonyms: ["mail"], difficulty: .a1, category: .technology),
        Word(id: "tech_014", original: "file", translation: "файл", transcription: "/faɪl/", exampleSentence: "Save the file to your desktop.", exampleTranslation: "Збережи файл на робочий стіл.", synonyms: ["document"], difficulty: .a1, category: .technology),
        Word(id: "tech_015", original: "gadget", translation: "гаджет", transcription: "/ˈɡædʒɪt/", exampleSentence: "I love buying new gadgets.", exampleTranslation: "Я люблю купувати нові гаджети.", synonyms: ["device"], difficulty: .a1, category: .technology),
        Word(id: "tech_016", original: "headphones", translation: "навушники", transcription: "/ˈhedfoʊnz/", exampleSentence: "I need new headphones.", exampleTranslation: "Мені потрібні нові навушники.", synonyms: ["earphones"], difficulty: .a1, category: .technology),
        Word(id: "tech_017", original: "internet", translation: "інтернет", transcription: "/ˈɪntərnet/", exampleSentence: "The internet is down.", exampleTranslation: "Інтернет не працює.", synonyms: ["web"], difficulty: .a1, category: .technology),
        Word(id: "tech_018", original: "keyboard", translation: "клавіатура", transcription: "/ˈkiːbɔːrd/", exampleSentence: "My keyboard is broken.", exampleTranslation: "Моя клавіатура зламалася.", synonyms: ["keypad"], difficulty: .a1, category: .technology),
        Word(id: "tech_019", original: "laptop", translation: "ноутбук", transcription: "/ˈlæptɑːp/", exampleSentence: "I prefer working on a laptop.", exampleTranslation: "Я віддаю перевагу роботі на ноутбуці.", synonyms: ["notebook"], difficulty: .a1, category: .technology),
        Word(id: "tech_020", original: "link", translation: "посилання", transcription: "/lɪŋk/", exampleSentence: "Click on this link.", exampleTranslation: "Клікни на це посилання.", synonyms: ["URL"], difficulty: .a1, category: .technology),
        Word(id: "tech_021", original: "login", translation: "вхід", transcription: "/ˈlɔːɡɪn/", exampleSentence: "Enter your login details.", exampleTranslation: "Введіть свої дані для входу.", synonyms: ["sign in"], difficulty: .a1, category: .technology),
        Word(id: "tech_022", original: "mouse", translation: "миша", transcription: "/maʊs/", exampleSentence: "My mouse is not working.", exampleTranslation: "Моя миша не працює.", synonyms: ["pointer"], difficulty: .a1, category: .technology),
        Word(id: "tech_023", original: "password", translation: "пароль", transcription: "/ˈpæswɜːrd/", exampleSentence: "Do not forget your password.", exampleTranslation: "Не забудь свій пароль.", synonyms: ["code"], difficulty: .a1, category: .technology),
        Word(id: "tech_024", original: "screen", translation: "екран", transcription: "/skriːn/", exampleSentence: "The screen is cracked.", exampleTranslation: "Екран тріснув.", synonyms: ["display"], difficulty: .a1, category: .technology),
        Word(id: "tech_025", original: "search", translation: "пошук", transcription: "/sɜːrtʃ/", exampleSentence: "Use the search function.", exampleTranslation: "Використовуй функцію пошуку.", synonyms: ["find"], difficulty: .a1, category: .technology),
        Word(id: "tech_026", original: "smartphone", translation: "смартфон", transcription: "/ˈsmɑːrtfoʊn/", exampleSentence: "Everyone has a smartphone now.", exampleTranslation: "Зараз у всіх є смартфон.", synonyms: ["mobile"], difficulty: .a1, category: .technology),
        Word(id: "tech_027", original: "software", translation: "програмне забезпечення", transcription: "/ˈsɔːftwer/", exampleSentence: "Update your software.", exampleTranslation: "Онови своє програмне забезпечення.", synonyms: ["program"], difficulty: .a1, category: .technology),
        Word(id: "tech_028", original: "tablet", translation: "планшет", transcription: "/ˈtæblət/", exampleSentence: "I read books on my tablet.", exampleTranslation: "Я читаю книги на планшеті.", synonyms: ["iPad"], difficulty: .a1, category: .technology),
        Word(id: "tech_029", original: "update", translation: "оновлення", transcription: "/ˈʌpdeɪt/", exampleSentence: "Install the latest update.", exampleTranslation: "Встанови останнє оновлення.", synonyms: ["upgrade"], difficulty: .a1, category: .technology),
        Word(id: "tech_030", original: "upload", translation: "завантажувати", transcription: "/ˈʌploʊd/", exampleSentence: "Upload your photos to the cloud.", exampleTranslation: "Завантаж свої фото в хмару.", synonyms: ["post"], difficulty: .a1, category: .technology),
        Word(id: "tech_031", original: "user", translation: "користувач", transcription: "/ˈjuːzər/", exampleSentence: "Create a new user account.", exampleTranslation: "Створи новий обліковий запис користувача.", synonyms: ["account"], difficulty: .a1, category: .technology),
        Word(id: "tech_032", original: "video", translation: "відео", transcription: "/ˈvɪdioʊ/", exampleSentence: "Watch this video.", exampleTranslation: "Подивися це відео.", synonyms: ["clip"], difficulty: .a1, category: .technology),
        Word(id: "tech_033", original: "website", translation: "веб-сайт", transcription: "/ˈwebsaɪt/", exampleSentence: "Visit our website.", exampleTranslation: "Відвідай наш веб-сайт.", synonyms: ["site"], difficulty: .a1, category: .technology),
        Word(id: "tech_034", original: "Wi-Fi", translation: "Wi-Fi", transcription: "/ˈwaɪfaɪ/", exampleSentence: "What is the Wi-Fi password?", exampleTranslation: "Який пароль від Wi-Fi?", synonyms: ["wireless"], difficulty: .a1, category: .technology),
    ]

    static let natureWords: [Word] = [
        Word(id: "nature_001", original: "animal", translation: "тварина", transcription: "/ˈænɪml/", exampleSentence: "I love animals.", exampleTranslation: "Я люблю тварин.", synonyms: ["creature"], difficulty: .a1, category: .nature),
        Word(id: "nature_002", original: "beach", translation: "пляж", transcription: "/biːtʃ/", exampleSentence: "Let us go to the beach.", exampleTranslation: "Підемо на пляж.", synonyms: ["shore"], difficulty: .a1, category: .nature),
        Word(id: "nature_003", original: "bird", translation: "птах", transcription: "/bɜːrd/", exampleSentence: "The bird is singing.", exampleTranslation: "Птах співає.", synonyms: ["fowl"], difficulty: .a1, category: .nature),
        Word(id: "nature_004", original: "butterfly", translation: "метелик", transcription: "/ˈbʌtərflaɪ/", exampleSentence: "A butterfly landed on the flower.", exampleTranslation: "Метелик сів на квітку.", synonyms: ["insect"], difficulty: .a1, category: .nature),
        Word(id: "nature_005", original: "cloud", translation: "хмара", transcription: "/klaʊd/", exampleSentence: "The clouds look like cotton.", exampleTranslation: "Хмари схожі на бавовну.", synonyms: ["fluff"], difficulty: .a1, category: .nature),
        Word(id: "nature_006", original: "desert", translation: "пустеля", transcription: "/ˈdezərt/", exampleSentence: "The Sahara is a large desert.", exampleTranslation: "Сахара — велика пустеля.", synonyms: ["wasteland"], difficulty: .a1, category: .nature),
        Word(id: "nature_007", original: "flower", translation: "квітка", transcription: "/ˈflaʊər/", exampleSentence: "She picked a beautiful flower.", exampleTranslation: "Вона зірвала гарну квітку.", synonyms: ["bloom"], difficulty: .a1, category: .nature),
        Word(id: "nature_008", original: "forest", translation: "ліс", transcription: "/ˈfɔːrɪst/", exampleSentence: "We walked through the forest.", exampleTranslation: "Ми пройшли крізь ліс.", synonyms: ["woods"], difficulty: .a1, category: .nature),
        Word(id: "nature_009", original: "grass", translation: "трава", transcription: "/ɡræs/", exampleSentence: "The grass is green.", exampleTranslation: "Трава зелена.", synonyms: ["lawn"], difficulty: .a1, category: .nature),
        Word(id: "nature_010", original: "hill", translation: "пагорб", transcription: "/hɪl/", exampleSentence: "We climbed to the top of the hill.", exampleTranslation: "Ми піднялися на вершину пагорба.", synonyms: ["mound"], difficulty: .a1, category: .nature),
        Word(id: "nature_011", original: "insect", translation: "комаха", transcription: "/ˈɪnsekt/", exampleSentence: "Insects are important for nature.", exampleTranslation: "Комахи важливі для природи.", synonyms: ["bug"], difficulty: .a1, category: .nature),
        Word(id: "nature_012", original: "lake", translation: "озеро", transcription: "/leɪk/", exampleSentence: "The lake is very peaceful.", exampleTranslation: "Озеро дуже спокійне.", synonyms: ["pond"], difficulty: .a1, category: .nature),
        Word(id: "nature_013", original: "leaf", translation: "листя", transcription: "/liːf/", exampleSentence: "The leaves are falling.", exampleTranslation: "Листя падає.", synonyms: ["foliage"], difficulty: .a1, category: .nature),
        Word(id: "nature_014", original: "mountain", translation: "гора", transcription: "/ˈmaʊntən/", exampleSentence: "We hiked up the mountain.", exampleTranslation: "Ми пішли в похід у гори.", synonyms: ["peak"], difficulty: .a1, category: .nature),
        Word(id: "nature_015", original: "ocean", translation: "океан", transcription: "/ˈoʊʃn/", exampleSentence: "The ocean is vast.", exampleTranslation: "Океан безмежний.", synonyms: ["sea"], difficulty: .a1, category: .nature),
        Word(id: "nature_016", original: "plant", translation: "рослина", transcription: "/plænt/", exampleSentence: "Water the plants, please.", exampleTranslation: "Полий рослини, будь ласка.", synonyms: ["flora"], difficulty: .a1, category: .nature),
        Word(id: "nature_017", original: "rain", translation: "дощ", transcription: "/reɪn/", exampleSentence: "It is going to rain today.", exampleTranslation: "Сьогодні буде дощ.", synonyms: ["precipitation"], difficulty: .a1, category: .nature),
        Word(id: "nature_018", original: "rainbow", translation: "веселка", transcription: "/ˈreɪnboʊ/", exampleSentence: "Look at that beautiful rainbow!", exampleTranslation: "Подивися на ту гарну веселку!", synonyms: ["arc"], difficulty: .a1, category: .nature),
        Word(id: "nature_019", original: "river", translation: "річка", transcription: "/ˈrɪvər/", exampleSentence: "The river flows to the sea.", exampleTranslation: "Річка тече до моря.", synonyms: ["stream"], difficulty: .a1, category: .nature),
        Word(id: "nature_020", original: "rock", translation: "камінь", transcription: "/rɑːk/", exampleSentence: "He sat on a big rock.", exampleTranslation: "Він сів на великий камінь.", synonyms: ["stone"], difficulty: .a1, category: .nature),
        Word(id: "nature_021", original: "sand", translation: "пісок", transcription: "/sænd/", exampleSentence: "The sand was hot.", exampleTranslation: "Пісок був гарячим.", synonyms: ["grit"], difficulty: .a1, category: .nature),
        Word(id: "nature_022", original: "sea", translation: "море", transcription: "/siː/", exampleSentence: "I love swimming in the sea.", exampleTranslation: "Я люблю плавати в морі.", synonyms: ["ocean"], difficulty: .a1, category: .nature),
        Word(id: "nature_023", original: "sky", translation: "небо", transcription: "/skaɪ/", exampleSentence: "The sky is blue today.", exampleTranslation: "Небо сьогодні блакитне.", synonyms: ["heavens"], difficulty: .a1, category: .nature),
        Word(id: "nature_024", original: "snow", translation: "сніг", transcription: "/snoʊ/", exampleSentence: "It snowed last night.", exampleTranslation: "Вночі йшов сніг.", synonyms: ["flurries"], difficulty: .a1, category: .nature),
        Word(id: "nature_025", original: "star", translation: "зірка", transcription: "/stɑːr/", exampleSentence: "Look at the stars tonight.", exampleTranslation: "Подивися на зірки сьогодні ввечері.", synonyms: ["celestial"], difficulty: .a1, category: .nature),
        Word(id: "nature_026", original: "storm", translation: "шторм", transcription: "/stɔːrm/", exampleSentence: "A storm is coming.", exampleTranslation: "Наближається шторм.", synonyms: ["tempest"], difficulty: .a1, category: .nature),
        Word(id: "nature_027", original: "sun", translation: "сонце", transcription: "/sʌn/", exampleSentence: "The sun is shining.", exampleTranslation: "Сонце світить.", synonyms: ["star"], difficulty: .a1, category: .nature),
        Word(id: "nature_028", original: "sunset", translation: "захід сонця", transcription: "/ˈsʌnset/", exampleSentence: "The sunset was beautiful.", exampleTranslation: "Захід сонця був прекрасним.", synonyms: ["dusk"], difficulty: .a1, category: .nature),
        Word(id: "nature_029", original: "tree", translation: "дерево", transcription: "/triː/", exampleSentence: "The tree is very tall.", exampleTranslation: "Дерево дуже високе.", synonyms: ["plant"], difficulty: .a1, category: .nature),
        Word(id: "nature_030", original: "waterfall", translation: "водоспад", transcription: "/ˈwɔːtərfɔːl/", exampleSentence: "The waterfall was amazing.", exampleTranslation: "Водоспад був неймовірним.", synonyms: ["cascade"], difficulty: .a1, category: .nature),
        Word(id: "nature_031", original: "weather", translation: "погода", transcription: "/ˈweðər/", exampleSentence: "How is the weather today?", exampleTranslation: "Яка сьогодні погода?", synonyms: ["climate"], difficulty: .a1, category: .nature),
        Word(id: "nature_032", original: "wind", translation: "вітер", transcription: "/wɪnd/", exampleSentence: "The wind is strong today.", exampleTranslation: "Вітер сьогодні сильний.", synonyms: ["breeze"], difficulty: .a1, category: .nature),
    ]

    static let educationWords: [Word] = [
        Word(id: "edu_001", original: "assignment", translation: "завдання", transcription: "/əˈsaɪnmənt/", exampleSentence: "I have an assignment due tomorrow.", exampleTranslation: "У мене завдання на завтра.", synonyms: ["task"], difficulty: .a1, category: .education),
        Word(id: "edu_002", original: "class", translation: "клас", transcription: "/klæs/", exampleSentence: "My math class starts at 9.", exampleTranslation: "Мій урок математики починається о 9.", synonyms: ["lesson"], difficulty: .a1, category: .education),
        Word(id: "edu_003", original: "classroom", translation: "класна кімната", transcription: "/ˈklæsruːm/", exampleSentence: "The classroom is full of students.", exampleTranslation: "Класна кімната повна учнів.", synonyms: ["room"], difficulty: .a1, category: .education),
        Word(id: "edu_004", original: "college", translation: "коледж", transcription: "/ˈkɑːlɪdʒ/", exampleSentence: "I am going to college next year.", exampleTranslation: "Я йду до коледжу наступного року.", synonyms: ["university"], difficulty: .a1, category: .education),
        Word(id: "edu_005", original: "course", translation: "курс", transcription: "/kɔːrs/", exampleSentence: "I am taking a Spanish course.", exampleTranslation: "Я проходжу курс іспанської.", synonyms: ["class"], difficulty: .a1, category: .education),
        Word(id: "edu_006", original: "degree", translation: "ступінь", transcription: "/dɪˈɡriː/", exampleSentence: "She has a degree in engineering.", exampleTranslation: "Вона має ступінь в інженерії.", synonyms: ["diploma"], difficulty: .a1, category: .education),
        Word(id: "edu_007", original: "diploma", translation: "диплом", transcription: "/dɪˈploʊmə/", exampleSentence: "I received my diploma yesterday.", exampleTranslation: "Я отримав свій диплом вчора.", synonyms: ["certificate"], difficulty: .a1, category: .education),
        Word(id: "edu_008", original: "exam", translation: "іспит", transcription: "/ɪɡˈzæm/", exampleSentence: "I have an exam next week.", exampleTranslation: "У мене іспит наступного тижня.", synonyms: ["test"], difficulty: .a1, category: .education),
        Word(id: "edu_009", original: "grade", translation: "оцінка", transcription: "/ɡreɪd/", exampleSentence: "I got a good grade on my test.", exampleTranslation: "Я отримав хорошу оцінку за тест.", synonyms: ["mark"], difficulty: .a1, category: .education),
        Word(id: "edu_010", original: "homework", translation: "домашнє завдання", transcription: "/ˈhoʊmwɜːrk/", exampleSentence: "I need to finish my homework.", exampleTranslation: "Мені потрібно закінчити домашнє завдання.", synonyms: ["assignment"], difficulty: .a1, category: .education),
        Word(id: "edu_011", original: "knowledge", translation: "знання", transcription: "/ˈnɑːlɪdʒ/", exampleSentence: "Knowledge is power.", exampleTranslation: "Знання — це сила.", synonyms: ["wisdom"], difficulty: .a1, category: .education),
        Word(id: "edu_012", original: "learn", translation: "вчити", transcription: "/lɜːrn/", exampleSentence: "I want to learn French.", exampleTranslation: "Я хочу вчити французьку.", synonyms: ["study"], difficulty: .a1, category: .education),
        Word(id: "edu_013", original: "lesson", translation: "урок", transcription: "/ˈlesn/", exampleSentence: "Today we have an English lesson.", exampleTranslation: "Сьогодні у нас урок англійської.", synonyms: ["class"], difficulty: .a1, category: .education),
        Word(id: "edu_014", original: "library", translation: "бібліотека", transcription: "/ˈlaɪbreri/", exampleSentence: "I study at the library.", exampleTranslation: "Я вчуся в бібліотеці.", synonyms: ["book room"], difficulty: .a1, category: .education),
        Word(id: "edu_015", original: "mark", translation: "оцінка", transcription: "/mɑːrk/", exampleSentence: "I got a high mark.", exampleTranslation: "Я отримав високу оцінку.", synonyms: ["grade"], difficulty: .a1, category: .education),
        Word(id: "edu_016", original: "notebook", translation: "зошит", transcription: "/ˈnoʊtbʊk/", exampleSentence: "Write it in your notebook.", exampleTranslation: "Запиши це в свій зошит.", synonyms: ["notepad"], difficulty: .a1, category: .education),
        Word(id: "edu_017", original: "pupil", translation: "учень", transcription: "/ˈpjuːpl/", exampleSentence: "The pupils are in class.", exampleTranslation: "Учні в класі.", synonyms: ["student"], difficulty: .a1, category: .education),
        Word(id: "edu_018", original: "question", translation: "питання", transcription: "/ˈkwestʃən/", exampleSentence: "Do you have any questions?", exampleTranslation: "У тебе є якісь питання?", synonyms: ["query"], difficulty: .a1, category: .education),
        Word(id: "edu_019", original: "scholarship", translation: "стипендія", transcription: "/ˈskɑːlərʃɪp/", exampleSentence: "She won a scholarship.", exampleTranslation: "Вона виграла стипендію.", synonyms: ["grant"], difficulty: .a1, category: .education),
        Word(id: "edu_020", original: "school", translation: "школа", transcription: "/skuːl/", exampleSentence: "I walk to school every day.", exampleTranslation: "Я ходжу до школи пішки щодня.", synonyms: ["academy"], difficulty: .a1, category: .education),
        Word(id: "edu_021", original: "science", translation: "наука", transcription: "/ˈsaɪəns/", exampleSentence: "I love science class.", exampleTranslation: "Я люблю уроки науки.", synonyms: ["knowledge"], difficulty: .a1, category: .education),
        Word(id: "edu_022", original: "semester", translation: "семестр", transcription: "/sɪˈmestər/", exampleSentence: "The semester ends in June.", exampleTranslation: "Семестр закінчується в червні.", synonyms: ["term"], difficulty: .a1, category: .education),
        Word(id: "edu_023", original: "student", translation: "студент", transcription: "/ˈstuːdnt/", exampleSentence: "I am a university student.", exampleTranslation: "Я студент університету.", synonyms: ["learner"], difficulty: .a1, category: .education),
        Word(id: "edu_024", original: "study", translation: "вчитися", transcription: "/ˈstʌdi/", exampleSentence: "I need to study for the exam.", exampleTranslation: "Мені потрібно вчитися до іспиту.", synonyms: ["learn"], difficulty: .a1, category: .education),
        Word(id: "edu_025", original: "subject", translation: "предмет", transcription: "/ˈsʌbdʒɪkt/", exampleSentence: "Math is my favorite subject.", exampleTranslation: "Математика — мій улюблений предмет.", synonyms: ["topic"], difficulty: .a1, category: .education),
        Word(id: "edu_026", original: "teacher", translation: "вчитель", transcription: "/ˈtiːtʃər/", exampleSentence: "My teacher is very helpful.", exampleTranslation: "Мій вчитель дуже допомагає.", synonyms: ["instructor"], difficulty: .a1, category: .education),
        Word(id: "edu_027", original: "test", translation: "тест", transcription: "/test/", exampleSentence: "We have a test tomorrow.", exampleTranslation: "У нас завтра тест.", synonyms: ["exam"], difficulty: .a1, category: .education),
        Word(id: "edu_028", original: "textbook", translation: "підручник", transcription: "/ˈtekstbʊk/", exampleSentence: "Open your textbook to page 10.", exampleTranslation: "Відкрийте підручник на сторінці 10.", synonyms: ["book"], difficulty: .a1, category: .education),
        Word(id: "edu_029", original: "university", translation: "університет", transcription: "/ˌjuːnɪˈvɜːrsəti/", exampleSentence: "He studies at a big university.", exampleTranslation: "Він вчиться у великому університеті.", synonyms: ["college"], difficulty: .a1, category: .education),
    ]

    static let businessWords: [Word] = [
        Word(id: "business_001", original: "agreement", translation: "угода", transcription: "/əˈɡriːmənt/", exampleSentence: "We signed an agreement.", exampleTranslation: "Ми підписали угоду.", synonyms: ["contract"], difficulty: .a1, category: .business),
        Word(id: "business_002", original: "budget", translation: "бюджет", transcription: "/ˈbʌdʒɪt/", exampleSentence: "We need to stick to the budget.", exampleTranslation: "Нам потрібно дотримуватися бюджету.", synonyms: ["finance"], difficulty: .a1, category: .business),
        Word(id: "business_003", original: "CEO", translation: "генеральний директор", transcription: "/ˌsiːiːˈoʊ/", exampleSentence: "The CEO gave a speech.", exampleTranslation: "Генеральний директор виступив з промовою.", synonyms: ["chief"], difficulty: .a1, category: .business),
        Word(id: "business_004", original: "competitor", translation: "конкурент", transcription: "/kəmˈpetɪtər/", exampleSentence: "We need to watch our competitors.", exampleTranslation: "Нам потрібно стежити за нашими конкурентами.", synonyms: ["rival"], difficulty: .a1, category: .business),
        Word(id: "business_005", original: "contract", translation: "контракт", transcription: "/ˈkɑːntrækt/", exampleSentence: "We signed a new contract.", exampleTranslation: "Ми підписали новий контракт.", synonyms: ["agreement"], difficulty: .a1, category: .business),
        Word(id: "business_006", original: "corporation", translation: "корпорація", transcription: "/ˌkɔːrpəˈreɪʃn/", exampleSentence: "He works for a big corporation.", exampleTranslation: "Він працює у великій корпорації.", synonyms: ["company"], difficulty: .a1, category: .business),
        Word(id: "business_007", original: "deal", translation: "угода", transcription: "/diːl/", exampleSentence: "We made a great deal.", exampleTranslation: "Ми уклали чудову угоду.", synonyms: ["agreement"], difficulty: .a1, category: .business),
        Word(id: "business_008", original: "earnings", translation: "заробіток", transcription: "/ˈɜːrnɪŋz/", exampleSentence: "Our earnings increased this quarter.", exampleTranslation: "Наші заробітки зросли цього кварталу.", synonyms: ["profit"], difficulty: .a1, category: .business),
        Word(id: "business_009", original: "economy", translation: "економіка", transcription: "/ɪˈkɑːnəmi/", exampleSentence: "The economy is growing.", exampleTranslation: "Економіка зростає.", synonyms: ["finance"], difficulty: .a1, category: .business),
        Word(id: "business_010", original: "entrepreneur", translation: "підприємець", transcription: "/ˌɑːntrəprəˈnɜːr/", exampleSentence: "He is a successful entrepreneur.", exampleTranslation: "Він успішний підприємець.", synonyms: ["businessman"], difficulty: .a1, category: .business),
        Word(id: "business_011", original: "expense", translation: "витрата", transcription: "/ɪkˈspens/", exampleSentence: "Travel is a business expense.", exampleTranslation: "Подорожі — це бізнес-витрата.", synonyms: ["cost"], difficulty: .a1, category: .business),
        Word(id: "business_012", original: "export", translation: "експорт", transcription: "/ˈekspɔːrt/", exampleSentence: "We export goods to Europe.", exampleTranslation: "Ми експортуємо товари до Європи.", synonyms: ["ship"], difficulty: .a1, category: .business),
        Word(id: "business_013", original: "growth", translation: "зростання", transcription: "/ɡroʊθ/", exampleSentence: "The company is experiencing rapid growth.", exampleTranslation: "Компанія переживає швидке зростання.", synonyms: ["expansion"], difficulty: .a1, category: .business),
        Word(id: "business_014", original: "import", translation: "імпорт", transcription: "/ˈɪmpɔːrt/", exampleSentence: "We import raw materials.", exampleTranslation: "Ми імпортуємо сировину.", synonyms: ["bring in"], difficulty: .a1, category: .business),
        Word(id: "business_015", original: "industry", translation: "промисловість", transcription: "/ˈɪndəstri/", exampleSentence: "The tech industry is booming.", exampleTranslation: "Технологічна промисловість процвітає.", synonyms: ["sector"], difficulty: .a1, category: .business),
        Word(id: "business_016", original: "investment", translation: "інвестиція", transcription: "/ɪnˈvestmənt/", exampleSentence: "This is a good investment.", exampleTranslation: "Це хороша інвестиція.", synonyms: ["funding"], difficulty: .a1, category: .business),
        Word(id: "business_017", original: "leadership", translation: "лідерство", transcription: "/ˈliːdərʃɪp/", exampleSentence: "Good leadership is essential.", exampleTranslation: "Хороше лідерство є необхідним.", synonyms: ["management"], difficulty: .a1, category: .business),
        Word(id: "business_018", original: "loss", translation: "збиток", transcription: "/lɔːs/", exampleSentence: "The company reported a loss.", exampleTranslation: "Компанія повідомила про збиток.", synonyms: ["deficit"], difficulty: .a1, category: .business),
        Word(id: "business_019", original: "market", translation: "ринок", transcription: "/ˈmɑːrkɪt/", exampleSentence: "We need to expand into new markets.", exampleTranslation: "Нам потрібно вийти на нові ринки.", synonyms: ["industry"], difficulty: .a1, category: .business),
        Word(id: "business_020", original: "meeting", translation: "зустріч", transcription: "/ˈmiːtɪŋ/", exampleSentence: "We have a meeting at 2 PM.", exampleTranslation: "У нас зустріч о 14:00.", synonyms: ["conference"], difficulty: .a1, category: .business),
        Word(id: "business_021", original: "merger", translation: "злиття", transcription: "/ˈmɜːrdʒər/", exampleSentence: "The merger was successful.", exampleTranslation: "Злиття було успішним.", synonyms: ["combination"], difficulty: .a1, category: .business),
        Word(id: "business_022", original: "negotiation", translation: "переговори", transcription: "/nɪˌɡoʊʃiˈeɪʃn/", exampleSentence: "The negotiation took three hours.", exampleTranslation: "Переговори тривали три години.", synonyms: ["discussion"], difficulty: .a1, category: .business),
        Word(id: "business_023", original: "partnership", translation: "партнерство", transcription: "/ˈpɑːrtnərʃɪp/", exampleSentence: "We formed a new partnership.", exampleTranslation: "Ми утворили нове партнерство.", synonyms: ["alliance"], difficulty: .a1, category: .business),
        Word(id: "business_024", original: "profit", translation: "прибуток", transcription: "/ˈprɑːfɪt/", exampleSentence: "Our profit increased by 20%.", exampleTranslation: "Наш прибуток зріс на 20%.", synonyms: ["earnings"], difficulty: .a1, category: .business),
        Word(id: "business_025", original: "revenue", translation: "дохід", transcription: "/ˈrevənuː/", exampleSentence: "Our revenue has grown.", exampleTranslation: "Наш дохід зріс.", synonyms: ["income"], difficulty: .a1, category: .business),
        Word(id: "business_026", original: "shareholder", translation: "акціонер", transcription: "/ˈʃerhoʊldər/", exampleSentence: "The shareholders voted yes.", exampleTranslation: "Акціонери проголосували «так».", synonyms: ["investor"], difficulty: .a1, category: .business),
        Word(id: "business_027", original: "startup", translation: "стартап", transcription: "/ˈstɑːrtʌp/", exampleSentence: "He founded a tech startup.", exampleTranslation: "Він заснував технологічний стартап.", synonyms: ["new company"], difficulty: .a1, category: .business),
        Word(id: "business_028", original: "strategy", translation: "стратегія", transcription: "/ˈstrætədʒi/", exampleSentence: "We need a new marketing strategy.", exampleTranslation: "Нам потрібна нова маркетингова стратегія.", synonyms: ["plan"], difficulty: .a1, category: .business),
        Word(id: "business_029", original: "success", translation: "успіх", transcription: "/səkˈses/", exampleSentence: "Hard work leads to success.", exampleTranslation: "Важка робота веде до успіху.", synonyms: ["achievement"], difficulty: .a1, category: .business),
        Word(id: "business_030", original: "target", translation: "ціль", transcription: "/ˈtɑːrɡɪt/", exampleSentence: "We met our sales target.", exampleTranslation: "Ми досягли нашої цілі продажів.", synonyms: ["goal"], difficulty: .a1, category: .business),
    ]

    static let hobbiesWords: [Word] = [
        Word(id: "hobby_001", original: "art", translation: "мистецтво", transcription: "/ɑːrt/", exampleSentence: "I love creating art.", exampleTranslation: "Я люблю створювати мистецтво.", synonyms: ["craft"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_002", original: "baking", translation: "випічка", transcription: "/ˈbeɪkɪŋ/", exampleSentence: "Baking is my favorite hobby.", exampleTranslation: "Випічка — моє улюблене хобі.", synonyms: ["cooking"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_003", original: "board game", translation: "настільна гра", transcription: "/bɔːrd ɡeɪm/", exampleSentence: "We play board games on weekends.", exampleTranslation: "Ми граємо в настільні ігри на вихідних.", synonyms: ["game"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_004", original: "camping", translation: "кемпінг", transcription: "/ˈkæmpɪŋ/", exampleSentence: "We go camping every summer.", exampleTranslation: "Ми їздимо в кемпінг кожного літа.", synonyms: ["outdoor"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_005", original: "chess", translation: "шахи", transcription: "/tʃes/", exampleSentence: "Chess requires strategy.", exampleTranslation: "Шахи вимагають стратегії.", synonyms: ["game"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_006", original: "cooking", translation: "готування", transcription: "/ˈkʊkɪŋ/", exampleSentence: "Cooking is relaxing for me.", exampleTranslation: "Готування розслабляє мене.", synonyms: ["cuisine"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_007", original: "craft", translation: "ремесло", transcription: "/kræft/", exampleSentence: "I enjoy doing crafts.", exampleTranslation: "Мені подобається займатися ремеслом.", synonyms: ["handicraft"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_008", original: "crochet", translation: "вʼязання гачком", transcription: "/kroʊˈʃeɪ/", exampleSentence: "She taught me how to crochet.", exampleTranslation: "Вона навчила мене вʼязати гачком.", synonyms: ["knitting"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_009", original: "dance", translation: "танець", transcription: "/dæns/", exampleSentence: "I take dance classes.", exampleTranslation: "Я ходжу на уроки танців.", synonyms: ["movement"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_010", original: "drawing", translation: "малювання", transcription: "/ˈdrɔːɪŋ/", exampleSentence: "Drawing helps me relax.", exampleTranslation: "Малювання допомагає мені розслабитися.", synonyms: ["sketching"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_011", original: "fishing", translation: "риболовля", transcription: "/ˈfɪʃɪŋ/", exampleSentence: "He goes fishing every Sunday.", exampleTranslation: "Він ходить на риболовлю щонеділі.", synonyms: ["angling"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_012", original: "gardening", translation: "садівництво", transcription: "/ˈɡɑːrdnɪŋ/", exampleSentence: "Gardening is good exercise.", exampleTranslation: "Садівництво — хороша вправа.", synonyms: ["farming"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_013", original: "guitar", translation: "гітара", transcription: "/ɡɪˈtɑːr/", exampleSentence: "I am learning to play guitar.", exampleTranslation: "Я вчуся грати на гітарі.", synonyms: ["instrument"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_014", original: "hiking", translation: "похід", transcription: "/ˈhaɪkɪŋ/", exampleSentence: "We went hiking in the mountains.", exampleTranslation: "Ми пішли в похід у гори.", synonyms: ["trekking"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_015", original: "jogging", translation: "біг", transcription: "/ˈdʒɑːɡɪŋ/", exampleSentence: "I go jogging every morning.", exampleTranslation: "Я бігаю щоранку.", synonyms: ["running"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_016", original: "knitting", translation: "вʼязання", transcription: "/ˈnɪtɪŋ/", exampleSentence: "My grandmother loves knitting.", exampleTranslation: "Моя бабуся любить вʼязати.", synonyms: ["sewing"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_017", original: "movie", translation: "фільм", transcription: "/ˈmuːvi/", exampleSentence: "Watching movies is my hobby.", exampleTranslation: "Перегляд фільмів — моє хобі.", synonyms: ["film"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_018", original: "music", translation: "музика", transcription: "/ˈmjuːzɪk/", exampleSentence: "I listen to music every day.", exampleTranslation: "Я слухаю музику щодня.", synonyms: ["tunes"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_019", original: "painting", translation: "живопис", transcription: "/ˈpeɪntɪŋ/", exampleSentence: "Painting is very therapeutic.", exampleTranslation: "Живопис дуже терапевтичний.", synonyms: ["art"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_020", original: "photography", translation: "фотографія", transcription: "/fəˈtɑːɡrəfi/", exampleSentence: "Photography is my passion.", exampleTranslation: "Фотографія — моя пристрасть.", synonyms: ["photos"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_021", original: "puzzle", translation: "пазл", transcription: "/ˈpʌzl/", exampleSentence: "I enjoy doing puzzles.", exampleTranslation: "Мені подобається складати пазли.", synonyms: ["jigsaw"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_022", original: "reading", translation: "читання", transcription: "/ˈriːdɪŋ/", exampleSentence: "Reading is my favorite pastime.", exampleTranslation: "Читання — моє улюблене заняття.", synonyms: ["books"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_023", original: "running", translation: "біг", transcription: "/ˈrʌnɪŋ/", exampleSentence: "Running keeps me fit.", exampleTranslation: "Біг підтримує мене у формі.", synonyms: ["jogging"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_024", original: "singing", translation: "спів", transcription: "/ˈsɪŋɪŋ/", exampleSentence: "She loves singing in the choir.", exampleTranslation: "Вона любить співати в хорі.", synonyms: ["vocal"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_025", original: "skiing", translation: "катання на лижах", transcription: "/ˈskiːɪŋ/", exampleSentence: "Skiing is fun in winter.", exampleTranslation: "Катання на лижах веселе взимку.", synonyms: ["winter sport"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_026", original: "swimming", translation: "плавання", transcription: "/ˈswɪmɪŋ/", exampleSentence: "Swimming is great exercise.", exampleTranslation: "Плавання — чудова вправа.", synonyms: ["aquatic"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_027", original: "traveling", translation: "подорожі", transcription: "/ˈtrævəlɪŋ/", exampleSentence: "Traveling is my biggest hobby.", exampleTranslation: "Подорожі — моє найбільше хобі.", synonyms: ["tourism"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_028", original: "video game", translation: "відеогра", transcription: "/ˈvɪdioʊ ɡeɪm/", exampleSentence: "I play video games to relax.", exampleTranslation: "Я граю у відеоігри, щоб розслабитися.", synonyms: ["gaming"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_029", original: "volunteering", translation: "волонтерство", transcription: "/ˌvɑːlənˈtɪrɪŋ/", exampleSentence: "Volunteering gives me purpose.", exampleTranslation: "Волонтерство дає мені мету.", synonyms: ["charity"], difficulty: .a1, category: .hobbies),
        Word(id: "hobby_030", original: "yoga", translation: "йога", transcription: "/ˈjoʊɡə/", exampleSentence: "Yoga helps me stay calm.", exampleTranslation: "Йога допомагає мені залишатися спокійним.", synonyms: ["meditation"], difficulty: .a1, category: .hobbies),
    ]

    static let socialWords: [Word] = [
        Word(id: "social_001", original: "apologize", translation: "вибачатися", transcription: "/əˈpɑːlədʒaɪz/", exampleSentence: "I want to apologize for my behavior.", exampleTranslation: "Я хочу вибачитися за свою поведінку.", synonyms: ["say sorry"], difficulty: .a1, category: .social),
        Word(id: "social_002", original: "celebrate", translation: "святкувати", transcription: "/ˈselɪbreɪt/", exampleSentence: "We celebrate birthdays together.", exampleTranslation: "Ми святкуємо дні народження разом.", synonyms: ["commemorate"], difficulty: .a1, category: .social),
        Word(id: "social_003", original: "chat", translation: "балакати", transcription: "/tʃæt/", exampleSentence: "We chatted for hours.", exampleTranslation: "Ми балакали годинами.", synonyms: ["talk"], difficulty: .a1, category: .social),
        Word(id: "social_004", original: "compliment", translation: "комплімент", transcription: "/ˈkɑːmplɪmənt/", exampleSentence: "She gave me a nice compliment.", exampleTranslation: "Вона зробила мені приємний комплімент.", synonyms: ["praise"], difficulty: .a1, category: .social),
        Word(id: "social_005", original: "congratulate", translation: "вітати", transcription: "/kənˈɡrætʃuleɪt/", exampleSentence: "I want to congratulate you on your success.", exampleTranslation: "Я хочу привітати тебе з успіхом.", synonyms: ["celebrate"], difficulty: .a1, category: .social),
        Word(id: "social_006", original: "conversation", translation: "розмова", transcription: "/ˌkɑːnvərˈseɪʃn/", exampleSentence: "We had an interesting conversation.", exampleTranslation: "Ми мали цікаву розмову.", synonyms: ["dialogue"], difficulty: .a1, category: .social),
        Word(id: "social_007", original: "date", translation: "побачення", transcription: "/deɪt/", exampleSentence: "We went on a date last night.", exampleTranslation: "Ми були на побаченні вчора ввечері.", synonyms: ["appointment"], difficulty: .a1, category: .social),
        Word(id: "social_008", original: "discuss", translation: "обговорювати", transcription: "/dɪˈskʌs/", exampleSentence: "Let us discuss this tomorrow.", exampleTranslation: "Давай обговоримо це завтра.", synonyms: ["talk about"], difficulty: .a1, category: .social),
        Word(id: "social_009", original: "greet", translation: "вітатися", transcription: "/ɡriːt/", exampleSentence: "Greet everyone when you enter.", exampleTranslation: "Вітайся з усіма, коли входиш.", synonyms: ["welcome"], difficulty: .a1, category: .social),
        Word(id: "social_010", original: "hang out", translation: "проводити час", transcription: "/hæŋ aʊt/", exampleSentence: "We often hang out after work.", exampleTranslation: "Ми часто проводимо час після роботи.", synonyms: ["spend time"], difficulty: .a1, category: .social),
        Word(id: "social_011", original: "invite", translation: "запрошувати", transcription: "/ɪnˈvaɪt/", exampleSentence: "I want to invite you to dinner.", exampleTranslation: "Я хочу запросити тебе на вечерю.", synonyms: ["ask"], difficulty: .a1, category: .social),
        Word(id: "social_012", original: "joke", translation: "жарт", transcription: "/dʒoʊk/", exampleSentence: "He told a funny joke.", exampleTranslation: "Він розказав смішний жарт.", synonyms: ["prank"], difficulty: .a1, category: .social),
        Word(id: "social_013", original: "laugh", translation: "сміятися", transcription: "/læf/", exampleSentence: "We laughed all night.", exampleTranslation: "Ми сміялися всю ніч.", synonyms: ["giggle"], difficulty: .a1, category: .social),
        Word(id: "social_014", original: "listen", translation: "слухати", transcription: "/ˈlɪsn/", exampleSentence: "Listen to what I am saying.", exampleTranslation: "Слухай, що я кажу.", synonyms: ["hear"], difficulty: .a1, category: .social),
        Word(id: "social_015", original: "message", translation: "повідомлення", transcription: "/ˈmesɪdʒ/", exampleSentence: "Send me a message later.", exampleTranslation: "Надішли мені повідомлення пізніше.", synonyms: ["text"], difficulty: .a1, category: .social),
        Word(id: "social_016", original: "network", translation: "спілкуватися", transcription: "/ˈnetwɜːrk/", exampleSentence: "It is important to network.", exampleTranslation: "Важливо спілкуватися.", synonyms: ["connect"], difficulty: .a1, category: .social),
        Word(id: "social_017", original: "party", translation: "вечірка", transcription: "/ˈpɑːrti/", exampleSentence: "We are having a party on Saturday.", exampleTranslation: "У нас вечірка в суботу.", synonyms: ["celebration"], difficulty: .a1, category: .social),
        Word(id: "social_018", original: "recommend", translation: "рекомендувати", transcription: "/ˌrekəˈmend/", exampleSentence: "Can you recommend a good restaurant?", exampleTranslation: "Можеш порекомендувати хороший ресторан?", synonyms: ["suggest"], difficulty: .a1, category: .social),
        Word(id: "social_019", original: "relationship", translation: "стосунки", transcription: "/rɪˈleɪʃnʃɪp/", exampleSentence: "They have a great relationship.", exampleTranslation: "У них чудові стосунки.", synonyms: ["connection"], difficulty: .a1, category: .social),
        Word(id: "social_020", original: "reply", translation: "відповідати", transcription: "/rɪˈplaɪ/", exampleSentence: "Please reply to my email.", exampleTranslation: "Будь ласка, відповідай на мій лист.", synonyms: ["answer"], difficulty: .a1, category: .social),
        Word(id: "social_021", original: "share", translation: "ділитися", transcription: "/ʃer/", exampleSentence: "Share your thoughts with me.", exampleTranslation: "Поділися своїми думками зі мною.", synonyms: ["tell"], difficulty: .a1, category: .social),
        Word(id: "social_022", original: "smile", translation: "посмішка", transcription: "/smaɪl/", exampleSentence: "She has a beautiful smile.", exampleTranslation: "У неї гарна посмішка.", synonyms: ["grin"], difficulty: .a1, category: .social),
        Word(id: "social_023", original: "suggest", translation: "пропонувати", transcription: "/səˈdʒest/", exampleSentence: "I suggest we meet tomorrow.", exampleTranslation: "Я пропоную зустрітися завтра.", synonyms: ["recommend"], difficulty: .a1, category: .social),
        Word(id: "social_024", original: "support", translation: "підтримка", transcription: "/səˈpɔːrt/", exampleSentence: "Thank you for your support.", exampleTranslation: "Дякую за твою підтримку.", synonyms: ["help"], difficulty: .a1, category: .social),
        Word(id: "social_025", original: "talk", translation: "говорити", transcription: "/tɔːk/", exampleSentence: "We need to talk.", exampleTranslation: "Нам потрібно поговорити.", synonyms: ["speak"], difficulty: .a1, category: .social),
        Word(id: "social_026", original: "thank", translation: "дякувати", transcription: "/θæŋk/", exampleSentence: "I want to thank you for everything.", exampleTranslation: "Я хочу подякувати тобі за все.", synonyms: ["grateful"], difficulty: .a1, category: .social),
        Word(id: "social_027", original: "trust", translation: "довіра", transcription: "/trʌst/", exampleSentence: "Trust is important in relationships.", exampleTranslation: "Довіра важлива в стосунках.", synonyms: ["faith"], difficulty: .a1, category: .social),
        Word(id: "social_028", original: "visit", translation: "відвідувати", transcription: "/ˈvɪzɪt/", exampleSentence: "I want to visit my grandmother.", exampleTranslation: "Я хочу відвідати свою бабусю.", synonyms: ["see"], difficulty: .a1, category: .social),
        Word(id: "social_029", original: "welcome", translation: "ласкаво просимо", transcription: "/ˈwelkəm/", exampleSentence: "Welcome to our home!", exampleTranslation: "Ласкаво просимо до нашого дому!", synonyms: ["greet"], difficulty: .a1, category: .social),
    ]

    static let homeWords: [Word] = [
        Word(id: "home_001", original: "apartment", translation: "квартира", transcription: "/əˈpɑːrtmənt/", exampleSentence: "I live in a small apartment.", exampleTranslation: "Я живу в маленькій квартирі.", synonyms: ["flat"], difficulty: .a1, category: .home),
        Word(id: "home_002", original: "balcony", translation: "балкон", transcription: "/ˈbælkəni/", exampleSentence: "We have breakfast on the balcony.", exampleTranslation: "Ми снідаємо на балконі.", synonyms: ["terrace"], difficulty: .a1, category: .home),
        Word(id: "home_003", original: "basement", translation: "підвал", transcription: "/ˈbeɪsmənt/", exampleSentence: "We store things in the basement.", exampleTranslation: "Ми зберігаємо речі в підвалі.", synonyms: ["cellar"], difficulty: .a1, category: .home),
        Word(id: "home_004", original: "bathroom", translation: "ванна кімната", transcription: "/ˈbæθruːm/", exampleSentence: "The bathroom is upstairs.", exampleTranslation: "Ванна кімната нагорі.", synonyms: ["restroom"], difficulty: .a1, category: .home),
        Word(id: "home_005", original: "bedroom", translation: "спальня", transcription: "/ˈbedruːm/", exampleSentence: "My bedroom is small but cozy.", exampleTranslation: "Моя спальня маленька, але затишна.", synonyms: ["sleeping room"], difficulty: .a1, category: .home),
        Word(id: "home_006", original: "blanket", translation: "ковдра", transcription: "/ˈblæŋkɪt/", exampleSentence: "I need a warm blanket.", exampleTranslation: "Мені потрібна тепла ковдра.", synonyms: ["cover"], difficulty: .a1, category: .home),
        Word(id: "home_007", original: "carpet", translation: "килим", transcription: "/ˈkɑːrpɪt/", exampleSentence: "The carpet needs cleaning.", exampleTranslation: "Килим потребує чищення.", synonyms: ["rug"], difficulty: .a1, category: .home),
        Word(id: "home_008", original: "ceiling", translation: "стеля", transcription: "/ˈsiːlɪŋ/", exampleSentence: "The ceiling is very high.", exampleTranslation: "Стеля дуже висока.", synonyms: ["roof"], difficulty: .a1, category: .home),
        Word(id: "home_009", original: "closet", translation: "шафа", transcription: "/ˈklɑːzɪt/", exampleSentence: "My clothes are in the closet.", exampleTranslation: "Мій одяг у шафі.", synonyms: ["wardrobe"], difficulty: .a1, category: .home),
        Word(id: "home_010", original: "couch", translation: "диван", transcription: "/kaʊtʃ/", exampleSentence: "Sit on the couch.", exampleTranslation: "Сідай на диван.", synonyms: ["sofa"], difficulty: .a1, category: .home),
        Word(id: "home_011", original: "curtain", translation: "штора", transcription: "/ˈkɜːrtn/", exampleSentence: "Close the curtains, please.", exampleTranslation: "Закрий штори, будь ласка.", synonyms: ["drape"], difficulty: .a1, category: .home),
        Word(id: "home_012", original: "dining room", translation: "їдальня", transcription: "/ˈdaɪnɪŋ ruːm/", exampleSentence: "We eat in the dining room.", exampleTranslation: "Ми їмо в їдальні.", synonyms: ["eating area"], difficulty: .a1, category: .home),
        Word(id: "home_013", original: "elevator", translation: "ліфт", transcription: "/ˈelɪveɪtər/", exampleSentence: "Take the elevator to the 5th floor.", exampleTranslation: "Їдьте ліфтом на 5-й поверх.", synonyms: ["lift"], difficulty: .a1, category: .home),
        Word(id: "home_014", original: "floor", translation: "підлога", transcription: "/flɔːr/", exampleSentence: "The floor is made of wood.", exampleTranslation: "Підлога зроблена з дерева.", synonyms: ["ground"], difficulty: .a1, category: .home),
        Word(id: "home_015", original: "furniture", translation: "меблі", transcription: "/ˈfɜːrnɪtʃər/", exampleSentence: "We need to buy new furniture.", exampleTranslation: "Нам потрібно купити нові меблі.", synonyms: ["furnishings"], difficulty: .a1, category: .home),
        Word(id: "home_016", original: "garage", translation: "гараж", transcription: "/ɡəˈrɑːʒ/", exampleSentence: "The car is in the garage.", exampleTranslation: "Машина в гаражі.", synonyms: ["carport"], difficulty: .a1, category: .home),
        Word(id: "home_017", original: "garden", translation: "сад", transcription: "/ˈɡɑːrdn/", exampleSentence: "We have a beautiful garden.", exampleTranslation: "У нас гарний сад.", synonyms: ["yard"], difficulty: .a1, category: .home),
        Word(id: "home_018", original: "hall", translation: "коридор", transcription: "/hɔːl/", exampleSentence: "Wait in the hall, please.", exampleTranslation: "Зачекайте в коридорі, будь ласка.", synonyms: ["corridor"], difficulty: .a1, category: .home),
        Word(id: "home_019", original: "heater", translation: "обігрівач", transcription: "/ˈhiːtər/", exampleSentence: "Turn on the heater, it is cold.", exampleTranslation: "Включи обігрівач, холодно.", synonyms: ["radiator"], difficulty: .a1, category: .home),
        Word(id: "home_020", original: "key", translation: "ключ", transcription: "/kiː/", exampleSentence: "Do not forget your keys.", exampleTranslation: "Не забудь свої ключі.", synonyms: ["lock opener"], difficulty: .a1, category: .home),
        Word(id: "home_021", original: "kitchen", translation: "кухня", transcription: "/ˈkɪtʃɪn/", exampleSentence: "Mom is cooking in the kitchen.", exampleTranslation: "Мама готує на кухні.", synonyms: ["cooking area"], difficulty: .a1, category: .home),
        Word(id: "home_022", original: "lamp", translation: "лампа", transcription: "/læmp/", exampleSentence: "Turn on the lamp, please.", exampleTranslation: "Включи лампу, будь ласка.", synonyms: ["light"], difficulty: .a1, category: .home),
        Word(id: "home_023", original: "living room", translation: "вітальня", transcription: "/ˈlɪvɪŋ ruːm/", exampleSentence: "We watch TV in the living room.", exampleTranslation: "Ми дивимося телевізор у вітальні.", synonyms: ["lounge"], difficulty: .a1, category: .home),
        Word(id: "home_024", original: "mirror", translation: "дзеркало", transcription: "/ˈmɪrər/", exampleSentence: "Look in the mirror.", exampleTranslation: "Подивися в дзеркало.", synonyms: ["reflection"], difficulty: .a1, category: .home),
        Word(id: "home_025", original: "neighbor", translation: "сусід", transcription: "/ˈneɪbər/", exampleSentence: "My neighbor is very friendly.", exampleTranslation: "Мій сусід дуже дружній.", synonyms: ["resident"], difficulty: .a1, category: .home),
        Word(id: "home_026", original: "pillow", translation: "подушка", transcription: "/ˈpɪloʊ/", exampleSentence: "I need a softer pillow.", exampleTranslation: "Мені потрібна мʼякша подушка.", synonyms: ["cushion"], difficulty: .a1, category: .home),
        Word(id: "home_027", original: "refrigerator", translation: "холодильник", transcription: "/rɪˈfrɪdʒəreɪtər/", exampleSentence: "Put the milk in the refrigerator.", exampleTranslation: "Поклади молоко в холодильник.", synonyms: ["fridge"], difficulty: .a1, category: .home),
        Word(id: "home_028", original: "roof", translation: "дах", transcription: "/ruːf/", exampleSentence: "The roof needs repair.", exampleTranslation: "Дах потребує ремонту.", synonyms: ["top"], difficulty: .a1, category: .home),
        Word(id: "home_029", original: "shelf", translation: "полиця", transcription: "/ʃelf/", exampleSentence: "Put the books on the shelf.", exampleTranslation: "Поклади книги на полицю.", synonyms: ["rack"], difficulty: .a1, category: .home),
        Word(id: "home_030", original: "shower", translation: "душ", transcription: "/ˈʃaʊər/", exampleSentence: "I take a shower every morning.", exampleTranslation: "Я приймаю душ щоранку.", synonyms: ["bath"], difficulty: .a1, category: .home),
        Word(id: "home_031", original: "stairs", translation: "сходи", transcription: "/sterz/", exampleSentence: "Be careful on the stairs.", exampleTranslation: "Будь обережний на сходах.", synonyms: ["steps"], difficulty: .a1, category: .home),
        Word(id: "home_032", original: "toilet", translation: "туалет", transcription: "/ˈtɔɪlət/", exampleSentence: "Where is the toilet?", exampleTranslation: "Де туалет?", synonyms: ["bathroom"], difficulty: .a1, category: .home),
        Word(id: "home_033", original: "wall", translation: "стіна", transcription: "/wɔːl/", exampleSentence: "Hang the picture on the wall.", exampleTranslation: "Повісь картину на стіну.", synonyms: ["partition"], difficulty: .a1, category: .home),
        Word(id: "home_034", original: "yard", translation: "подвірʼя", transcription: "/jɑːrd/", exampleSentence: "The kids are playing in the yard.", exampleTranslation: "Діти граються у дворі.", synonyms: ["garden"], difficulty: .a1, category: .home),
    ]


    // MARK: - Verbs Arrays

    static let verbsWords: [Word] = [
        Word(id: "verb_001", original: "accept", translation: "приймати", transcription: "/əkˈsept/", exampleSentence: "I accept your apology.", exampleTranslation: "Я приймаю твої вибачення.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_002", original: "add", translation: "додавати", transcription: "/æd/", exampleSentence: "Add salt to the soup.", exampleTranslation: "Додай солі до супу.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_003", original: "agree", translation: "погоджуватися", transcription: "/əˈɡriː/", exampleSentence: "I agree with you.", exampleTranslation: "Я з тобою погоджуюся.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_004", original: "allow", translation: "дозволяти", transcription: "/əˈlaʊ/", exampleSentence: "Smoking is not allowed.", exampleTranslation: "Куріння не дозволяється.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_005", original: "answer", translation: "відповідати", transcription: "/ˈænsər/", exampleSentence: "Please answer the question.", exampleTranslation: "Будь ласка, відповідай на питання.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_006", original: "arrive", translation: "прибувати", transcription: "/əˈraɪv/", exampleSentence: "We arrived at noon.", exampleTranslation: "Ми прибули опівдні.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_007", original: "ask", translation: "питати", transcription: "/ɑːsk/", exampleSentence: "Ask me anything.", exampleTranslation: "Питай мене про що завгодно.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_008", original: "believe", translation: "вірити", transcription: "/bɪˈliːv/", exampleSentence: "I believe in you.", exampleTranslation: "Я вірю в тебе.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_009", original: "belong", translation: "належати", transcription: "/bɪˈlɔːŋ/", exampleSentence: "This book belongs to me.", exampleTranslation: "Ця книга належить мені.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_010", original: "borrow", translation: "позичати", transcription: "/ˈbɔːroʊ/", exampleSentence: "Can I borrow your pen?", exampleTranslation: "Можна я позичу твою ручку?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_011", original: "call", translation: "дзвонити", transcription: "/kɔːl/", exampleSentence: "I will call you later.", exampleTranslation: "Я подзвоню тобі пізніше.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_012", original: "cancel", translation: "скасувати", transcription: "/ˈkænsl/", exampleSentence: "We had to cancel the meeting.", exampleTranslation: "Нам довелося скасувати зустріч.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_013", original: "change", translation: "змінювати", transcription: "/tʃeɪndʒ/", exampleSentence: "I need to change my clothes.", exampleTranslation: "Мені потрібно перевдягнутися.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_014", original: "clean", translation: "чистити", transcription: "/kliːn/", exampleSentence: "I need to clean my room.", exampleTranslation: "Мені потрібно прибрати в кімнаті.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_015", original: "close", translation: "закривати", transcription: "/kloʊz/", exampleSentence: "Please close the door.", exampleTranslation: "Будь ласка, закрий двері.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_016", original: "collect", translation: "збирати", transcription: "/kəˈlekt/", exampleSentence: "I collect stamps.", exampleTranslation: "Я збираю марки.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_017", original: "complain", translation: "скаржитися", transcription: "/kəmˈpleɪn/", exampleSentence: "Stop complaining!", exampleTranslation: "Перестань скаржитися!", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_018", original: "complete", translation: "завершувати", transcription: "/kəmˈpliːt/", exampleSentence: "I completed the task.", exampleTranslation: "Я завершив завдання.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_019", original: "continue", translation: "продовжувати", transcription: "/kənˈtɪnjuː/", exampleSentence: "Please continue speaking.", exampleTranslation: "Будь ласка, продовжуй говорити.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_020", original: "cook", translation: "готувати", transcription: "/kʊk/", exampleSentence: "I love to cook.", exampleTranslation: "Я люблю готувати.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_021", original: "copy", translation: "копіювати", transcription: "/ˈkɑːpi/", exampleSentence: "Copy this file.", exampleTranslation: "Скопіюй цей файл.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_022", original: "count", translation: "рахувати", transcription: "/kaʊnt/", exampleSentence: "Count to ten.", exampleTranslation: "Порахуй до десяти.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_023", original: "create", translation: "створювати", transcription: "/kriˈeɪt/", exampleSentence: "Create something beautiful.", exampleTranslation: "Створи щось красиве.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_024", original: "cross", translation: "перетинати", transcription: "/krɔːs/", exampleSentence: "Cross the street carefully.", exampleTranslation: "Переходь вулицю обережно.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_025", original: "dance", translation: "танцювати", transcription: "/dæns/", exampleSentence: "I love to dance.", exampleTranslation: "Я люблю танцювати.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_026", original: "decide", translation: "вирішувати", transcription: "/dɪˈsaɪd/", exampleSentence: "I decided to stay home.", exampleTranslation: "Я вирішив залишитися вдома.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_027", original: "deliver", translation: "доставляти", transcription: "/dɪˈlɪvər/", exampleSentence: "They deliver pizza.", exampleTranslation: "Вони доставляють піцу.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_028", original: "depend", translation: "залежати", transcription: "/dɪˈpend/", exampleSentence: "It depends on the weather.", exampleTranslation: "Це залежить від погоди.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_029", original: "describe", translation: "описувати", transcription: "/dɪˈskraɪb/", exampleSentence: "Describe what you saw.", exampleTranslation: "Опиши, що ти бачив.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_030", original: "design", translation: "проєктувати", transcription: "/dɪˈzaɪn/", exampleSentence: "I design websites.", exampleTranslation: "Я проєктую веб-сайти.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_031", original: "destroy", translation: "руйнувати", transcription: "/dɪˈstrɔɪ/", exampleSentence: "The fire destroyed the building.", exampleTranslation: "Пожежа зруйнувала будівлю.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_032", original: "develop", translation: "розвивати", transcription: "/dɪˈveləp/", exampleSentence: "We need to develop new skills.", exampleTranslation: "Нам потрібно розвивати нові навички.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_033", original: "die", translation: "помирати", transcription: "/daɪ/", exampleSentence: "Plants die without water.", exampleTranslation: "Рослини помирають без води.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_034", original: "discuss", translation: "обговорювати", transcription: "/dɪˈskʌs/", exampleSentence: "Let us discuss this issue.", exampleTranslation: "Давай обговоримо це питання.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_035", original: "divide", translation: "ділити", transcription: "/dɪˈvaɪd/", exampleSentence: "Divide the cake into pieces.", exampleTranslation: "Поділи торт на шматочки.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_036", original: "draw", translation: "малювати", transcription: "/drɔː/", exampleSentence: "I like to draw.", exampleTranslation: "Мені подобається малювати.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_037", original: "dress", translation: "одягатися", transcription: "/dres/", exampleSentence: "I need to dress up.", exampleTranslation: "Мені потрібно нарядитися.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_038", original: "drive", translation: "водити", transcription: "/draɪv/", exampleSentence: "I drive to work.", exampleTranslation: "Я їжджу на роботу.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_039", original: "drop", translation: "кидати", transcription: "/drɑːp/", exampleSentence: "Do not drop the glass.", exampleTranslation: "Не кидай склянку.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_040", original: "earn", translation: "заробляти", transcription: "/ɜːrn/", exampleSentence: "I earn enough money.", exampleTranslation: "Я заробляю достатньо грошей.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_041", original: "encourage", translation: "заохочувати", transcription: "/ɪnˈkɜːrɪdʒ/", exampleSentence: "Teachers encourage students.", exampleTranslation: "Вчителі заохочують учнів.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_042", original: "enjoy", translation: "насолоджуватися", transcription: "/ɪnˈdʒɔɪ/", exampleSentence: "I enjoy reading.", exampleTranslation: "Я насолоджуюся читанням.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_043", original: "enter", translation: "входити", transcription: "/ˈentər/", exampleSentence: "Please enter the room.", exampleTranslation: "Будь ласка, увійдіть до кімнати.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_044", original: "escape", translation: "втікати", transcription: "/ɪˈskeɪp/", exampleSentence: "The prisoner escaped.", exampleTranslation: "Вʼязень втік.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_045", original: "examine", translation: "оглядати", transcription: "/ɪɡˈzæmɪn/", exampleSentence: "The doctor examined the patient.", exampleTranslation: "Лікар оглянув пацієнта.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_046", original: "exist", translation: "існувати", transcription: "/ɪɡˈzɪst/", exampleSentence: "Do aliens exist?", exampleTranslation: "Чи існують інопланетяни?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_047", original: "expect", translation: "очікувати", transcription: "/ɪkˈspekt/", exampleSentence: "I expect good results.", exampleTranslation: "Я очікую хороших результатів.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_048", original: "explain", translation: "пояснювати", transcription: "/ɪkˈspleɪn/", exampleSentence: "Can you explain this?", exampleTranslation: "Можеш це пояснити?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_049", original: "explore", translation: "досліджувати", transcription: "/ɪkˈsplɔːr/", exampleSentence: "We love to explore new places.", exampleTranslation: "Ми любимо досліджувати нові місця.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_050", original: "fail", translation: "зазнавати невдачі", transcription: "/feɪl/", exampleSentence: "Do not be afraid to fail.", exampleTranslation: "Не бійся зазнати невдачі.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_051", original: "fix", translation: "ремонтувати", transcription: "/fɪks/", exampleSentence: "I need to fix my bike.", exampleTranslation: "Мені потрібно відремонтувати велосипед.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_052", original: "follow", translation: "слідувати", transcription: "/ˈfɑːloʊ/", exampleSentence: "Follow me.", exampleTranslation: "Слідуй за мною.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_053", original: "force", translation: "змушувати", transcription: "/fɔːrs/", exampleSentence: "Do not force me.", exampleTranslation: "Не змушуй мене.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_054", original: "forget", translation: "забувати", transcription: "/fərˈɡet/", exampleSentence: "I always forget his name.", exampleTranslation: "Я завжди забуваю його імʼя.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_055", original: "forgive", translation: "пробачати", transcription: "/fərˈɡɪv/", exampleSentence: "I forgive you.", exampleTranslation: "Я прощаю тебе.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_056", original: "form", translation: "формувати", transcription: "/fɔːrm/", exampleSentence: "We formed a team.", exampleTranslation: "Ми сформували команду.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_057", original: "found", translation: "засновувати", transcription: "/faʊnd/", exampleSentence: "He founded the company.", exampleTranslation: "Він заснував компанію.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_058", original: "gain", translation: "набувати", transcription: "/ɡeɪn/", exampleSentence: "I gained weight.", exampleTranslation: "Я набрав вагу.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_059", original: "gather", translation: "збирати", transcription: "/ˈɡæðər/", exampleSentence: "We gathered in the park.", exampleTranslation: "Ми зібралися в парку.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_060", original: "happen", translation: "траплятися", transcription: "/ˈhæpən/", exampleSentence: "What happened?", exampleTranslation: "Що трапилося?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_061", original: "hate", translation: "ненавидіти", transcription: "/heɪt/", exampleSentence: "I hate spiders.", exampleTranslation: "Я ненавиджу павуків.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_062", original: "hope", translation: "сподіватися", transcription: "/hoʊp/", exampleSentence: "I hope you feel better.", exampleTranslation: "Я сподіваюся, тобі краще.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_063", original: "imagine", translation: "уявляти", transcription: "/ɪˈmædʒɪn/", exampleSentence: "Imagine a better world.", exampleTranslation: "Уяви кращий світ.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_064", original: "improve", translation: "покращувати", transcription: "/ɪmˈpruːv/", exampleSentence: "I want to improve my English.", exampleTranslation: "Я хочу покращити свою англійську.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_065", original: "include", translation: "включати", transcription: "/ɪnˈkluːd/", exampleSentence: "The price includes tax.", exampleTranslation: "Ціна включає податок.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_066", original: "increase", translation: "збільшувати", transcription: "/ɪnˈkriːs/", exampleSentence: "Sales increased this year.", exampleTranslation: "Продажі збільшилися цього року.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_067", original: "influence", translation: "впливати", transcription: "/ˈɪnfluəns/", exampleSentence: "Parents influence their children.", exampleTranslation: "Батьки впливають на своїх дітей.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_068", original: "inform", translation: "інформувати", transcription: "/ɪnˈfɔːrm/", exampleSentence: "Please inform me of any changes.", exampleTranslation: "Будь ласка, повідомте мене про будь-які зміни.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_069", original: "introduce", translation: "представляти", transcription: "/ˌɪntrəˈdjuːs/", exampleSentence: "Let me introduce myself.", exampleTranslation: "Дозвольте представитися.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_070", original: "invite", translation: "запрошувати", transcription: "/ɪnˈvaɪt/", exampleSentence: "I want to invite you to dinner.", exampleTranslation: "Я хочу запросити тебе на вечерю.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_071", original: "join", translation: "приєднуватися", transcription: "/dʒɔɪn/", exampleSentence: "Join us for dinner.", exampleTranslation: "Приєднуйся до нас на вечерю.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_072", original: "jump", translation: "стрибати", transcription: "/dʒʌmp/", exampleSentence: "The cat jumped on the table.", exampleTranslation: "Кіт стрибнув на стіл.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_073", original: "kick", translation: "бити ногою", transcription: "/kɪk/", exampleSentence: "Do not kick the ball inside.", exampleTranslation: "Не бий мʼяч ногою всередині.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_074", original: "kiss", translation: "цілувати", transcription: "/kɪs/", exampleSentence: "She kissed her mother goodbye.", exampleTranslation: "Вона поцілувала маму на прощання.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_075", original: "laugh", translation: "сміятися", transcription: "/læf/", exampleSentence: "We laughed all night.", exampleTranslation: "Ми сміялися всю ніч.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_076", original: "learn", translation: "вчити", transcription: "/lɜːrn/", exampleSentence: "I want to learn Spanish.", exampleTranslation: "Я хочу вчити іспанську.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_077", original: "leave", translation: "залишати", transcription: "/liːv/", exampleSentence: "I need to leave now.", exampleTranslation: "Мені потрібно йти зараз.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_078", original: "lend", translation: "позичати", transcription: "/lend/", exampleSentence: "Can you lend me some money?", exampleTranslation: "Можеш позичити мені грошей?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_079", original: "lie", translation: "брехати", transcription: "/laɪ/", exampleSentence: "Do not lie to me.", exampleTranslation: "Не бреши мені.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_080", original: "lift", translation: "піднімати", transcription: "/lɪft/", exampleSentence: "Can you lift this box?", exampleTranslation: "Можеш підняти цю коробку?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_081", original: "limit", translation: "обмежувати", transcription: "/ˈlɪmɪt/", exampleSentence: "We need to limit our spending.", exampleTranslation: "Нам потрібно обмежити наші витрати.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_082", original: "link", translation: "звʼязувати", transcription: "/lɪŋk/", exampleSentence: "These events are linked.", exampleTranslation: "Ці події повʼязані.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_083", original: "list", translation: "перелічувати", transcription: "/lɪst/", exampleSentence: "List your favorite movies.", exampleTranslation: "Перелічи свої улюблені фільми.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_084", original: "lock", translation: "замикати", transcription: "/lɑːk/", exampleSentence: "Do not forget to lock the door.", exampleTranslation: "Не забудь замкнути двері.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_085", original: "look", translation: "дивитися", transcription: "/lʊk/", exampleSentence: "Look at that!", exampleTranslation: "Подивися на це!", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_086", original: "love", translation: "любити", transcription: "/lʌv/", exampleSentence: "I love you.", exampleTranslation: "Я люблю тебе.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_087", original: "maintain", translation: "підтримувати", transcription: "/meɪnˈteɪn/", exampleSentence: "We need to maintain our equipment.", exampleTranslation: "Нам потрібно підтримувати наше обладнання.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_088", original: "manage", translation: "керувати", transcription: "/ˈmænɪdʒ/", exampleSentence: "She manages a team of ten.", exampleTranslation: "Вона керує командою з десяти осіб.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_089", original: "matter", translation: "мати значення", transcription: "/ˈmætər/", exampleSentence: "It does not matter.", exampleTranslation: "Це не має значення.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_090", original: "measure", translation: "вимірювати", transcription: "/ˈmeʒər/", exampleSentence: "Measure the length.", exampleTranslation: "Виміряй довжину.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_091", original: "mention", translation: "згадувати", transcription: "/ˈmenʃn/", exampleSentence: "Did I mention that?", exampleTranslation: "Чи я згадував про це?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_092", original: "mind", translation: "заперечувати", transcription: "/maɪnd/", exampleSentence: "Do you mind if I open the window?", exampleTranslation: "Ти не заперечуєш, якщо я відкрию вікно?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_093", original: "miss", translation: "пропускати", transcription: "/mɪs/", exampleSentence: "I miss you.", exampleTranslation: "Я сумую за тобою.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_094", original: "mix", translation: "змішувати", transcription: "/mɪks/", exampleSentence: "Mix the ingredients.", exampleTranslation: "Змішай інгредієнти.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_095", original: "move", translation: "рухатися", transcription: "/muːv/", exampleSentence: "Please move your car.", exampleTranslation: "Будь ласка, пересунь свою машину.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_096", original: "need", translation: "потребувати", transcription: "/niːd/", exampleSentence: "I need help.", exampleTranslation: "Мені потрібна допомога.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_097", original: "notice", translation: "помічати", transcription: "/ˈnoʊtɪs/", exampleSentence: "Did you notice anything strange?", exampleTranslation: "Ти помітив щось дивне?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_098", original: "obey", translation: "підкорятися", transcription: "/oʊˈbeɪ/", exampleSentence: "You must obey the rules.", exampleTranslation: "Ти повинен підкорятися правилам.", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_099", original: "offer", translation: "пропонувати", transcription: "/ˈɔːfər/", exampleSentence: "Can I offer you some tea?", exampleTranslation: "Можу я запропонувати тобі чаю?", synonyms: [], difficulty: .a1, category: .verbs),
        Word(id: "verb_100", original: "open", translation: "відкривати", transcription: "/ˈoʊpən/", exampleSentence: "Please open the window.", exampleTranslation: "Будь ласка, відкрий вікно.", synonyms: [], difficulty: .a1, category: .verbs),
    ]

    static let irregularVerbsWords: [Word] = [
        Word(id: "irreg_001", original: "be - was/were - been", translation: "бути", transcription: "/biː/", exampleSentence: "I was happy. She has been there.", exampleTranslation: "Я був щасливий. Вона була там.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_002", original: "begin - began - begun", translation: "починати", transcription: "/bɪˈɡɪn/", exampleSentence: "The movie began at 8.", exampleTranslation: "Фільм почався о 8.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_003", original: "break - broke - broken", translation: "ламати", transcription: "/breɪk/", exampleSentence: "I broke my phone.", exampleTranslation: "Я зламав телефон.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_004", original: "bring - brought - brought", translation: "приносити", transcription: "/brɪŋ/", exampleSentence: "Bring your friend.", exampleTranslation: "Приведи свого друга.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_005", original: "build - built - built", translation: "будувати", transcription: "/bɪld/", exampleSentence: "They built a house.", exampleTranslation: "Вони побудували будинок.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_006", original: "buy - bought - bought", translation: "купувати", transcription: "/baɪ/", exampleSentence: "I bought a new car.", exampleTranslation: "Я купив нову машину.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_007", original: "catch - caught - caught", translation: "ловити", transcription: "/kætʃ/", exampleSentence: "Catch the ball!", exampleTranslation: "Лови мʼяч!", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_008", original: "choose - chose - chosen", translation: "вибирати", transcription: "/tʃuːz/", exampleSentence: "I chose the blue one.", exampleTranslation: "Я вибрав синій.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_009", original: "come - came - come", translation: "приходити", transcription: "/kʌm/", exampleSentence: "She came late.", exampleTranslation: "Вона прийшла пізно.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_010", original: "cost - cost - cost", translation: "коштувати", transcription: "/kɔːst/", exampleSentence: "It cost a lot.", exampleTranslation: "Це коштувало багато.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_011", original: "cut - cut - cut", translation: "різати", transcription: "/kʌt/", exampleSentence: "Cut the paper.", exampleTranslation: "Поріж папір.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_012", original: "do - did - done", translation: "робити", transcription: "/duː/", exampleSentence: "Have you done your homework?", exampleTranslation: "Ти зробив домашнє завдання?", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_013", original: "draw - drew - drawn", translation: "малювати", transcription: "/drɔː/", exampleSentence: "I drew a picture.", exampleTranslation: "Я намалював картинку.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_014", original: "drink - drank - drunk", translation: "пити", transcription: "/drɪŋk/", exampleSentence: "He drank all the water.", exampleTranslation: "Він випив всю воду.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_015", original: "drive - drove - driven", translation: "водити", transcription: "/draɪv/", exampleSentence: "I drove to work.", exampleTranslation: "Я поїхав на роботу.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_016", original: "eat - ate - eaten", translation: "їсти", transcription: "/iːt/", exampleSentence: "I ate breakfast.", exampleTranslation: "Я поснідав.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_017", original: "fall - fell - fallen", translation: "падати", transcription: "/fɔːl/", exampleSentence: "The leaves fall in autumn.", exampleTranslation: "Листя падає восени.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_018", original: "feel - felt - felt", translation: "почуватися", transcription: "/fiːl/", exampleSentence: "I feel great today.", exampleTranslation: "Я чудово почуваюся сьогодні.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_019", original: "fight - fought - fought", translation: "боротися", transcription: "/faɪt/", exampleSentence: "They fought bravely.", exampleTranslation: "Вони боролися мужньо.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_020", original: "find - found - found", translation: "знаходити", transcription: "/faɪnd/", exampleSentence: "I found my keys.", exampleTranslation: "Я знайшов свої ключі.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_021", original: "fly - flew - flown", translation: "літати", transcription: "/flaɪ/", exampleSentence: "The bird flew away.", exampleTranslation: "Птах полетів.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_022", original: "forget - forgot - forgotten", translation: "забувати", transcription: "/fərˈɡet/", exampleSentence: "I forgot my password.", exampleTranslation: "Я забув свій пароль.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_023", original: "forgive - forgave - forgiven", translation: "пробачати", transcription: "/fərˈɡɪv/", exampleSentence: "I forgave him.", exampleTranslation: "Я пробачив його.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_024", original: "freeze - froze - frozen", translation: "замерзати", transcription: "/friːz/", exampleSentence: "The water froze.", exampleTranslation: "Вода замерзла.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_025", original: "get - got - got/gotten", translation: "отримувати", transcription: "/ɡet/", exampleSentence: "I got a present.", exampleTranslation: "Я отримав подарунок.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_026", original: "give - gave - given", translation: "давати", transcription: "/ɡɪv/", exampleSentence: "She gave me a book.", exampleTranslation: "Вона дала мені книгу.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_027", original: "go - went - gone", translation: "йти", transcription: "/ɡoʊ/", exampleSentence: "He went home early.", exampleTranslation: "Він пішов додому рано.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_028", original: "grow - grew - grown", translation: "рости", transcription: "/ɡroʊ/", exampleSentence: "Plants grow fast.", exampleTranslation: "Рослини ростуть швидко.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_029", original: "have - had - had", translation: "мати", transcription: "/hæv/", exampleSentence: "I had a good time.", exampleTranslation: "Я добре провів час.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_030", original: "hear - heard - heard", translation: "чути", transcription: "/hɪr/", exampleSentence: "I heard a noise.", exampleTranslation: "Я почув шум.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_031", original: "hide - hid - hidden", translation: "ховати", transcription: "/haɪd/", exampleSentence: "Hide and seek!", exampleTranslation: "Хованки!", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_032", original: "hit - hit - hit", translation: "бити", transcription: "/hɪt/", exampleSentence: "Do not hit the dog.", exampleTranslation: "Не бий собаку.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_033", original: "hold - held - held", translation: "тримати", transcription: "/hoʊld/", exampleSentence: "Hold my hand.", exampleTranslation: "Тримай мою руку.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_034", original: "hurt - hurt - hurt", translation: "боліти", transcription: "/hɜːrt/", exampleSentence: "My leg hurts.", exampleTranslation: "Моя нога болить.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_035", original: "keep - kept - kept", translation: "тримати", transcription: "/kiːp/", exampleSentence: "Keep the change.", exampleTranslation: "Залиште решту собі.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_036", original: "know - knew - known", translation: "знати", transcription: "/noʊ/", exampleSentence: "I knew him before.", exampleTranslation: "Я знав його раніше.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_037", original: "lead - led - led", translation: "вести", transcription: "/liːd/", exampleSentence: "He led the team.", exampleTranslation: "Він вів команду.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_038", original: "leave - left - left", translation: "залишати", transcription: "/liːv/", exampleSentence: "I left my bag at home.", exampleTranslation: "Я залишив сумку вдома.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_039", original: "lend - lent - lent", translation: "позичати", transcription: "/lend/", exampleSentence: "Can you lend me money?", exampleTranslation: "Можеш позичити мені гроші?", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_040", original: "let - let - let", translation: "дозволяти", transcription: "/let/", exampleSentence: "Let me help you.", exampleTranslation: "Дозволь мені допомогти.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_041", original: "lie - lay - lain", translation: "лежати", transcription: "/laɪ/", exampleSentence: "The book lay on the table.", exampleTranslation: "Книга лежала на столі.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_042", original: "lose - lost - lost", translation: "втрачати", transcription: "/luːz/", exampleSentence: "I lost my wallet.", exampleTranslation: "Я загубив гаманець.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_043", original: "make - made - made", translation: "робити", transcription: "/meɪk/", exampleSentence: "I made a mistake.", exampleTranslation: "Я зробив помилку.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_044", original: "mean - meant - meant", translation: "означати", transcription: "/miːn/", exampleSentence: "What does this word mean?", exampleTranslation: "Що означає це слово?", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_045", original: "meet - met - met", translation: "зустрічати", transcription: "/miːt/", exampleSentence: "Nice to meet you.", exampleTranslation: "Приємно познайомитись.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_046", original: "pay - paid - paid", translation: "платити", transcription: "/peɪ/", exampleSentence: "I paid the bill.", exampleTranslation: "Я оплатив рахунок.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_047", original: "put - put - put", translation: "класти", transcription: "/pʊt/", exampleSentence: "Put it on the table.", exampleTranslation: "Поклади це на стіл.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_048", original: "read - read - read", translation: "читати", transcription: "/riːd/", exampleSentence: "I read a book yesterday.", exampleTranslation: "Я прочитав книгу вчора.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_049", original: "ride - rode - ridden", translation: "їздити", transcription: "/raɪd/", exampleSentence: "I rode a bike.", exampleTranslation: "Я їздив на велосипеді.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_050", original: "ring - rang - rung", translation: "дзвонити", transcription: "/rɪŋ/", exampleSentence: "The phone rang.", exampleTranslation: "Телефон задзвонив.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_051", original: "rise - rose - risen", translation: "підніматися", transcription: "/raɪz/", exampleSentence: "The sun rose.", exampleTranslation: "Сонце сходило.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_052", original: "run - ran - run", translation: "бігти", transcription: "/rʌn/", exampleSentence: "I ran five kilometers.", exampleTranslation: "Я пробіг пʼять кілометрів.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_053", original: "say - said - said", translation: "казати", transcription: "/seɪ/", exampleSentence: "She said hello.", exampleTranslation: "Вона сказала привіт.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_054", original: "see - saw - seen", translation: "бачити", transcription: "/siː/", exampleSentence: "I saw a movie.", exampleTranslation: "Я подивився фільм.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_055", original: "sell - sold - sold", translation: "продавати", transcription: "/sel/", exampleSentence: "I sold my car.", exampleTranslation: "Я продав свою машину.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_056", original: "send - sent - sent", translation: "надсилати", transcription: "/send/", exampleSentence: "I sent an email.", exampleTranslation: "Я надіслав листа.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_057", original: "set - set - set", translation: "встановлювати", transcription: "/set/", exampleSentence: "Set the table.", exampleTranslation: "Накрий на стіл.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_058", original: "shake - shook - shaken", translation: "трусити", transcription: "/ʃeɪk/", exampleSentence: "Shake hands.", exampleTranslation: "Потисни руку.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_059", original: "shine - shone - shone", translation: "світити", transcription: "/ʃaɪn/", exampleSentence: "The sun shone brightly.", exampleTranslation: "Сонце яскраво світило.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_060", original: "shoot - shot - shot", translation: "стріляти", transcription: "/ʃuːt/", exampleSentence: "He shot the ball.", exampleTranslation: "Він кинув мʼяч.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_061", original: "show - showed - shown", translation: "показувати", transcription: "/ʃoʊ/", exampleSentence: "Show me your photos.", exampleTranslation: "Покажи мені свої фото.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_062", original: "shut - shut - shut", translation: "зачиняти", transcription: "/ʃʌt/", exampleSentence: "Shut the door.", exampleTranslation: "Зачиніть двері.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_063", original: "sing - sang - sung", translation: "співати", transcription: "/sɪŋ/", exampleSentence: "She sang beautifully.", exampleTranslation: "Вона чудово співала.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_064", original: "sink - sank - sunk", translation: "тонути", transcription: "/sɪŋk/", exampleSentence: "The ship sank.", exampleTranslation: "Корабель затонув.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_065", original: "sit - sat - sat", translation: "сидіти", transcription: "/sɪt/", exampleSentence: "Please sit down.", exampleTranslation: "Будь ласка, сідай.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_066", original: "sleep - slept - slept", translation: "спати", transcription: "/sliːp/", exampleSentence: "I slept well last night.", exampleTranslation: "Я добре спав минулої ночі.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_067", original: "speak - spoke - spoken", translation: "говорити", transcription: "/spiːk/", exampleSentence: "I spoke to the manager.", exampleTranslation: "Я поговорив з менеджером.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_068", original: "spend - spent - spent", translation: "витрачати", transcription: "/spend/", exampleSentence: "I spent all my money.", exampleTranslation: "Я витратив всі гроші.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_069", original: "stand - stood - stood", translation: "стояти", transcription: "/stænd/", exampleSentence: "Please stand up.", exampleTranslation: "Будь ласка, встань.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_070", original: "steal - stole - stolen", translation: "красти", transcription: "/stiːl/", exampleSentence: "Someone stole my bike.", exampleTranslation: "Хтось вкрав мій велосипед.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_071", original: "stick - stuck - stuck", translation: "приклеювати", transcription: "/stɪk/", exampleSentence: "The door stuck.", exampleTranslation: "Двері заїли.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_072", original: "strike - struck - struck", translation: "вдаряти", transcription: "/straɪk/", exampleSentence: "Lightning struck the tree.", exampleTranslation: "Блискавка вдарила в дерево.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_073", original: "swim - swam - swum", translation: "плавати", transcription: "/swɪm/", exampleSentence: "I swam in the lake.", exampleTranslation: "Я плавав у озері.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_074", original: "take - took - taken", translation: "брати", transcription: "/teɪk/", exampleSentence: "I took the bus.", exampleTranslation: "Я сів на автобус.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_075", original: "teach - taught - taught", translation: "вчити", transcription: "/tiːtʃ/", exampleSentence: "She teaches English.", exampleTranslation: "Вона викладає англійську.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_076", original: "tear - tore - torn", translation: "рвати", transcription: "/ter/", exampleSentence: "I tore the paper.", exampleTranslation: "Я порвав папір.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_077", original: "tell - told - told", translation: "розповідати", transcription: "/tel/", exampleSentence: "Tell me a story.", exampleTranslation: "Розкажи мені історію.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_078", original: "think - thought - thought", translation: "думати", transcription: "/θɪŋk/", exampleSentence: "I think so.", exampleTranslation: "Я так думаю.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_079", original: "throw - threw - thrown", translation: "кидати", transcription: "/θroʊ/", exampleSentence: "Throw the ball.", exampleTranslation: "Кинь мʼяч.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_080", original: "understand - understood - understood", translation: "розуміти", transcription: "/ˌʌndərˈstænd/", exampleSentence: "I do not understand.", exampleTranslation: "Я не розумію.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_081", original: "wake - woke - woken", translation: "прокидатися", transcription: "/weɪk/", exampleSentence: "I woke up early.", exampleTranslation: "Я прокинувся рано.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_082", original: "wear - wore - worn", translation: "носити", transcription: "/wer/", exampleSentence: "I wore a red dress.", exampleTranslation: "Я носила червону сукню.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_083", original: "win - won - won", translation: "перемагати", transcription: "/wɪn/", exampleSentence: "We won the game.", exampleTranslation: "Ми виграли гру.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
        Word(id: "irreg_084", original: "write - wrote - written", translation: "писати", transcription: "/raɪt/", exampleSentence: "I wrote a letter.", exampleTranslation: "Я написав листа.", synonyms: [], difficulty: .a1, category: .irregularVerbs),
    ]

// MARK: - Helper Methods
    
    static var allWords: [Word] {
        a1Words + a2Words + b1Words + b2Words + c1Words + c2Words +
        foodWords + travelWords + workWords + emotionsWords + familyWords +
        shoppingWords + healthWords + technologyWords + natureWords +
        educationWords + businessWords + hobbiesWords + socialWords + homeWords +
        verbsWords + irregularVerbsWords
    }
    
    static func words(for category: WordCategory) -> [Word] {
        switch category {
        case .basics:
            // Return all A1-A2 words sorted alphabetically
            return (a1Words + a2Words).sorted { $0.original.lowercased() < $1.original.lowercased() }
        case .food:
            return foodWords
        case .travel:
            return travelWords
        case .work:
            return workWords
        case .emotions:
            return emotionsWords
        case .family:
            return familyWords
        case .shopping:
            return shoppingWords
        case .health:
            return healthWords
        case .technology:
            return technologyWords
        case .nature:
            return natureWords
        case .education:
            return educationWords
        case .business:
            return businessWords
        case .hobbies:
            return hobbiesWords
        case .social:
            return socialWords
        case .home:
            return homeWords
        case .verbs:
            return verbsWords
        case .irregularVerbs:
            return irregularVerbsWords
        }
    }
    
    static func words(for difficulty: DifficultyLevel) -> [Word] {
        switch difficulty {
        case .a1: return a1Words
        case .a2: return a2Words
        case .b1: return b1Words
        case .b2: return b2Words
        case .c1: return c1Words
        case .c2: return c2Words
        }
    }
    
    static func searchWords(query: String) -> [Word] {
        let lowerQuery = query.lowercased()
        return allWords.filter { word in
            word.original.lowercased().contains(lowerQuery) ||
            word.translation.lowercased().contains(lowerQuery)
        }
    }
    
    static var allSets: [WordSet] {
        [
            WordSet(
                id: "a1_basics",
                titleKey: "A1 Basics",
                titleLocalized: ["en": "A1 Basics", "uk": "A1 Основи", "pl": "A1 Podstawy"],
                emoji: "🌱",
                gradientColors: ["#4CAF50", "#8BC34A"],
                difficulty: .a1,
                category: .basics,
                wordCount: a1Words.count,
                words: a1Words
            ),
            WordSet(
                id: "a2_elementary",
                titleKey: "A2 Elementary",
                titleLocalized: ["en": "A2 Elementary", "uk": "A2 Елементарний", "pl": "A2 Elementarny"],
                emoji: "📗",
                gradientColors: ["#2196F3", "#03A9F4"],
                difficulty: .a2,
                category: .basics,
                wordCount: a2Words.count,
                words: a2Words
            ),
            WordSet(
                id: "b1_intermediate",
                titleKey: "B1 Intermediate",
                titleLocalized: ["en": "B1 Intermediate", "uk": "B1 Середній", "pl": "B1 Średniozaawansowany"],
                emoji: "📘",
                gradientColors: ["#9C27B0", "#E91E63"],
                difficulty: .b1,
                category: .basics,
                wordCount: b1Words.count,
                words: b1Words
            ),
            WordSet(
                id: "b2_upper_intermediate",
                titleKey: "B2 Upper-Intermediate",
                titleLocalized: ["en": "B2 Upper-Intermediate", "uk": "B2 Вище середнього", "pl": "B2 Zaawansowany"],
                emoji: "📙",
                gradientColors: ["#FF9800", "#FFC107"],
                difficulty: .b2,
                category: .basics,
                wordCount: b2Words.count,
                words: b2Words
            ),
            WordSet(
                id: "c1_advanced",
                titleKey: "C1 Advanced",
                titleLocalized: ["en": "C1 Advanced", "uk": "C1 Просунутий", "pl": "C1 Zaawansowany"],
                emoji: "📕",
                gradientColors: ["#F44336", "#FF5722"],
                difficulty: .c1,
                category: .basics,
                wordCount: c1Words.count,
                words: c1Words
            ),
            WordSet(
                id: "c2_proficiency",
                titleKey: "C2 Proficiency",
                titleLocalized: ["en": "C2 Proficiency", "uk": "C2 Вільне володіння", "pl": "C2 Biegłość"],
                emoji: "👑",
                gradientColors: ["#E91E63", "#9C27B0"],
                difficulty: .c2,
                category: .basics,
                wordCount: c2Words.count,
                words: c2Words
            )
        ]
    }
}

struct PresetWord: Identifiable, Codable {
    let id: String
    let original: String
    let translation: String
    let transcription: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let synonyms: [String]
    let languagePair: String
    let generatedAt: Date
    let aiModel: String
}

struct GeneratedWordSet: Codable {
    let id: String
    let title: String
    let description: String
    let words: [PresetWord]
    let languagePair: String
    let difficulty: DifficultyLevel
    let createdAt: Date
    let generationCost: Double
    let estimatedQuality: Double
}

struct ExportedSet: Codable {
    let version: String
    let exportDate: Date
    let setData: WordSetExport
    let statistics: SetStatistics
    
    init(version: String = "1.0", exportDate: Date = Date(), setData: WordSetExport, statistics: SetStatistics) {
        self.version = version
        self.exportDate = exportDate
        self.setData = setData
        self.statistics = statistics
    }
    
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

struct WordSetExport: Codable {
    let title: String
    let description: String
    let languagePair: String
    let difficulty: String
    let words: [ExportedWord]
    let tags: [String]
    let customPrompt: String?
}

struct ExportedWord: Codable {
    let original: String
    let translation: String
    let transcription: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let synonyms: [String]
    let notes: String?
}

struct SetStatistics: Codable {
    let totalRatings: Int
    let averageRating: Double
    let downloadCount: Int
    let usageCount: Int
}

struct CommunityWordSet: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let authorName: String
    let authorAvatar: String?
    let downloadCount: Int
    let averageRating: Double
    let ratingCount: Int
    let languagePair: String
    let difficulty: DifficultyLevel
    let wordCount: Int
    let tags: [String]
    let createdAt: Date
}

enum WordRating: Int, Codable {
    case poor = 1
    case okay = 2
    case good = 3
    case excellent = 4
    case native = 5
    
    var label: String {
        switch self {
        case .poor: return "Needs improvement"
        case .okay: return "Acceptable"
        case .good: return "Good"
        case .excellent: return "Excellent!"
        case .native: return "Perfect (native level)"
        }
    }
}

// MARK: - User Dictionary Manager
class UserDictionaryManager: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = ObservableObjectPublisher()
    
    static let shared = UserDictionaryManager()
    private let userDefaultsKey = "userDictionaryWords"
    private let customSetsKey = "userCustomSets"
    
    @Published private(set) var userWords: [Word]
    @Published var customSets: [WordSet]
    
    private init() {
        // Initialize with persisted values without calling instance methods before self is initialized
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([Word].self, from: data) {
            self.userWords = decoded
        } else {
            self.userWords = []
        }
        
        if let data = UserDefaults.standard.data(forKey: customSetsKey),
           let decoded = try? JSONDecoder().decode([WordSet].self, from: data) {
            self.customSets = decoded
        } else {
            self.customSets = []
        }
    }
    // MARK: - User Words Management
    
    func addWord(_ word: Word) {
        // Generate new ID to avoid conflicts with predefined words
        var newWord = word
        newWord = Word(
            id: "user_\(UUID().uuidString)",
            original: word.original,
            translation: word.translation,
            transcription: word.transcription,
            exampleSentence: word.exampleSentence,
            exampleTranslation: word.exampleTranslation,
            synonyms: word.synonyms,
            difficulty: word.difficulty,
            audioUrl: word.audioUrl
        )
        
        userWords.append(newWord)
        saveUserWords()
    }
    
    func removeWord(withId id: String) {
        userWords.removeAll { $0.id == id }
        saveUserWords()
        
        // Also remove from custom sets if present
        for i in customSets.indices {
            if let index = customSets[i].words.firstIndex(where: { $0.id == id }) {
                var updatedSet = customSets[i]
                let updatedWords = updatedSet.words.enumerated().filter { $0.offset != index }.map { $0.element }
                customSets[i] = WordSet(
                    id: updatedSet.id,
                    titleKey: updatedSet.titleKey,
                    titleLocalized: updatedSet.titleLocalized,
                    emoji: updatedSet.emoji,
                    gradientColors: updatedSet.gradientColors,
                    difficulty: updatedSet.difficulty,
                    category: updatedSet.category,
                    wordCount: updatedWords.count,
                    words: updatedWords
                )
            }
        }
        saveCustomSets()
    }
    
    func updateWord(_ word: Word) {
        if let index = userWords.firstIndex(where: { $0.id == word.id }) {
            userWords[index] = word
            saveUserWords()
        }
    }
    
    func searchUserWords(query: String) -> [Word] {
        let lowercasedQuery = query.lowercased()
        return userWords.filter { word in
            word.original.lowercased().contains(lowercasedQuery) ||
            word.translation.lowercased().contains(lowercasedQuery) ||
            word.synonyms.contains(where: { $0.lowercased().contains(lowercasedQuery) })
        }
    }
    
    func getWordsByDifficulty(_ difficulty: DifficultyLevel) -> [Word] {
        return userWords.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Custom Sets Management
    
    func createCustomSet(title: String, emoji: String, gradientColors: [String], category: WordCategory, words: [Word]) -> WordSet {
        let setId = "custom_\(UUID().uuidString)"
        let titleKey = "custom_set_\(setId)"
        
        // Create localized title
        var titleLocalized: [String: String] = [:]
        let availableLanguages = ["en", "uk", "de", "fr", "es", "pl"]
        for lang in availableLanguages {
            titleLocalized[lang] = title
        }
        
        let newSet = WordSet(
            id: setId,
            titleKey: titleKey,
            titleLocalized: titleLocalized,
            emoji: emoji,
            gradientColors: gradientColors,
            difficulty: .a1, // Default, will be calculated
            category: category,
            wordCount: words.count,
            words: words
        )
        
        customSets.append(newSet)
        saveCustomSets()
        return newSet
    }
    
    func deleteCustomSet(withId id: String) {
        customSets.removeAll { $0.id == id }
        saveCustomSets()
    }
    
    func addWordToSet(wordId: String, setId: String) {
        guard let word = (userWords + PredefinedWordSets.allWords).first(where: { $0.id == wordId }),
              let setIndex = customSets.firstIndex(where: { $0.id == setId }) else { return }
        
        // Check if word already in set
        guard !customSets[setIndex].words.contains(where: { $0.id == wordId }) else { return }
        
        var updatedSet = customSets[setIndex]
        let updatedWords = updatedSet.words + [word]
        
        customSets[setIndex] = WordSet(
            id: updatedSet.id,
            titleKey: updatedSet.titleKey,
            titleLocalized: updatedSet.titleLocalized,
            emoji: updatedSet.emoji,
            gradientColors: updatedSet.gradientColors,
            difficulty: updatedSet.difficulty,
            category: updatedSet.category,
            wordCount: updatedWords.count,
            words: updatedWords
        )
        
        saveCustomSets()
    }
    
    func removeWordFromSet(wordId: String, setId: String) {
        guard let setIndex = customSets.firstIndex(where: { $0.id == setId }) else { return }
        
        var updatedSet = customSets[setIndex]
        let updatedWords = updatedSet.words.filter { $0.id != wordId }
        
        customSets[setIndex] = WordSet(
            id: updatedSet.id,
            titleKey: updatedSet.titleKey,
            titleLocalized: updatedSet.titleLocalized,
            emoji: updatedSet.emoji,
            gradientColors: updatedSet.gradientColors,
            difficulty: updatedSet.difficulty,
            category: updatedSet.category,
            wordCount: updatedWords.count,
            words: updatedWords
        )
        
        saveCustomSets()
    }
    
    func updateCustomSet(_ set: WordSet) {
        if let index = customSets.firstIndex(where: { $0.id == set.id }) {
            customSets[index] = set
            saveCustomSets()
        }
    }
    
    // MARK: - Import/Export
    
    func exportUserWords() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(userWords),
              let jsonString = String(data: data, encoding: .utf8) else { return nil }
        return jsonString
    }
    
    func importUserWords(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let words = try? JSONDecoder().decode([Word].self, from: data) else { return false }
        
        // Merge with existing, avoiding duplicates by original word
        let existingOriginals = Set(userWords.map { $0.original.lowercased() })
        let newWords = words.filter { !existingOriginals.contains($0.original.lowercased()) }
        
        // Regenerate IDs to ensure uniqueness
        let importedWords = newWords.map { word in
            Word(
                id: "user_imported_\(UUID().uuidString)",
                original: word.original,
                translation: word.translation,
                transcription: word.transcription,
                exampleSentence: word.exampleSentence,
                exampleTranslation: word.exampleTranslation,
                synonyms: word.synonyms,
                difficulty: word.difficulty,
                audioUrl: word.audioUrl
            )
        }
        
        userWords.append(contentsOf: importedWords)
        saveUserWords()
        return true
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> UserDictionaryStats {
        let totalWords = userWords.count
        let byDifficulty = Dictionary(grouping: userWords, by: { $0.difficulty })
            .mapValues { $0.count }
        
        let totalCustomSets = customSets.count
        let totalWordsInSets = customSets.reduce(0) { $0 + $1.wordCount }
        
        return UserDictionaryStats(
            totalWords: totalWords,
            wordsByDifficulty: byDifficulty,
            totalCustomSets: totalCustomSets,
            totalWordsInCustomSets: totalWordsInSets,
            lastAddedDate: getLastAddedDate()
        )
    }
    
    // MARK: - Private Persistence Methods
    
    private func saveUserWords() {
        if let encoded = try? JSONEncoder().encode(userWords) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadUserWords() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else { return }
        userWords = decoded
    }
    
    func saveCustomSets() {
        if let encoded = try? JSONEncoder().encode(customSets) {
            UserDefaults.standard.set(encoded, forKey: customSetsKey)
        }
    }
    
    func loadCustomSets() {
        guard let data = UserDefaults.standard.data(forKey: customSetsKey),
              let decoded = try? JSONDecoder().decode([WordSet].self, from: data) else { return }
        customSets = decoded
    }
    
    private func getLastAddedDate() -> Date? {
        // Implementation would track last added date if needed
        return nil
    }
    
    // MARK: - Reset
    
    func resetAllUserData() {
        userWords.removeAll()
        customSets.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: customSetsKey)
    }
}

// MARK: - Statistics Model
struct UserDictionaryStats {
    let totalWords: Int
    let wordsByDifficulty: [DifficultyLevel: Int]
    let totalCustomSets: Int
    let totalWordsInCustomSets: Int
    let lastAddedDate: Date?
    
    var totalItems: Int {
        totalWords + totalWordsInCustomSets
    }
}

// MARK: - Word Extension for User Management
extension Word {
    func withUpdatedTranslation(_ newTranslation: String) -> Word {
        Word(
            id: id,
            original: original,
            translation: newTranslation,
            transcription: transcription,
            exampleSentence: exampleSentence,
            exampleTranslation: exampleTranslation,
            synonyms: synonyms,
            difficulty: difficulty,
            audioUrl: audioUrl
        )
    }
    
    func withUpdatedFields(newTranslation: String? = nil,
                           sentence: String? = nil,
                           exampleTranslation: String? = nil) -> Word {
        Word(
            id: id,
            original: original,
            translation: newTranslation ?? translation,
            transcription: transcription,
            exampleSentence: sentence,
            exampleTranslation: exampleTranslation,
            synonyms: synonyms,
            difficulty: difficulty,
            audioUrl: audioUrl
        )
    }
}

extension Date {
    var iso8601String: String {
        ISO8601DateFormatter().string(from: self)
    }
}
