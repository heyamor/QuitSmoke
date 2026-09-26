import Foundation

struct AppData: Codable, Equatable {
    var hasCompletedSetup = false
    var profile = QuitProfile()
    var attempts: [QuitAttempt] = []
    var checkIns: [DailyCheckIn] = []
    var cravings: [CravingRecord] = []
    var relapses: [RelapseRecord] = []
    var wellnessEntries: [WellnessEntry] = []
    var customTriggers: [String] = []
    var reminder = ReminderSettings()

    init(
        hasCompletedSetup: Bool = false,
        profile: QuitProfile = QuitProfile(),
        attempts: [QuitAttempt] = [],
        checkIns: [DailyCheckIn] = [],
        cravings: [CravingRecord] = [],
        relapses: [RelapseRecord] = [],
        wellnessEntries: [WellnessEntry] = [],
        customTriggers: [String] = [],
        reminder: ReminderSettings = ReminderSettings()
    ) {
        self.hasCompletedSetup = hasCompletedSetup
        self.profile = profile
        self.attempts = attempts
        self.checkIns = checkIns
        self.cravings = cravings
        self.relapses = relapses
        self.wellnessEntries = wellnessEntries
        self.customTriggers = customTriggers
        self.reminder = reminder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedSetup) ?? false
        profile = try container.decodeIfPresent(QuitProfile.self, forKey: .profile) ?? QuitProfile()
        attempts = try container.decodeIfPresent([QuitAttempt].self, forKey: .attempts) ?? []
        checkIns = try container.decodeIfPresent([DailyCheckIn].self, forKey: .checkIns) ?? []
        cravings = try container.decodeIfPresent([CravingRecord].self, forKey: .cravings) ?? []
        relapses = try container.decodeIfPresent([RelapseRecord].self, forKey: .relapses) ?? []
        wellnessEntries = try container.decodeIfPresent([WellnessEntry].self, forKey: .wellnessEntries) ?? []
        customTriggers = try container.decodeIfPresent([String].self, forKey: .customTriggers) ?? []
        reminder = try container.decodeIfPresent(ReminderSettings.self, forKey: .reminder) ?? ReminderSettings()
    }

    var currentAttempt: QuitAttempt? {
        attempts.last(where: { $0.endedAt == nil }) ?? attempts.last
    }
}

struct QuitProfile: Codable, Equatable {
    var originalQuitDate = Date()
    var cigarettesPerDay = 10
    var cigarettesPerPack = 20
    var pricePerPack = 30.0
    var smokingYears = 0

    init(
        originalQuitDate: Date = Date(),
        cigarettesPerDay: Int = 10,
        cigarettesPerPack: Int = 20,
        pricePerPack: Double = 30.0,
        smokingYears: Int = 0
    ) {
        self.originalQuitDate = originalQuitDate
        self.cigarettesPerDay = cigarettesPerDay
        self.cigarettesPerPack = cigarettesPerPack
        self.pricePerPack = pricePerPack
        self.smokingYears = smokingYears
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        originalQuitDate = try container.decodeIfPresent(Date.self, forKey: .originalQuitDate) ?? Date()
        cigarettesPerDay = try container.decodeIfPresent(Int.self, forKey: .cigarettesPerDay) ?? 10
        cigarettesPerPack = try container.decodeIfPresent(Int.self, forKey: .cigarettesPerPack) ?? 20
        pricePerPack = try container.decodeIfPresent(Double.self, forKey: .pricePerPack) ?? 30.0
        smokingYears = try container.decodeIfPresent(Int.self, forKey: .smokingYears) ?? 0
    }
}

struct QuitAttempt: Identifiable, Codable, Equatable {
    var id = UUID()
    var startedAt: Date
    var endedAt: Date?
}

struct DailyCheckIn: Identifiable, Codable, Equatable {
    enum Status: String, Codable {
        case smokeFree
        case smoked
    }

    var id = UUID()
    var date: Date
    var status: Status
    var cigarettesSmoked: Int
}

struct CravingRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var intensity: Int
    var trigger: String
    var resisted: Bool
    var emotion: String
    var note: String

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        intensity: Int,
        trigger: String,
        resisted: Bool,
        emotion: String = "",
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.intensity = intensity
        self.trigger = trigger
        self.resisted = resisted
        self.emotion = emotion
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        intensity = try container.decodeIfPresent(Int.self, forKey: .intensity) ?? 3
        trigger = try container.decodeIfPresent(String.self, forKey: .trigger) ?? "未填写"
        resisted = try container.decodeIfPresent(Bool.self, forKey: .resisted) ?? false
        emotion = try container.decodeIfPresent(String.self, forKey: .emotion) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }
}

struct RelapseRecord: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var cigarettes: Int
    var reason: String
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), cigarettes: Int, reason: String, note: String = "") {
        self.id = id
        self.date = date
        self.cigarettes = cigarettes
        self.reason = reason
        self.note = note
    }
}

struct WellnessEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var weight: Double?
    var sleepHours: Double?
    var energy: Int?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weight: Double? = nil,
        sleepHours: Double? = nil,
        energy: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.sleepHours = sleepHours
        self.energy = energy
    }
}

struct ReminderTime: Identifiable, Codable, Equatable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var label: String

    init(id: UUID = UUID(), hour: Int, minute: Int, label: String = "自定义提醒") {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
    }
}

struct ReminderSettings: Codable, Equatable {
    var enabled = false
    var hour = 20
    var minute = 0
    var times: [ReminderTime] = []

    init(enabled: Bool = false, hour: Int = 20, minute: Int = 0, times: [ReminderTime] = []) {
        self.enabled = enabled
        self.hour = hour
        self.minute = minute
        self.times = times
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        hour = try container.decodeIfPresent(Int.self, forKey: .hour) ?? 20
        minute = try container.decodeIfPresent(Int.self, forKey: .minute) ?? 0
        times = try container.decodeIfPresent([ReminderTime].self, forKey: .times) ?? []
        if times.isEmpty && enabled {
            times = [ReminderTime(hour: hour, minute: minute)]
        }
    }

    var effectiveTimes: [ReminderTime] {
        if times.isEmpty && enabled { return [ReminderTime(hour: hour, minute: minute)] }
        return times
    }
}
