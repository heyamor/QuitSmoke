import Foundation

struct AppData: Codable, Equatable {
    var hasCompletedSetup = false
    var profile = QuitProfile()
    var attempts: [QuitAttempt] = []
    var checkIns: [DailyCheckIn] = []
    var cravings: [CravingRecord] = []
    var reminder = ReminderSettings()

    var currentAttempt: QuitAttempt? {
        attempts.last(where: { $0.endedAt == nil }) ?? attempts.last
    }
}

struct QuitProfile: Codable, Equatable {
    var originalQuitDate = Date()
    var cigarettesPerDay = 10
    var cigarettesPerPack = 20
    var pricePerPack = 30.0
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
}

struct ReminderSettings: Codable, Equatable {
    var enabled = false
    var hour = 20
    var minute = 0
}

