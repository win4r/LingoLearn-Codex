//
//  ContentView.swift
//  LingoLearn
//
//  Created by charles qin on 12/19/25.
//

import SwiftUI
import SwiftData
import AVFoundation
import Charts
import UserNotifications
import UniformTypeIdentifiers
import UIKit
import Combine

enum WordStatus: Int, CaseIterable {
    case new = 0
    case learning = 1
    case mastered = 2

    var label: String {
        switch self {
        case .new:
            return "New"
        case .learning:
            return "Learning"
        case .mastered:
            return "Mastered"
        }
    }

    var color: Color {
        switch self {
        case .new:
            return Color.warmBlue
        case .learning:
            return Color.freshGreen
        case .mastered:
            return Color.orange
        }
    }
}

enum WordLevel: Int, CaseIterable {
    case basic = 0
    case intermediate = 1
    case advanced = 2

    var label: String {
        switch self {
        case .basic:
            return "Basic"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }
}

enum PracticeType: Int, CaseIterable, Identifiable {
    case choiceWordToDefinition = 0
    case choiceDefinitionToWord = 1
    case fillBlank = 2
    case listening = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .choiceWordToDefinition:
            return "Word to Meaning"
        case .choiceDefinitionToWord:
            return "Meaning to Word"
        case .fillBlank:
            return "Fill in the Blank"
        case .listening:
            return "Listening"
        }
    }

    var subtitle: String {
        switch self {
        case .choiceWordToDefinition:
            return "Pick the correct meaning"
        case .choiceDefinitionToWord:
            return "Pick the correct word"
        case .fillBlank:
            return "Type the missing word"
        case .listening:
            return "Hear it and choose"
        }
    }

    var icon: String {
        switch self {
        case .choiceWordToDefinition:
            return "text.book.closed"
        case .choiceDefinitionToWord:
            return "text.magnifyingglass"
        case .fillBlank:
            return "square.and.pencil"
        case .listening:
            return "ear"
        }
    }
}

enum ThemeMode: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .system:
            return "System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum FontScale: Int, CaseIterable, Identifiable {
    case small = 0
    case medium = 1
    case large = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .small:
            return "Small"
        case .medium:
            return "Medium"
        case .large:
            return "Large"
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        }
    }
}

enum SpeechRateOption: Int, CaseIterable, Identifiable {
    case slow = 0
    case normal = 1
    case fast = 2

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .slow:
            return "Slow"
        case .normal:
            return "Normal"
        case .fast:
            return "Fast"
        }
    }

    var rate: Float {
        switch self {
        case .slow:
            return AVSpeechUtteranceDefaultSpeechRate * 0.6
        case .normal:
            return AVSpeechUtteranceDefaultSpeechRate
        case .fast:
            return AVSpeechUtteranceDefaultSpeechRate * 1.3
        }
    }
}

enum AchievementKind: Int, CaseIterable {
    case studyDays = 0
    case vocabMastered = 1
    case correctStreak = 2
}

extension Color {
    static let warmBlue = Color(red: 0.2, green: 0.45, blue: 0.85)
    static let freshGreen = Color(red: 0.2, green: 0.75, blue: 0.45)
}

@Model
final class Word: Identifiable {
    @Attribute(.unique) var id: UUID
    var term: String
    var phonetic: String
    var partOfSpeech: String
    var definition: String
    var example: String
    var levelRaw: Int
    var statusRaw: Int
    var isFavorite: Bool
    var correctCount: Int
    var incorrectCount: Int
    var lastReviewed: Date?

    init(
        term: String,
        phonetic: String,
        partOfSpeech: String,
        definition: String,
        example: String,
        level: WordLevel
    ) {
        self.id = UUID()
        self.term = term
        self.phonetic = phonetic
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.example = example
        self.levelRaw = level.rawValue
        self.statusRaw = WordStatus.new.rawValue
        self.isFavorite = false
        self.correctCount = 0
        self.incorrectCount = 0
        self.lastReviewed = nil
    }

    var status: WordStatus {
        get { WordStatus(rawValue: statusRaw) ?? .new }
        set { statusRaw = newValue.rawValue }
    }

    var level: WordLevel {
        get { WordLevel(rawValue: levelRaw) ?? .basic }
        set { levelRaw = newValue.rawValue }
    }
}

@Model
final class PracticeAttempt: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var duration: TimeInterval
    var isCorrect: Bool
    var typeRaw: Int
    @Relationship(deleteRule: .nullify) var word: Word?

    init(date: Date, duration: TimeInterval, isCorrect: Bool, type: PracticeType, word: Word?) {
        self.id = UUID()
        self.date = date
        self.duration = duration
        self.isCorrect = isCorrect
        self.typeRaw = type.rawValue
        self.word = word
    }

    var type: PracticeType {
        get { PracticeType(rawValue: typeRaw) ?? .choiceWordToDefinition }
        set { typeRaw = newValue.rawValue }
    }
}

@Model
final class DailyStats: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var learnedCount: Int
    var correctCount: Int
    var totalCount: Int
    var studySeconds: TimeInterval

    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.learnedCount = 0
        self.correctCount = 0
        self.totalCount = 0
        self.studySeconds = 0
    }

    var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }
}

@Model
final class Achievement: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var iconName: String
    var kindRaw: Int
    var targetValue: Int
    var isEarned: Bool
    var achievedAt: Date?

    init(title: String, detail: String, iconName: String, kind: AchievementKind, targetValue: Int) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.kindRaw = kind.rawValue
        self.targetValue = targetValue
        self.isEarned = false
        self.achievedAt = nil
    }

    var kind: AchievementKind {
        get { AchievementKind(rawValue: kindRaw) ?? .studyDays }
        set { kindRaw = newValue.rawValue }
    }
}

@Model
final class UserSettings: Identifiable {
    @Attribute(.unique) var id: UUID
    var dailyGoal: Int?
    var reminderHour: Int?
    var reminderMinute: Int?
    var speechRateRaw: Int?
    var autoPlay: Bool?
    var themeModeRaw: Int?
    var fontScaleRaw: Int?
    var notificationsEnabled: Bool?
    var correctStreak: Int?

    init(
        dailyGoal: Int = 20,
        reminderHour: Int = 20,
        reminderMinute: Int = 0,
        speechRate: SpeechRateOption = .normal,
        autoPlay: Bool = true,
        themeMode: ThemeMode = .system,
        fontScale: FontScale = .medium,
        notificationsEnabled: Bool = false,
        correctStreak: Int = 0
    ) {
        self.id = UUID()
        self.dailyGoal = dailyGoal
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.speechRateRaw = speechRate.rawValue
        self.autoPlay = autoPlay
        self.themeModeRaw = themeMode.rawValue
        self.fontScaleRaw = fontScale.rawValue
        self.notificationsEnabled = notificationsEnabled
        self.correctStreak = correctStreak
    }

    var speechRate: SpeechRateOption {
        get { SpeechRateOption(rawValue: speechRateRaw ?? SpeechRateOption.normal.rawValue) ?? .normal }
        set { speechRateRaw = newValue.rawValue }
    }

    var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRaw ?? ThemeMode.system.rawValue) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }

    var fontScale: FontScale {
        get { FontScale(rawValue: fontScaleRaw ?? FontScale.medium.rawValue) ?? .medium }
        set { fontScaleRaw = newValue.rawValue }
    }

    var preferredColorScheme: ColorScheme? {
        themeMode.preferredColorScheme
    }

    var dynamicTypeSize: DynamicTypeSize {
        fontScale.dynamicTypeSize
    }

    var reminderDate: Date {
        get {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = reminderHour ?? 20
            components.minute = reminderMinute ?? 0
            return calendar.date(from: components) ?? Date()
        }
        set {
            let calendar = Calendar.current
            reminderHour = calendar.component(.hour, from: newValue)
            reminderMinute = calendar.component(.minute, from: newValue)
        }
    }

    var reminderComponents: DateComponents {
        var components = DateComponents()
        components.hour = reminderHour ?? 20
        components.minute = reminderMinute ?? 0
        return components
    }
}

struct SeedWord: Codable, Hashable {
    let term: String
    let phonetic: String
    let partOfSpeech: String
    let definition: String
    let example: String
    let levelRaw: Int
}

enum SeedData {
    static let words: [SeedWord] = [
        SeedWord(term: "time", phonetic: "/taɪm/", partOfSpeech: "n.", definition: "时间", example: "Time moves quickly when you are busy.", levelRaw: 0),
        SeedWord(term: "people", phonetic: "/ˈpiːpəl/", partOfSpeech: "n.", definition: "人们", example: "People gather in the park on weekends.", levelRaw: 0),
        SeedWord(term: "year", phonetic: "/jɪr/", partOfSpeech: "n.", definition: "年", example: "This year is full of new goals.", levelRaw: 0),
        SeedWord(term: "day", phonetic: "/deɪ/", partOfSpeech: "n.", definition: "天", example: "She studies English every day.", levelRaw: 0),
        SeedWord(term: "man", phonetic: "/mæn/", partOfSpeech: "n.", definition: "男人", example: "The man smiled and waved.", levelRaw: 0),
        SeedWord(term: "woman", phonetic: "/ˈwʊmən/", partOfSpeech: "n.", definition: "女人", example: "The woman carries a red bag.", levelRaw: 0),
        SeedWord(term: "child", phonetic: "/tʃaɪld/", partOfSpeech: "n.", definition: "孩子", example: "Every child deserves a safe home.", levelRaw: 0),
        SeedWord(term: "world", phonetic: "/wɜːrld/", partOfSpeech: "n.", definition: "世界", example: "The world looks different after rain.", levelRaw: 0),
        SeedWord(term: "school", phonetic: "/skuːl/", partOfSpeech: "n.", definition: "学校", example: "The school opens at eight.", levelRaw: 0),
        SeedWord(term: "family", phonetic: "/ˈfæməli/", partOfSpeech: "n.", definition: "家庭", example: "Her family enjoys cooking together.", levelRaw: 0),
        SeedWord(term: "student", phonetic: "/ˈstuːdənt/", partOfSpeech: "n.", definition: "学生", example: "The student asked a smart question.", levelRaw: 0),
        SeedWord(term: "group", phonetic: "/ɡruːp/", partOfSpeech: "n.", definition: "小组", example: "Our group meets on Friday.", levelRaw: 0),
        SeedWord(term: "country", phonetic: "/ˈkʌntri/", partOfSpeech: "n.", definition: "国家", example: "He loves his country.", levelRaw: 0),
        SeedWord(term: "problem", phonetic: "/ˈprɑːbləm/", partOfSpeech: "n.", definition: "问题", example: "This problem needs a simple solution.", levelRaw: 0),
        SeedWord(term: "hand", phonetic: "/hænd/", partOfSpeech: "n.", definition: "手", example: "She raised her hand to answer.", levelRaw: 0),
        SeedWord(term: "part", phonetic: "/pɑːrt/", partOfSpeech: "n.", definition: "部分", example: "This part is easy to understand.", levelRaw: 0),
        SeedWord(term: "place", phonetic: "/pleɪs/", partOfSpeech: "n.", definition: "地方", example: "This is a quiet place to read.", levelRaw: 0),
        SeedWord(term: "case", phonetic: "/keɪs/", partOfSpeech: "n.", definition: "情况", example: "In this case, we should wait.", levelRaw: 0),
        SeedWord(term: "week", phonetic: "/wiːk/", partOfSpeech: "n.", definition: "周", example: "The week starts on Monday.", levelRaw: 0),
        SeedWord(term: "company", phonetic: "/ˈkʌmpəni/", partOfSpeech: "n.", definition: "公司", example: "The company released a new product.", levelRaw: 0),
        SeedWord(term: "system", phonetic: "/ˈsɪstəm/", partOfSpeech: "n.", definition: "系统", example: "The system works smoothly.", levelRaw: 0),
        SeedWord(term: "program", phonetic: "/ˈproʊɡræm/", partOfSpeech: "n.", definition: "程序", example: "The program teaches basic skills.", levelRaw: 0),
        SeedWord(term: "question", phonetic: "/ˈkwestʃən/", partOfSpeech: "n.", definition: "问题", example: "Please ask your question now.", levelRaw: 0),
        SeedWord(term: "work", phonetic: "/wɜːrk/", partOfSpeech: "n.", definition: "工作", example: "Her work keeps her busy.", levelRaw: 0),
        SeedWord(term: "government", phonetic: "/ˈɡʌvərnmənt/", partOfSpeech: "n.", definition: "政府", example: "The government announced new policies.", levelRaw: 0),
        SeedWord(term: "number", phonetic: "/ˈnʌmbər/", partOfSpeech: "n.", definition: "数字", example: "Pick a number between one and ten.", levelRaw: 0),
        SeedWord(term: "night", phonetic: "/naɪt/", partOfSpeech: "n.", definition: "夜晚", example: "The night sky is full of stars.", levelRaw: 0),
        SeedWord(term: "point", phonetic: "/pɔɪnt/", partOfSpeech: "n.", definition: "要点", example: "The main point is clear.", levelRaw: 0),
        SeedWord(term: "home", phonetic: "/hoʊm/", partOfSpeech: "n.", definition: "家", example: "Home feels warm and safe.", levelRaw: 0),
        SeedWord(term: "water", phonetic: "/ˈwɔːtər/", partOfSpeech: "n.", definition: "水", example: "Drink water every day.", levelRaw: 0),
        SeedWord(term: "room", phonetic: "/ruːm/", partOfSpeech: "n.", definition: "房间", example: "The room is bright and clean.", levelRaw: 0),
        SeedWord(term: "mother", phonetic: "/ˈmʌðər/", partOfSpeech: "n.", definition: "母亲", example: "Her mother makes great soup.", levelRaw: 0),
        SeedWord(term: "area", phonetic: "/ˈeəriə/", partOfSpeech: "n.", definition: "区域", example: "This area is quiet at night.", levelRaw: 0),
        SeedWord(term: "money", phonetic: "/ˈmʌni/", partOfSpeech: "n.", definition: "钱", example: "Save money for the future.", levelRaw: 0),
        SeedWord(term: "story", phonetic: "/ˈstɔːri/", partOfSpeech: "n.", definition: "故事", example: "The story has a happy ending.", levelRaw: 0),
        SeedWord(term: "fact", phonetic: "/fækt/", partOfSpeech: "n.", definition: "事实", example: "It is a fact that she is kind.", levelRaw: 0),
        SeedWord(term: "month", phonetic: "/mʌnθ/", partOfSpeech: "n.", definition: "月", example: "This month is very busy.", levelRaw: 0),
        SeedWord(term: "lot", phonetic: "/lɑːt/", partOfSpeech: "n.", definition: "很多", example: "A lot of people came today.", levelRaw: 0),
        SeedWord(term: "right", phonetic: "/raɪt/", partOfSpeech: "adj.", definition: "正确的", example: "You chose the right answer.", levelRaw: 0),
        SeedWord(term: "study", phonetic: "/ˈstʌdi/", partOfSpeech: "v.", definition: "学习", example: "We study English after class.", levelRaw: 0),
        SeedWord(term: "book", phonetic: "/bʊk/", partOfSpeech: "n.", definition: "书", example: "He borrowed a book from the library.", levelRaw: 0),
        SeedWord(term: "eye", phonetic: "/aɪ/", partOfSpeech: "n.", definition: "眼睛", example: "Her eye color is blue.", levelRaw: 0),
        SeedWord(term: "job", phonetic: "/dʒɑːb/", partOfSpeech: "n.", definition: "工作", example: "He found a new job.", levelRaw: 0),
        SeedWord(term: "word", phonetic: "/wɜːrd/", partOfSpeech: "n.", definition: "单词", example: "This word is easy to spell.", levelRaw: 0),
        SeedWord(term: "business", phonetic: "/ˈbɪznəs/", partOfSpeech: "n.", definition: "商业", example: "Her business is growing fast.", levelRaw: 0),
        SeedWord(term: "issue", phonetic: "/ˈɪʃuː/", partOfSpeech: "n.", definition: "问题", example: "We discussed the issue today.", levelRaw: 0),
        SeedWord(term: "side", phonetic: "/saɪd/", partOfSpeech: "n.", definition: "侧面", example: "Stand on the left side.", levelRaw: 0),
        SeedWord(term: "kind", phonetic: "/kaɪnd/", partOfSpeech: "adj.", definition: "友好的", example: "She is kind to everyone.", levelRaw: 0),
        SeedWord(term: "head", phonetic: "/hed/", partOfSpeech: "n.", definition: "头", example: "He nodded his head.", levelRaw: 0),
        SeedWord(term: "house", phonetic: "/haʊs/", partOfSpeech: "n.", definition: "房子", example: "Their house is near the river.", levelRaw: 0),
        SeedWord(term: "service", phonetic: "/ˈsɜːrvɪs/", partOfSpeech: "n.", definition: "服务", example: "The service here is excellent.", levelRaw: 0),
        SeedWord(term: "friend", phonetic: "/frend/", partOfSpeech: "n.", definition: "朋友", example: "A friend helped me move.", levelRaw: 0),
        SeedWord(term: "father", phonetic: "/ˈfɑːðər/", partOfSpeech: "n.", definition: "父亲", example: "Her father cooks dinner.", levelRaw: 0),
        SeedWord(term: "power", phonetic: "/ˈpaʊər/", partOfSpeech: "n.", definition: "力量", example: "Knowledge gives us power.", levelRaw: 0),
        SeedWord(term: "hour", phonetic: "/ˈaʊər/", partOfSpeech: "n.", definition: "小时", example: "An hour passed quickly.", levelRaw: 0),
        SeedWord(term: "game", phonetic: "/ɡeɪm/", partOfSpeech: "n.", definition: "游戏", example: "We played a fun game.", levelRaw: 0),
        SeedWord(term: "line", phonetic: "/laɪn/", partOfSpeech: "n.", definition: "线", example: "Draw a straight line.", levelRaw: 0),
        SeedWord(term: "end", phonetic: "/end/", partOfSpeech: "n.", definition: "结束", example: "The end of the movie was sad.", levelRaw: 0),
        SeedWord(term: "member", phonetic: "/ˈmembər/", partOfSpeech: "n.", definition: "成员", example: "Each member has a role.", levelRaw: 0),
        SeedWord(term: "law", phonetic: "/lɔː/", partOfSpeech: "n.", definition: "法律", example: "The law protects citizens.", levelRaw: 0),
        SeedWord(term: "car", phonetic: "/kɑːr/", partOfSpeech: "n.", definition: "汽车", example: "The car runs quietly.", levelRaw: 0),
        SeedWord(term: "city", phonetic: "/ˈsɪti/", partOfSpeech: "n.", definition: "城市", example: "The city is full of lights.", levelRaw: 0),
        SeedWord(term: "community", phonetic: "/kəˈmjuːnəti/", partOfSpeech: "n.", definition: "社区", example: "The community center is open.", levelRaw: 0),
        SeedWord(term: "name", phonetic: "/neɪm/", partOfSpeech: "n.", definition: "名字", example: "Her name is Lily.", levelRaw: 0),
        SeedWord(term: "president", phonetic: "/ˈprezɪdənt/", partOfSpeech: "n.", definition: "总统", example: "The president gave a speech.", levelRaw: 0),
        SeedWord(term: "team", phonetic: "/tiːm/", partOfSpeech: "n.", definition: "团队", example: "Our team won the match.", levelRaw: 0),
        SeedWord(term: "minute", phonetic: "/ˈmɪnɪt/", partOfSpeech: "n.", definition: "分钟", example: "Wait a minute, please.", levelRaw: 0),
        SeedWord(term: "idea", phonetic: "/aɪˈdiːə/", partOfSpeech: "n.", definition: "想法", example: "That is a great idea.", levelRaw: 0),
        SeedWord(term: "kid", phonetic: "/kɪd/", partOfSpeech: "n.", definition: "小孩", example: "The kid laughed loudly.", levelRaw: 0),
        SeedWord(term: "body", phonetic: "/ˈbɑːdi/", partOfSpeech: "n.", definition: "身体", example: "Exercise keeps the body healthy.", levelRaw: 0),
        SeedWord(term: "information", phonetic: "/ˌɪnfərˈmeɪʃən/", partOfSpeech: "n.", definition: "信息", example: "We need more information.", levelRaw: 0),
        SeedWord(term: "back", phonetic: "/bæk/", partOfSpeech: "n.", definition: "背部", example: "My back feels tired today.", levelRaw: 0),
        SeedWord(term: "parent", phonetic: "/ˈperənt/", partOfSpeech: "n.", definition: "父母", example: "A parent signed the form.", levelRaw: 0),
        SeedWord(term: "face", phonetic: "/feɪs/", partOfSpeech: "n.", definition: "脸", example: "She washed her face.", levelRaw: 0),
        SeedWord(term: "others", phonetic: "/ˈʌðərz/", partOfSpeech: "pron.", definition: "其他人", example: "Others agreed with the plan.", levelRaw: 0),
        SeedWord(term: "level", phonetic: "/ˈlevəl/", partOfSpeech: "n.", definition: "水平", example: "His level improved quickly.", levelRaw: 0),
        SeedWord(term: "office", phonetic: "/ˈɔːfɪs/", partOfSpeech: "n.", definition: "办公室", example: "The office is quiet now.", levelRaw: 0),
        SeedWord(term: "door", phonetic: "/dɔːr/", partOfSpeech: "n.", definition: "门", example: "Please close the door.", levelRaw: 0),
        SeedWord(term: "health", phonetic: "/helθ/", partOfSpeech: "n.", definition: "健康", example: "Good sleep helps health.", levelRaw: 0),
        SeedWord(term: "person", phonetic: "/ˈpɜːrsən/", partOfSpeech: "n.", definition: "人", example: "Each person matters.", levelRaw: 0),
        SeedWord(term: "art", phonetic: "/ɑːrt/", partOfSpeech: "n.", definition: "艺术", example: "Art inspires creativity.", levelRaw: 0),
        SeedWord(term: "war", phonetic: "/wɔːr/", partOfSpeech: "n.", definition: "战争", example: "War brings many losses.", levelRaw: 0),
        SeedWord(term: "history", phonetic: "/ˈhɪstəri/", partOfSpeech: "n.", definition: "历史", example: "We learned history today.", levelRaw: 0),
        SeedWord(term: "party", phonetic: "/ˈpɑːrti/", partOfSpeech: "n.", definition: "聚会", example: "The party starts at six.", levelRaw: 0),
        SeedWord(term: "result", phonetic: "/rɪˈzʌlt/", partOfSpeech: "n.", definition: "结果", example: "The result was surprising.", levelRaw: 0),
        SeedWord(term: "change", phonetic: "/tʃeɪndʒ/", partOfSpeech: "n.", definition: "变化", example: "Change can be positive.", levelRaw: 0),
        SeedWord(term: "morning", phonetic: "/ˈmɔːrnɪŋ/", partOfSpeech: "n.", definition: "早晨", example: "The morning air is fresh.", levelRaw: 0),
        SeedWord(term: "reason", phonetic: "/ˈriːzən/", partOfSpeech: "n.", definition: "原因", example: "There is a reason for that.", levelRaw: 0),
        SeedWord(term: "research", phonetic: "/rɪˈsɜːrtʃ/", partOfSpeech: "n.", definition: "研究", example: "Her research is widely known.", levelRaw: 0),
        SeedWord(term: "girl", phonetic: "/ɡɜːrl/", partOfSpeech: "n.", definition: "女孩", example: "The girl plays the piano.", levelRaw: 0),
        SeedWord(term: "guy", phonetic: "/ɡaɪ/", partOfSpeech: "n.", definition: "小伙子", example: "That guy helped us.", levelRaw: 0),
        SeedWord(term: "moment", phonetic: "/ˈmoʊmənt/", partOfSpeech: "n.", definition: "时刻", example: "This moment feels special.", levelRaw: 0),
        SeedWord(term: "air", phonetic: "/er/", partOfSpeech: "n.", definition: "空气", example: "Fresh air is good for health.", levelRaw: 0),
        SeedWord(term: "teacher", phonetic: "/ˈtiːtʃər/", partOfSpeech: "n.", definition: "老师", example: "The teacher explained the rule.", levelRaw: 0),
        SeedWord(term: "force", phonetic: "/fɔːrs/", partOfSpeech: "n.", definition: "力量", example: "The force of the wind was strong.", levelRaw: 0),
        SeedWord(term: "education", phonetic: "/ˌedʒuˈkeɪʃən/", partOfSpeech: "n.", definition: "教育", example: "Education opens many doors.", levelRaw: 0),
        SeedWord(term: "foot", phonetic: "/fʊt/", partOfSpeech: "n.", definition: "脚", example: "He hurt his foot yesterday.", levelRaw: 0),
        SeedWord(term: "food", phonetic: "/fuːd/", partOfSpeech: "n.", definition: "食物", example: "The food smells delicious.", levelRaw: 0),
        SeedWord(term: "music", phonetic: "/ˈmjuːzɪk/", partOfSpeech: "n.", definition: "音乐", example: "Soft music helps me relax.", levelRaw: 0),
        SeedWord(term: "market", phonetic: "/ˈmɑːrkɪt/", partOfSpeech: "n.", definition: "市场", example: "The market is crowded today.", levelRaw: 0),

        SeedWord(term: "discover", phonetic: "/dɪˈskʌvər/", partOfSpeech: "v.", definition: "发现", example: "They discover new ideas quickly.", levelRaw: 1),
        SeedWord(term: "improve", phonetic: "/ɪmˈpruːv/", partOfSpeech: "v.", definition: "改善", example: "Practice will improve your skills.", levelRaw: 1),
        SeedWord(term: "solution", phonetic: "/səˈluːʃən/", partOfSpeech: "n.", definition: "解决方案", example: "We found a solution to the problem.", levelRaw: 1),
        SeedWord(term: "culture", phonetic: "/ˈkʌltʃər/", partOfSpeech: "n.", definition: "文化", example: "Culture shapes our habits.", levelRaw: 1),
        SeedWord(term: "balance", phonetic: "/ˈbæləns/", partOfSpeech: "n.", definition: "平衡", example: "Work-life balance matters.", levelRaw: 1),
        SeedWord(term: "responsible", phonetic: "/rɪˈspɑːnsəbəl/", partOfSpeech: "adj.", definition: "负责的", example: "She is responsible for the report.", levelRaw: 1),
        SeedWord(term: "increase", phonetic: "/ɪnˈkriːs/", partOfSpeech: "v.", definition: "增加", example: "Sales increase every month.", levelRaw: 1),
        SeedWord(term: "decrease", phonetic: "/dɪˈkriːs/", partOfSpeech: "v.", definition: "减少", example: "We need to decrease waste.", levelRaw: 1),
        SeedWord(term: "effect", phonetic: "/ɪˈfekt/", partOfSpeech: "n.", definition: "影响", example: "The effect was immediate.", levelRaw: 1),
        SeedWord(term: "opinion", phonetic: "/əˈpɪnjən/", partOfSpeech: "n.", definition: "观点", example: "In my opinion, this is fair.", levelRaw: 1),
        SeedWord(term: "society", phonetic: "/səˈsaɪəti/", partOfSpeech: "n.", definition: "社会", example: "Society changes over time.", levelRaw: 1),
        SeedWord(term: "environment", phonetic: "/ɪnˈvaɪrənmənt/", partOfSpeech: "n.", definition: "环境", example: "We should protect the environment.", levelRaw: 1),
        SeedWord(term: "quality", phonetic: "/ˈkwɑːləti/", partOfSpeech: "n.", definition: "质量", example: "Quality matters more than quantity.", levelRaw: 1),
        SeedWord(term: "benefit", phonetic: "/ˈbenɪfɪt/", partOfSpeech: "n.", definition: "好处", example: "Exercise has many benefits.", levelRaw: 1),
        SeedWord(term: "resource", phonetic: "/ˈriːsɔːrs/", partOfSpeech: "n.", definition: "资源", example: "Water is a valuable resource.", levelRaw: 1),
        SeedWord(term: "communication", phonetic: "/kəˌmjuːnɪˈkeɪʃən/", partOfSpeech: "n.", definition: "沟通", example: "Clear communication avoids mistakes.", levelRaw: 1),
        SeedWord(term: "technology", phonetic: "/tekˈnɑːlədʒi/", partOfSpeech: "n.", definition: "技术", example: "Technology moves fast.", levelRaw: 1),
        SeedWord(term: "opportunity", phonetic: "/ˌɑːpərˈtuːnəti/", partOfSpeech: "n.", definition: "机会", example: "This is a great opportunity.", levelRaw: 1),
        SeedWord(term: "experience", phonetic: "/ɪkˈspɪriəns/", partOfSpeech: "n.", definition: "经验", example: "Experience helps us grow.", levelRaw: 1),
        SeedWord(term: "decision", phonetic: "/dɪˈsɪʒən/", partOfSpeech: "n.", definition: "决定", example: "The decision was not easy.", levelRaw: 1),
        SeedWord(term: "process", phonetic: "/ˈprɑːses/", partOfSpeech: "n.", definition: "过程", example: "Learning is a long process.", levelRaw: 1),
        SeedWord(term: "support", phonetic: "/səˈpɔːrt/", partOfSpeech: "v.", definition: "支持", example: "We support your plan.", levelRaw: 1),
        SeedWord(term: "arrive", phonetic: "/əˈraɪv/", partOfSpeech: "v.", definition: "到达", example: "They arrive at noon.", levelRaw: 1),
        SeedWord(term: "accept", phonetic: "/əkˈsept/", partOfSpeech: "v.", definition: "接受", example: "Please accept my apology.", levelRaw: 1),
        SeedWord(term: "prepare", phonetic: "/prɪˈper/", partOfSpeech: "v.", definition: "准备", example: "She will prepare the slides.", levelRaw: 1),
        SeedWord(term: "demand", phonetic: "/dɪˈmænd/", partOfSpeech: "n.", definition: "需求", example: "Demand is rising quickly.", levelRaw: 1),
        SeedWord(term: "industry", phonetic: "/ˈɪndəstri/", partOfSpeech: "n.", definition: "行业", example: "The industry needs talent.", levelRaw: 1),
        SeedWord(term: "compare", phonetic: "/kəmˈper/", partOfSpeech: "v.", definition: "比较", example: "Compare the two options.", levelRaw: 1),
        SeedWord(term: "customer", phonetic: "/ˈkʌstəmər/", partOfSpeech: "n.", definition: "顾客", example: "The customer was satisfied.", levelRaw: 1),
        SeedWord(term: "project", phonetic: "/ˈprɑːdʒekt/", partOfSpeech: "n.", definition: "项目", example: "The project finished early.", levelRaw: 1),
        SeedWord(term: "position", phonetic: "/pəˈzɪʃən/", partOfSpeech: "n.", definition: "位置", example: "He found a good position.", levelRaw: 1),
        SeedWord(term: "pattern", phonetic: "/ˈpætərn/", partOfSpeech: "n.", definition: "模式", example: "We noticed a clear pattern.", levelRaw: 1),
        SeedWord(term: "pressure", phonetic: "/ˈpreʃər/", partOfSpeech: "n.", definition: "压力", example: "Pressure can affect sleep.", levelRaw: 1),
        SeedWord(term: "structure", phonetic: "/ˈstrʌktʃər/", partOfSpeech: "n.", definition: "结构", example: "The structure is solid.", levelRaw: 1),
        SeedWord(term: "influence", phonetic: "/ˈɪnfluəns/", partOfSpeech: "n.", definition: "影响", example: "Her words had influence.", levelRaw: 1),
        SeedWord(term: "career", phonetic: "/kəˈrɪr/", partOfSpeech: "n.", definition: "职业", example: "He changed his career path.", levelRaw: 1),
        SeedWord(term: "attention", phonetic: "/əˈtenʃən/", partOfSpeech: "n.", definition: "注意力", example: "Pay attention to details.", levelRaw: 1),
        SeedWord(term: "development", phonetic: "/dɪˈveləpmənt/", partOfSpeech: "n.", definition: "发展", example: "Development takes time.", levelRaw: 1),
        SeedWord(term: "performance", phonetic: "/pərˈfɔːrməns/", partOfSpeech: "n.", definition: "表现", example: "Her performance improved.", levelRaw: 1),
        SeedWord(term: "strategy", phonetic: "/ˈstrætədʒi/", partOfSpeech: "n.", definition: "策略", example: "The strategy worked well.", levelRaw: 1),
        SeedWord(term: "evaluate", phonetic: "/ɪˈvæljuˌeɪt/", partOfSpeech: "v.", definition: "评估", example: "We will evaluate the results.", levelRaw: 1),
        SeedWord(term: "provide", phonetic: "/prəˈvaɪd/", partOfSpeech: "v.", definition: "提供", example: "They provide useful tools.", levelRaw: 1),
        SeedWord(term: "require", phonetic: "/rɪˈkwaɪr/", partOfSpeech: "v.", definition: "需要", example: "This task requires focus.", levelRaw: 1),
        SeedWord(term: "feature", phonetic: "/ˈfiːtʃər/", partOfSpeech: "n.", definition: "功能", example: "This feature saves time.", levelRaw: 1),
        SeedWord(term: "normal", phonetic: "/ˈnɔːrməl/", partOfSpeech: "adj.", definition: "正常的", example: "It is normal to feel nervous.", levelRaw: 1),
        SeedWord(term: "complex", phonetic: "/kəmˈpleks/", partOfSpeech: "adj.", definition: "复杂的", example: "The problem is complex.", levelRaw: 1),
        SeedWord(term: "standard", phonetic: "/ˈstændərd/", partOfSpeech: "n.", definition: "标准", example: "We follow a strict standard.", levelRaw: 1),
        SeedWord(term: "section", phonetic: "/ˈsekʃən/", partOfSpeech: "n.", definition: "部分", example: "Read the first section.", levelRaw: 1),
        SeedWord(term: "manage", phonetic: "/ˈmænɪdʒ/", partOfSpeech: "v.", definition: "管理", example: "She can manage the team.", levelRaw: 1),
        SeedWord(term: "response", phonetic: "/rɪˈspɑːns/", partOfSpeech: "n.", definition: "回应", example: "We got a quick response.", levelRaw: 1),

        SeedWord(term: "meticulous", phonetic: "/məˈtɪkjələs/", partOfSpeech: "adj.", definition: "一丝不苟的", example: "She is meticulous about details.", levelRaw: 2),
        SeedWord(term: "ambiguous", phonetic: "/æmˈbɪɡjuəs/", partOfSpeech: "adj.", definition: "模糊的", example: "The instructions were ambiguous.", levelRaw: 2),
        SeedWord(term: "inevitable", phonetic: "/ɪnˈevɪtəbl/", partOfSpeech: "adj.", definition: "不可避免的", example: "Change is inevitable.", levelRaw: 2),
        SeedWord(term: "hypothesis", phonetic: "/haɪˈpɑːθəsɪs/", partOfSpeech: "n.", definition: "假设", example: "We tested the hypothesis carefully.", levelRaw: 2),
        SeedWord(term: "paradigm", phonetic: "/ˈpærədaɪm/", partOfSpeech: "n.", definition: "范式", example: "The paradigm shifted in science.", levelRaw: 2),
        SeedWord(term: "resilient", phonetic: "/rɪˈzɪljənt/", partOfSpeech: "adj.", definition: "有韧性的", example: "Resilient teams adapt quickly.", levelRaw: 2),
        SeedWord(term: "sophisticated", phonetic: "/səˈfɪstɪkeɪtɪd/", partOfSpeech: "adj.", definition: "复杂精密的", example: "The device is sophisticated.", levelRaw: 2),
        SeedWord(term: "sustainable", phonetic: "/səˈsteɪnəbəl/", partOfSpeech: "adj.", definition: "可持续的", example: "We need sustainable solutions.", levelRaw: 2),
        SeedWord(term: "phenomenon", phonetic: "/fəˈnɑːmənɑːn/", partOfSpeech: "n.", definition: "现象", example: "It is a rare phenomenon.", levelRaw: 2),
        SeedWord(term: "intrinsic", phonetic: "/ɪnˈtrɪnsɪk/", partOfSpeech: "adj.", definition: "内在的", example: "Curiosity is intrinsic to learning.", levelRaw: 2),
        SeedWord(term: "pragmatic", phonetic: "/præɡˈmætɪk/", partOfSpeech: "adj.", definition: "务实的", example: "He took a pragmatic approach.", levelRaw: 2),
        SeedWord(term: "cumulative", phonetic: "/ˈkjuːmjəleɪtɪv/", partOfSpeech: "adj.", definition: "累计的", example: "The cumulative effect was large.", levelRaw: 2),
        SeedWord(term: "corroborate", phonetic: "/kəˈrɑːbəreɪt/", partOfSpeech: "v.", definition: "证实", example: "The data corroborate the claim.", levelRaw: 2),
        SeedWord(term: "diligent", phonetic: "/ˈdɪlɪdʒənt/", partOfSpeech: "adj.", definition: "勤奋的", example: "She is diligent in her studies.", levelRaw: 2),
        SeedWord(term: "nuance", phonetic: "/ˈnuːɑːns/", partOfSpeech: "n.", definition: "细微差别", example: "The word has a subtle nuance.", levelRaw: 2),
        SeedWord(term: "ubiquitous", phonetic: "/juːˈbɪkwɪtəs/", partOfSpeech: "adj.", definition: "无处不在的", example: "Smartphones are ubiquitous today.", levelRaw: 2),
        SeedWord(term: "unprecedented", phonetic: "/ʌnˈpresɪdentɪd/", partOfSpeech: "adj.", definition: "空前的", example: "The results were unprecedented.", levelRaw: 2),
        SeedWord(term: "volatile", phonetic: "/ˈvɑːlətl/", partOfSpeech: "adj.", definition: "易变的", example: "The market is volatile.", levelRaw: 2),
        SeedWord(term: "coherent", phonetic: "/koʊˈhɪrənt/", partOfSpeech: "adj.", definition: "连贯的", example: "Her speech was coherent.", levelRaw: 2),
        SeedWord(term: "consequence", phonetic: "/ˈkɑːnsəkwens/", partOfSpeech: "n.", definition: "结果", example: "Every choice has a consequence.", levelRaw: 2),
        SeedWord(term: "contemplate", phonetic: "/ˈkɑːntəmpleɪt/", partOfSpeech: "v.", definition: "沉思", example: "He paused to contemplate the plan.", levelRaw: 2),
        SeedWord(term: "substantial", phonetic: "/səbˈstænʃəl/", partOfSpeech: "adj.", definition: "大量的", example: "The project made substantial progress.", levelRaw: 2),
        SeedWord(term: "transient", phonetic: "/ˈtrænʃənt/", partOfSpeech: "adj.", definition: "短暂的", example: "The joy was transient.", levelRaw: 2),
        SeedWord(term: "obsolete", phonetic: "/ˈɑːbsəliːt/", partOfSpeech: "adj.", definition: "过时的", example: "The device became obsolete.", levelRaw: 2),
        SeedWord(term: "articulate", phonetic: "/ɑːrˈtɪkjəleɪt/", partOfSpeech: "v.", definition: "清楚表达", example: "She can articulate her ideas.", levelRaw: 2),
        SeedWord(term: "emerge", phonetic: "/ɪˈmɜːrdʒ/", partOfSpeech: "v.", definition: "出现", example: "New patterns emerge quickly.", levelRaw: 2),
        SeedWord(term: "innovation", phonetic: "/ˌɪnəˈveɪʃən/", partOfSpeech: "n.", definition: "创新", example: "Innovation drives growth.", levelRaw: 2),
        SeedWord(term: "imperative", phonetic: "/ɪmˈperətɪv/", partOfSpeech: "adj.", definition: "必要的", example: "It is imperative to act now.", levelRaw: 2),
        SeedWord(term: "pervasive", phonetic: "/pərˈveɪsɪv/", partOfSpeech: "adj.", definition: "普遍的", example: "Stress is pervasive in cities.", levelRaw: 2),
        SeedWord(term: "perspective", phonetic: "/pərˈspektɪv/", partOfSpeech: "n.", definition: "视角", example: "Try a new perspective.", levelRaw: 2),
        SeedWord(term: "alleviate", phonetic: "/əˈliːvieɪt/", partOfSpeech: "v.", definition: "缓解", example: "The medicine alleviates pain.", levelRaw: 2),
        SeedWord(term: "contradict", phonetic: "/ˌkɑːntrəˈdɪkt/", partOfSpeech: "v.", definition: "反驳", example: "Do not contradict the facts.", levelRaw: 2),
        SeedWord(term: "conventional", phonetic: "/kənˈvenʃənl/", partOfSpeech: "adj.", definition: "传统的", example: "He chose a conventional method.", levelRaw: 2),
        SeedWord(term: "derive", phonetic: "/dɪˈraɪv/", partOfSpeech: "v.", definition: "来源于", example: "Many words derive from Latin.", levelRaw: 2),
        SeedWord(term: "discrepancy", phonetic: "/dɪˈskrepənsi/", partOfSpeech: "n.", definition: "差异", example: "We found a discrepancy in the report.", levelRaw: 2),
        SeedWord(term: "feasible", phonetic: "/ˈfiːzəbəl/", partOfSpeech: "adj.", definition: "可行的", example: "The plan is feasible.", levelRaw: 2),
        SeedWord(term: "formulate", phonetic: "/ˈfɔːrmjəleɪt/", partOfSpeech: "v.", definition: "制定", example: "They formulate a clear policy.", levelRaw: 2),
        SeedWord(term: "integrate", phonetic: "/ˈɪntɪɡreɪt/", partOfSpeech: "v.", definition: "整合", example: "We integrate data from sensors.", levelRaw: 2),
        SeedWord(term: "interpret", phonetic: "/ɪnˈtɜːrprət/", partOfSpeech: "v.", definition: "解释", example: "He can interpret complex charts.", levelRaw: 2),
        SeedWord(term: "marginal", phonetic: "/ˈmɑːrdʒɪnəl/", partOfSpeech: "adj.", definition: "边缘的", example: "The benefits are marginal.", levelRaw: 2),
        SeedWord(term: "optimize", phonetic: "/ˈɑːptɪmaɪz/", partOfSpeech: "v.", definition: "优化", example: "We optimize the workflow.", levelRaw: 2),
        SeedWord(term: "prioritize", phonetic: "/praɪˈɔːrətaɪz/", partOfSpeech: "v.", definition: "优先处理", example: "Prioritize the urgent tasks.", levelRaw: 2),
        SeedWord(term: "profound", phonetic: "/prəˈfaʊnd/", partOfSpeech: "adj.", definition: "深刻的", example: "The book had a profound impact.", levelRaw: 2),
        SeedWord(term: "rational", phonetic: "/ˈræʃənl/", partOfSpeech: "adj.", definition: "理性的", example: "He made a rational choice.", levelRaw: 2),
        SeedWord(term: "reconcile", phonetic: "/ˈrekənsaɪl/", partOfSpeech: "v.", definition: "调和", example: "They reconcile the two reports.", levelRaw: 2),
        SeedWord(term: "subsidy", phonetic: "/ˈsʌbsədi/", partOfSpeech: "n.", definition: "补贴", example: "The subsidy reduced costs.", levelRaw: 2),
        SeedWord(term: "threshold", phonetic: "/ˈθreʃhoʊld/", partOfSpeech: "n.", definition: "门槛", example: "We crossed the threshold.", levelRaw: 2),
        SeedWord(term: "validity", phonetic: "/vəˈlɪdəti/", partOfSpeech: "n.", definition: "有效性", example: "We checked the validity of data.", levelRaw: 2),
        SeedWord(term: "vulnerable", phonetic: "/ˈvʌlnərəbəl/", partOfSpeech: "adj.", definition: "脆弱的", example: "Young plants are vulnerable.", levelRaw: 2),
        SeedWord(term: "equilibrium", phonetic: "/ˌiːkwɪˈlɪbriəm/", partOfSpeech: "n.", definition: "平衡", example: "The system returned to equilibrium.", levelRaw: 2)
    ]
}

@MainActor
enum SeedDataLoader {
    static func seedIfNeeded(context: ModelContext) async {
        var fetch = FetchDescriptor<Word>()
        fetch.fetchLimit = 1
        let hasWords = ((try? context.fetch(fetch))?.isEmpty == false)
        if !hasWords {
            for seed in SeedData.words {
                let level = WordLevel(rawValue: seed.levelRaw) ?? .basic
                let word = Word(
                    term: seed.term,
                    phonetic: seed.phonetic,
                    partOfSpeech: seed.partOfSpeech,
                    definition: seed.definition,
                    example: seed.example,
                    level: level
                )
                context.insert(word)
            }
        }

        var settingsFetch = FetchDescriptor<UserSettings>()
        settingsFetch.fetchLimit = 1
        let hasSettings = ((try? context.fetch(settingsFetch))?.isEmpty == false)
        if !hasSettings {
            context.insert(UserSettings())
        }

        var achievementFetch = FetchDescriptor<Achievement>()
        achievementFetch.fetchLimit = 1
        let hasAchievements = ((try? context.fetch(achievementFetch))?.isEmpty == false)
        if !hasAchievements {
            for achievement in AchievementCatalog.defaultAchievements() {
                context.insert(achievement)
            }
        }

        let today = Calendar.current.startOfDay(for: Date())
        var statsFetch = FetchDescriptor<DailyStats>(predicate: #Predicate { $0.date == today })
        statsFetch.fetchLimit = 1
        let hasTodayStats = ((try? context.fetch(statsFetch))?.isEmpty == false)
        if !hasTodayStats {
            context.insert(DailyStats(date: today))
        }

        if context.hasChanges {
            try? context.save()
        }
    }
}

@MainActor
enum Haptic {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

@MainActor
final class SpeechService {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(text: String, rate: SpeechRateOption) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate.rate
        synthesizer.speak(utterance)
    }
}

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    func scheduleDailyReminder(settings: UserSettings) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Time to study"
        content.body = "Keep your streak alive with a quick session."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: settings.reminderComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func scheduleStreakReminder(hour: Int, minute: Int) async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Streak check"
        content.body = "Study now to keep your streak."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        try? await center.add(request)
    }

    func clearAll() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}

@MainActor
enum StatsService {
    static func todayStats(context: ModelContext) -> DailyStats {
        let today = Calendar.current.startOfDay(for: Date())
        var fetch = FetchDescriptor<DailyStats>(predicate: #Predicate { $0.date == today })
        fetch.fetchLimit = 1
        if let stats = try? context.fetch(fetch).first {
            return stats
        }
        let stats = DailyStats(date: today)
        context.insert(stats)
        return stats
    }

    static func recordStudy(context: ModelContext, learnedIncrement: Int) {
        let stats = todayStats(context: context)
        stats.learnedCount += learnedIncrement
        stats.studySeconds += Double(learnedIncrement) * 5
    }

    static func recordPractice(context: ModelContext, isCorrect: Bool, duration: TimeInterval) {
        let stats = todayStats(context: context)
        stats.totalCount += 1
        if isCorrect {
            stats.correctCount += 1
        }
        stats.studySeconds += duration
    }

    static func streak(from stats: [DailyStats]) -> Int {
        let calendar = Calendar.current
        let statsByDate = Dictionary(grouping: stats, by: { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        while true {
            if let dayStats = statsByDate[currentDate]?.first,
               dayStats.learnedCount > 0 || dayStats.totalCount > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        return streak
    }
}

enum AchievementCatalog {
    static func defaultAchievements() -> [Achievement] {
        return [
            Achievement(title: "7-Day Streak", detail: "Study 7 days in a row", iconName: "flame", kind: .studyDays, targetValue: 7),
            Achievement(title: "30-Day Streak", detail: "Study 30 days in a row", iconName: "flame.fill", kind: .studyDays, targetValue: 30),
            Achievement(title: "100-Day Streak", detail: "Study 100 days in a row", iconName: "flame.circle", kind: .studyDays, targetValue: 100),
            Achievement(title: "365-Day Streak", detail: "Study 365 days in a row", iconName: "flame.circle.fill", kind: .studyDays, targetValue: 365),
            Achievement(title: "100 Words", detail: "Master 100 words", iconName: "book", kind: .vocabMastered, targetValue: 100),
            Achievement(title: "500 Words", detail: "Master 500 words", iconName: "books.vertical", kind: .vocabMastered, targetValue: 500),
            Achievement(title: "1000 Words", detail: "Master 1000 words", iconName: "graduationcap", kind: .vocabMastered, targetValue: 1000),
            Achievement(title: "5000 Words", detail: "Master 5000 words", iconName: "graduationcap.fill", kind: .vocabMastered, targetValue: 5000),
            Achievement(title: "Perfect 10", detail: "10 correct in a row", iconName: "checkmark.seal", kind: .correctStreak, targetValue: 10),
            Achievement(title: "Perfect 50", detail: "50 correct in a row", iconName: "checkmark.seal.fill", kind: .correctStreak, targetValue: 50),
            Achievement(title: "Perfect 100", detail: "100 correct in a row", iconName: "star.circle", kind: .correctStreak, targetValue: 100)
        ]
    }
}

@MainActor
enum AchievementService {
    static func updateAchievements(
        context: ModelContext,
        stats: [DailyStats],
        words: [Word],
        settings: UserSettings,
        achievements: [Achievement]
    ) {
        let streak = StatsService.streak(from: stats)
        let masteredCount = words.filter { $0.status == .mastered }.count
        let correctStreak = settings.correctStreak ?? 0

        for achievement in achievements where !achievement.isEarned {
            let reached: Bool
            switch achievement.kind {
            case .studyDays:
                reached = streak >= achievement.targetValue
            case .vocabMastered:
                reached = masteredCount >= achievement.targetValue
            case .correctStreak:
                reached = correctStreak >= achievement.targetValue
            }
            if reached {
                achievement.isEarned = true
                achievement.achievedAt = Date()
            }
        }

        if context.hasChanges {
            try? context.save()
        }
    }
}

struct PracticeQuestion: Identifiable {
    let id = UUID()
    let type: PracticeType
    let prompt: String
    let options: [String]
    let answer: String
    let hint: String
    let word: Word
    let example: String
}

@MainActor
final class PracticeSessionViewModel: ObservableObject {
    @Published var questions: [PracticeQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var selectedOption: String? = nil
    @Published var answerResult: Bool? = nil
    @Published var timeRemaining: Int = 30
    @Published var textAnswer: String = ""
    @Published var showHint: Bool = false
    @Published var isCompleted: Bool = false
    @Published var wrongQuestions: [PracticeQuestion] = []

    private var startTime: Date = Date()
    private(set) var correctCount: Int = 0
    private(set) var totalTime: TimeInterval = 0
    private var context: ModelContext?
    private var settings: UserSettings?

    func configure(type: PracticeType, words: [Word], context: ModelContext, settings: UserSettings) {
        guard questions.isEmpty else { return }
        self.context = context
        self.settings = settings
        let pool = Array(words.shuffled().prefix(10))
        var generated: [PracticeQuestion] = []

        for word in pool {
            let optionsPool = Array(words.shuffled().filter { $0.term != word.term }.prefix(3))
            let options: [String]
            let prompt: String
            let answer: String
            switch type {
            case .choiceWordToDefinition:
                prompt = word.term
                answer = word.definition
                options = ([word.definition] + optionsPool.map { $0.definition }).shuffled()
            case .choiceDefinitionToWord:
                prompt = word.definition
                answer = word.term
                options = ([word.term] + optionsPool.map { $0.term }).shuffled()
            case .fillBlank:
                prompt = word.example.replacingOccurrences(of: word.term, with: "____")
                answer = word.term
                options = []
            case .listening:
                prompt = "Listen and choose the correct word"
                answer = word.term
                options = ([word.term] + optionsPool.map { $0.term }).shuffled()
            }

            generated.append(
                PracticeQuestion(
                    type: type,
                    prompt: prompt,
                    options: options,
                    answer: answer,
                    hint: String(word.term.prefix(1)),
                    word: word,
                    example: word.example
                )
            )
        }

        questions = generated
        currentIndex = 0
        startTime = Date()
        timeRemaining = 30
    }

    var currentQuestion: PracticeQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    func tick() {
        guard !isCompleted, answerResult == nil else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining == 0 {
            submitAnswer(selected: nil)
        }
    }

    func submitOption(_ option: String) {
        guard answerResult == nil else { return }
        selectedOption = option
        submitAnswer(selected: option)
    }

    func submitTextAnswer() {
        guard answerResult == nil else { return }
        submitAnswer(selected: textAnswer.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func submitAnswer(selected: String?) {
        guard let question = currentQuestion else { return }
        let isCorrect = (selected?.lowercased() == question.answer.lowercased())
        answerResult = isCorrect
        if isCorrect {
            correctCount += 1
            Haptic.notify(.success)
        } else {
            wrongQuestions.append(question)
            Haptic.notify(.error)
        }

        let duration = Date().timeIntervalSince(startTime)
        totalTime += duration
        recordResult(question: question, isCorrect: isCorrect, duration: duration)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.moveToNext()
        }
    }

    private func recordResult(question: PracticeQuestion, isCorrect: Bool, duration: TimeInterval) {
        guard let context, let settings else { return }
        question.word.lastReviewed = Date()
        if isCorrect {
            question.word.correctCount += 1
            settings.correctStreak = (settings.correctStreak ?? 0) + 1
        } else {
            question.word.incorrectCount += 1
            question.word.status = .learning
            settings.correctStreak = 0
        }
        StatsService.recordPractice(context: context, isCorrect: isCorrect, duration: duration)
        let attempt = PracticeAttempt(date: Date(), duration: duration, isCorrect: isCorrect, type: question.type, word: question.word)
        context.insert(attempt)
        try? context.save()
    }

    private func moveToNext() {
        guard currentIndex < questions.count else { return }
        currentIndex += 1
        selectedOption = nil
        answerResult = nil
        textAnswer = ""
        showHint = false
        timeRemaining = 30
        startTime = Date()
        if currentIndex >= questions.count {
            isCompleted = true
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var settings: [UserSettings]
    @State private var isSeeding = false

    var body: some View {
        let activeSettings = settings.first ?? UserSettings()
        Group {
            if isSeeding {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Preparing your vocabulary...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                RootTabView(settings: activeSettings)
            }
        }
        .task {
            guard !isSeeding else { return }
            isSeeding = true
            await SeedDataLoader.seedIfNeeded(context: context)
            isSeeding = false
        }
        .preferredColorScheme(activeSettings.preferredColorScheme)
        .dynamicTypeSize(activeSettings.dynamicTypeSize)
    }
}

struct RootTabView: View {
    var settings: UserSettings

    var body: some View {
        TabView {
            StudyHomeView(settings: settings)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            PracticeHubView(settings: settings)
                .tabItem {
                    Label("Practice", systemImage: "target")
                }

            ProgressDashboardView(settings: settings)
                .tabItem {
                    Label("Progress", systemImage: "chart.xyaxis.line")
                }

            SettingsView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ProgressHeaderView: View {
    let title: String
    let subtitle: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView(value: progress)
                .tint(Color.freshGreen)
                .accessibilityLabel("Daily progress")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

struct StudyHomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @Query private var stats: [DailyStats]
    @Query private var achievements: [Achievement]
    var settings: UserSettings

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    let todayStats = stats.first(where: { Calendar.current.isDateInToday($0.date) })
                    let learned = todayStats?.learnedCount ?? 0
                    let goal = max(settings.dailyGoal ?? 20, 1)
                    ProgressHeaderView(
                        title: "Today",
                        subtitle: "Learned \(learned) / \(goal) words",
                        progress: min(Double(learned) / Double(goal), 1)
                    )

                    StudyDeckView(words: words, settings: settings)

                    GoalSummaryView(learned: learned, goal: goal)

                    NavigationLink {
                        FavoritesView()
                    } label: {
                        SectionCardView(
                            title: "Favorites",
                            subtitle: "Starred words you love",
                            icon: "star.fill",
                            tint: .yellow
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("LingoLearn")
            .task {
                AchievementService.updateAchievements(
                    context: context,
                    stats: stats,
                    words: words,
                    settings: settings,
                    achievements: achievements
                )
            }
        }
    }
}

struct GoalSummaryView: View {
    let learned: Int
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Goal")
                .font(.headline)
            HStack {
                VStack(alignment: .leading) {
                    Text("\(learned)")
                        .font(.title.bold())
                    Text("Words learned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("\(goal)")
                        .font(.title.bold())
                    Text("Target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.warmBlue.opacity(0.1))
        )
    }
}

struct SectionCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

struct StudyDeckView: View {
    @Environment(\.modelContext) private var context
    @State private var deck: [Word] = []
    @State private var isFlipped = false
    @State private var dragOffset: CGSize = .zero
    @State private var isLoading = true
    let words: [Word]
    let settings: UserSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Study Cards")
                    .font(.headline)
                Spacer()
                Button("Shuffle") {
                    reloadDeck()
                }
                .font(.caption.bold())
            }

            ZStack {
                ForEach(deck.prefix(3).indices.reversed(), id: \.self) { index in
                    let word = deck[index]
                    WordCardView(
                        word: word,
                        isFlipped: index == 0 ? $isFlipped : .constant(false),
                        settings: settings
                    )
                    .offset(y: CGFloat(index) * 12)
                    .scaleEffect(1 - CGFloat(index) * 0.04)
                    .shadow(radius: index == 0 ? 12 : 4)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .overlay(alignment: .center) {
                if deck.isEmpty {
                    Text("No words left. Great job!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        handleSwipe(translation: value.translation)
                    }
            )
            .animation(.spring(), value: dragOffset)
            .redacted(reason: isLoading ? .placeholder : [])

            HStack {
                Label("Swipe left: Mastered", systemImage: "hand.thumbsup.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("Swipe right: Review", systemImage: "arrow.uturn.left.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
        .onAppear {
            reloadDeck()
        }
    }

    private func reloadDeck() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let candidates = words.filter { $0.status != .mastered }
            deck = Array(candidates.shuffled().prefix(6))
            isFlipped = false
            dragOffset = .zero
            isLoading = false
        }
    }

    private func handleSwipe(translation: CGSize) {
        let threshold: CGFloat = 120
        guard let word = deck.first else { return }
        if translation.width < -threshold {
            markWord(word, as: .mastered)
        } else if translation.width > threshold {
            markWord(word, as: .learning)
        }
        dragOffset = .zero
    }

    private func markWord(_ word: Word, as status: WordStatus) {
        word.status = status
        word.lastReviewed = Date()
        StatsService.recordStudy(context: context, learnedIncrement: 1)
        if status == .mastered {
            Haptic.notify(.success)
        } else {
            Haptic.impact(.light)
        }
        deck.removeFirst()
        isFlipped = false
        try? context.save()
        if deck.count < 2 {
            reloadDeck()
        }
    }
}

struct WordCardView: View {
    @Environment(\.modelContext) private var context
    let word: Word
    @Binding var isFlipped: Bool
    let settings: UserSettings
    @State private var isAnimatingRipple = false

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.15))
        )
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFlipped)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Word card for \(word.term)")
    }

    private var front: some View {
        VStack(spacing: 12) {
            HStack {
                Text(word.level.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(word.level == .basic ? Color.warmBlue.opacity(0.2) : (word.level == .intermediate ? Color.freshGreen.opacity(0.2) : Color.orange.opacity(0.2)))
                    .clipShape(Capsule())
                Spacer()
                favoriteButton
            }
            Spacer()
            Text(word.term)
                .font(.largeTitle.bold())
            Text(word.phonetic)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(word.partOfSpeech)
                .font(.caption)
                .foregroundStyle(.secondary)
            PronounceButton(isAnimating: $isAnimatingRipple) {
                SpeechService.shared.speak(text: word.term, rate: settings.speechRate)
                Haptic.impact(.light)
            }
            Spacer()
            Text("Tap to flip")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            isFlipped.toggle()
            Haptic.impact(.light)
        }
    }

    private var back: some View {
        VStack(spacing: 12) {
            HStack {
                Text(word.status.label)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(word.status.color.opacity(0.2))
                    .clipShape(Capsule())
                Spacer()
                favoriteButton
            }
            Spacer()
            Text(word.definition)
                .font(.title2.bold())
            Text(word.example)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Text("Tap to flip back")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            isFlipped.toggle()
            Haptic.impact(.light)
        }
    }

    private var favoriteButton: some View {
        Button {
            word.isFavorite.toggle()
            Haptic.impact(.light)
            try? context.save()
        } label: {
            Image(systemName: word.isFavorite ? "star.fill" : "star")
                .foregroundStyle(word.isFavorite ? Color.yellow : Color.secondary)
                .font(.title3)
        }
        .accessibilityLabel(word.isFavorite ? "Remove from favorites" : "Add to favorites")
    }
}

struct PronounceButton: View {
    @Binding var isAnimating: Bool
    var action: () -> Void

    var body: some View {
        Button {
            isAnimating = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isAnimating = false
            }
        } label: {
            ZStack {
                if isAnimating {
                    Circle()
                        .stroke(Color.freshGreen.opacity(0.4), lineWidth: 2)
                        .frame(width: 64, height: 64)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: isAnimating)
                }
                Circle()
                    .fill(Color.freshGreen.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(Color.freshGreen)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Play pronunciation")
    }
}

struct FavoritesView: View {
    @Query private var favorites: [Word]

    init() {
        _favorites = Query(filter: #Predicate<Word> { $0.isFavorite == true }, sort: [SortDescriptor(\.term)])
    }

    var body: some View {
        List {
            ForEach(favorites) { word in
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.term)
                        .font(.headline)
                    Text("\(word.definition) · \(word.phonetic)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Favorites")
    }
}

struct PracticeHubView: View {
    @Query private var stats: [DailyStats]
    var settings: UserSettings

    var body: some View {
        NavigationStack {
            List {
                Section {
                    let todayStats = stats.first(where: { Calendar.current.isDateInToday($0.date) })
                    let learned = todayStats?.learnedCount ?? 0
                    let goal = max(settings.dailyGoal ?? 20, 1)
                    ProgressHeaderView(
                        title: "Practice Today",
                        subtitle: "\(learned) / \(goal) words learned",
                        progress: min(Double(learned) / Double(goal), 1)
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Practice Types") {
                    ForEach(PracticeType.allCases) { practice in
                        NavigationLink {
                            PracticeSessionView(type: practice, settings: settings)
                        } label: {
                            HStack {
                                Image(systemName: practice.icon)
                                    .foregroundStyle(Color.warmBlue)
                                VStack(alignment: .leading) {
                                    Text(practice.title)
                                        .font(.headline)
                                    Text(practice.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Practice")
        }
    }
}

struct PracticeSessionView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @StateObject private var viewModel = PracticeSessionViewModel()
    let type: PracticeType
    let settings: UserSettings
    @State private var remainingPlays = 3

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isCompleted {
                PracticeResultView(
                    correct: viewModel.correctCount,
                    total: viewModel.questions.count,
                    totalTime: viewModel.totalTime,
                    wrongQuestions: viewModel.wrongQuestions
                )
            } else {
                if let question = viewModel.currentQuestion {
                    PracticeHeaderView(
                        index: viewModel.currentIndex + 1,
                        total: viewModel.questions.count,
                        timeRemaining: viewModel.timeRemaining
                    )

                    QuestionView(
                        question: question,
                        selectedOption: viewModel.selectedOption,
                        answerResult: viewModel.answerResult,
                        textAnswer: $viewModel.textAnswer,
                        showHint: $viewModel.showHint,
                        onOptionSelected: viewModel.submitOption,
                        onSubmitText: viewModel.submitTextAnswer,
                        remainingPlays: remainingPlays,
                        onPlay: {
                            if remainingPlays > 0 {
                                remainingPlays -= 1
                                SpeechService.shared.speak(text: question.word.term, rate: settings.speechRate)
                            }
                        }
                    )
                } else {
                    ProgressView("Loading questions...")
                }
            }
        }
        .padding()
        .navigationTitle(type.title)
        .onAppear {
            viewModel.configure(type: type, words: words, context: context, settings: settings)
            remainingPlays = 3
            if (settings.autoPlay ?? true), let question = viewModel.currentQuestion, question.type == .listening {
                SpeechService.shared.speak(text: question.word.term, rate: settings.speechRate)
            }
        }
        .onChange(of: viewModel.currentIndex) { _ in
            remainingPlays = 3
            if (settings.autoPlay ?? true), let question = viewModel.currentQuestion, question.type == .listening {
                SpeechService.shared.speak(text: question.word.term, rate: settings.speechRate)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            viewModel.tick()
        }
    }
}

struct PracticeHeaderView: View {
    let index: Int
    let total: Int
    let timeRemaining: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Question \(index)/\(total)")
                    .font(.headline)
                Spacer()
                Text("\(timeRemaining)s")
                    .font(.headline)
                    .foregroundStyle(timeRemaining > 10 ? Color.freshGreen : Color.red)
            }
            ProgressView(value: Double(index), total: Double(max(total, 1)))
                .tint(Color.warmBlue)
        }
    }
}

struct QuestionView: View {
    let question: PracticeQuestion
    let selectedOption: String?
    let answerResult: Bool?
    @Binding var textAnswer: String
    @Binding var showHint: Bool
    let onOptionSelected: (String) -> Void
    let onSubmitText: () -> Void
    let remainingPlays: Int
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(question.prompt)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            if question.type == .listening {
                Button("Play (\(remainingPlays))") {
                    onPlay()
                }
                .buttonStyle(.borderedProminent)
                .disabled(remainingPlays == 0)
                .accessibilityLabel("Play audio")
            }

            if question.type == .fillBlank {
                TextField("Type the word", text: $textAnswer)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit {
                        onSubmitText()
                    }

                Button(showHint ? "Hint: \(question.hint)" : "Show hint") {
                    showHint.toggle()
                }
                .buttonStyle(.bordered)

                Button("Submit") {
                    onSubmitText()
                }
                .buttonStyle(.borderedProminent)
                .disabled(textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        Button {
                            onOptionSelected(option)
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if answerResult != nil {
                                    Image(systemName: option == question.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(option == question.answer ? Color.freshGreen : Color.red)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(optionBackground(option: option))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(answerResult != nil)
                    }
                }
            }

            if let result = answerResult {
                Text(result ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundStyle(result ? Color.freshGreen : Color.red)
            }

            Text("Example: \(question.example)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }

    private func optionBackground(option: String) -> Color {
        if let result = answerResult {
            if option == question.answer {
                return Color.freshGreen.opacity(0.2)
            }
            if option == selectedOption {
                return Color.red.opacity(0.2)
            }
        }
        return Color.warmBlue.opacity(0.1)
    }
}

struct PracticeResultView: View {
    let correct: Int
    let total: Int
    let totalTime: TimeInterval
    let wrongQuestions: [PracticeQuestion]

    var body: some View {
        VStack(spacing: 16) {
            Text("Session Complete")
                .font(.title2.bold())
            Text("Accuracy: \(Int((Double(correct) / Double(max(total, 1))) * 100))%")
                .font(.headline)
            Text("Time: \(Int(totalTime))s")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Correct: \(correct) / \(total)")
                .font(.subheadline)

            if !wrongQuestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review Mistakes")
                        .font(.headline)
                    ForEach(wrongQuestions) { question in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(question.word.term)
                                .font(.subheadline.bold())
                            Text(question.word.definition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.08))
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.freshGreen.opacity(0.1))
        )
    }
}

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @Query(sort: [SortDescriptor<DailyStats>(\DailyStats.date, order: .reverse)]) private var stats: [DailyStats]
    @Query private var achievements: [Achievement]
    var settings: UserSettings
    @State private var chartScope: ChartScope = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    DailyStatsCard(stats: stats)
                    StreakCard(streak: StatsService.streak(from: stats))
                    VocabularyRingCard(words: words)
                    ChartCard(stats: stats, scope: $chartScope)
                    AchievementsCard(achievements: achievements)
                }
                .padding()
            }
            .navigationTitle("Progress")
            .task {
                AchievementService.updateAchievements(
                    context: context,
                    stats: stats,
                    words: words,
                    settings: settings,
                    achievements: achievements
                )
            }
        }
    }
}

enum ChartScope: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

struct DailyStatsCard: View {
    let stats: [DailyStats]

    var body: some View {
        let today = stats.first(where: { Calendar.current.isDateInToday($0.date) })
        let yesterday = stats.first(where: { Calendar.current.isDateInYesterday($0.date) })
        let learnedToday = today?.learnedCount ?? 0
        let learnedYesterday = yesterday?.learnedCount ?? 0
        let delta = learnedToday - learnedYesterday

        return VStack(alignment: .leading, spacing: 12) {
            Text("Daily Summary")
                .font(.headline)
            HStack {
                VStack(alignment: .leading) {
                    Text("\(learnedToday)")
                        .font(.title.bold())
                    Text("Words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("\(Int((today?.accuracy ?? 0) * 100))%")
                        .font(.title.bold())
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("\(Int(today?.studySeconds ?? 0))s")
                        .font(.title.bold())
                    Text("Study time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(delta >= 0 ? "+\(delta) vs yesterday" : "\(delta) vs yesterday")
                .font(.caption)
                .foregroundStyle(delta >= 0 ? Color.freshGreen : Color.red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

struct StreakCard: View {
    let streak: Int
    @State private var animate = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Streak")
                .font(.headline)
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(Color.orange)
                    .scaleEffect(animate ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animate)
                Text("\(streak) days")
                    .font(.title2.bold())
            }
            Text("Keep the streak alive")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
        .onAppear {
            animate = true
        }
    }
}

struct VocabularyRingCard: View {
    let words: [Word]

    var body: some View {
        let total = max(words.count, 1)
        let mastered = words.filter { $0.status == .mastered }.count
        let learning = words.filter { $0.status == .learning }.count
        let newCount = total - mastered - learning

        return VStack(alignment: .leading, spacing: 12) {
            Text("Vocabulary")
                .font(.headline)
            HStack(spacing: 16) {
                ProgressRingView(progress: Double(mastered) / Double(total))
                VStack(alignment: .leading, spacing: 6) {
                    Label("Mastered \(mastered)", systemImage: "checkmark.seal")
                    Label("Learning \(learning)", systemImage: "arrow.triangle.2.circlepath")
                    Label("New \(newCount)", systemImage: "sparkles")
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.freshGreen, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
        }
        .frame(width: 80, height: 80)
    }
}

struct ChartCard: View {
    let stats: [DailyStats]
    @Binding var scope: ChartScope

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Study Trend")
                    .font(.headline)
                Spacer()
                Picker("Scope", selection: $scope) {
                    ForEach(ChartScope.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            Chart {
                ForEach(filteredStats) { stat in
                    LineMark(
                        x: .value("Date", stat.date),
                        y: .value("Learned", stat.learnedCount)
                    )
                    .foregroundStyle(Color.warmBlue)
                    PointMark(
                        x: .value("Date", stat.date),
                        y: .value("Learned", stat.learnedCount)
                    )
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }

    private var filteredStats: [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = scope == .week ? 7 : 30
        let start = calendar.date(byAdding: .day, value: -days + 1, to: today) ?? today
        return stats.filter { $0.date >= start }.sorted { $0.date < $1.date }
    }
}

struct AchievementsCard: View {
    let achievements: [Achievement]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achievements) { achievement in
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: achievement.iconName)
                            .foregroundStyle(achievement.isEarned ? Color.freshGreen : Color.secondary)
                        Text(achievement.title)
                            .font(.subheadline.bold())
                        Text(achievement.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(achievement.isEarned ? Color.freshGreen.opacity(0.12) : Color.gray.opacity(0.08))
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
        )
    }
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var words: [Word]
    @Query private var stats: [DailyStats]
    @Query private var achievements: [Achievement]
    @Query private var attempts: [PracticeAttempt]
    var settings: UserSettings

    @State private var isExporting = false
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Learning") {
                    Picker("Daily Goal", selection: Binding(
                        get: { settings.dailyGoal ?? 20 },
                        set: { newValue in
                            settings.dailyGoal = newValue
                            save()
                        }
                    )) {
                        Text("10").tag(10)
                        Text("20").tag(20)
                        Text("30").tag(30)
                        Text("50").tag(50)
                    }

                    DatePicker("Reminder Time", selection: Binding(
                        get: { settings.reminderDate },
                        set: { newValue in
                            settings.reminderDate = newValue
                            save()
                        }
                    ), displayedComponents: .hourAndMinute)

                    Toggle("Auto Play Pronunciation", isOn: Binding(
                        get: { settings.autoPlay ?? true },
                        set: { newValue in
                            settings.autoPlay = newValue
                            save()
                        }
                    ))
                }

                Section("Speech") {
                    Picker("Speech Rate", selection: Binding(
                        get: { settings.speechRate },
                        set: { newValue in
                            settings.speechRate = newValue
                            save()
                        }
                    )) {
                        ForEach(SpeechRateOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                }

                Section("Display") {
                    Picker("Theme", selection: Binding(
                        get: { settings.themeMode },
                        set: { newValue in
                            settings.themeMode = newValue
                            save()
                        }
                    )) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }

                    Picker("Font Size", selection: Binding(
                        get: { settings.fontScale },
                        set: { newValue in
                            settings.fontScale = newValue
                            save()
                        }
                    )) {
                        ForEach(FontScale.allCases) { scale in
                            Text(scale.label).tag(scale)
                        }
                    }
                }

                Section("Notifications") {
                    Toggle("Enable Reminders", isOn: Binding(
                        get: { settings.notificationsEnabled ?? false },
                        set: { newValue in
                            settings.notificationsEnabled = newValue
                            Task {
                                await updateNotifications(enabled: newValue)
                            }
                        }
                    ))
                }

                Section("Data") {
                    Button("Export Study Data") {
                        exportDocument = ExportDocument(data: exportData())
                        isExporting = true
                    }

                    Button("Reset All Data", role: .destructive) {
                        showResetConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "LingoLearnData") { _ in }
            .confirmationDialog("Reset all data?", isPresented: $showResetConfirm) {
                Button("Reset", role: .destructive) {
                    resetAll()
                }
            }
        }
    }

    private func save() {
        try? context.save()
    }

    private func updateNotifications(enabled: Bool) async {
        if enabled {
            let granted = await NotificationService.shared.requestAuthorization()
            settings.notificationsEnabled = granted
            if granted {
                await NotificationService.shared.clearAll()
                await NotificationService.shared.scheduleDailyReminder(settings: settings)
                await NotificationService.shared.scheduleStreakReminder(hour: 21, minute: 0)
            }
        } else {
            await NotificationService.shared.clearAll()
        }
        save()
    }

    private func exportData() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let payload = ExportPayload(words: words, stats: stats, achievements: achievements)
        return (try? encoder.encode(payload)) ?? Data()
    }

    private func resetAll() {
        words.forEach { context.delete($0) }
        stats.forEach { context.delete($0) }
        achievements.forEach { context.delete($0) }
        attempts.forEach { context.delete($0) }
        try? context.save()
        Task {
            await SeedDataLoader.seedIfNeeded(context: context)
        }
    }
}

struct ExportPayload: Codable {
    let words: [ExportWord]
    let stats: [ExportStats]
    let achievements: [ExportAchievement]

    init(words: [Word], stats: [DailyStats], achievements: [Achievement]) {
        self.words = words.map { ExportWord(word: $0) }
        self.stats = stats.map { ExportStats(stats: $0) }
        self.achievements = achievements.map { ExportAchievement(achievement: $0) }
    }
}

struct ExportWord: Codable {
    let term: String
    let definition: String
    let phonetic: String
    let partOfSpeech: String
    let status: String
    let isFavorite: Bool
    let correctCount: Int
    let incorrectCount: Int

    init(word: Word) {
        term = word.term
        definition = word.definition
        phonetic = word.phonetic
        partOfSpeech = word.partOfSpeech
        status = word.status.label
        isFavorite = word.isFavorite
        correctCount = word.correctCount
        incorrectCount = word.incorrectCount
    }
}

struct ExportStats: Codable {
    let date: Date
    let learnedCount: Int
    let correctCount: Int
    let totalCount: Int
    let studySeconds: TimeInterval

    init(stats: DailyStats) {
        date = stats.date
        learnedCount = stats.learnedCount
        correctCount = stats.correctCount
        totalCount = stats.totalCount
        studySeconds = stats.studySeconds
    }
}

struct ExportAchievement: Codable {
    let title: String
    let detail: String
    let isEarned: Bool
    let achievedAt: Date?

    init(achievement: Achievement) {
        title = achievement.title
        detail = achievement.detail
        isEarned = achievement.isEarned
        achievedAt = achievement.achievedAt
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, PracticeAttempt.self, DailyStats.self, Achievement.self, UserSettings.self], inMemory: true)
}
