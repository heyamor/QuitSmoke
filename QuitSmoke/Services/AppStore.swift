import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData
    @Published var lastSaveError: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = baseURL.appendingPathComponent("QuitSmoke", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("quit-smoke-data.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let raw = try? Data(contentsOf: fileURL),
           let saved = try? decoder.decode(AppData.self, from: raw) {
            data = saved
        } else {
            data = AppData()
        }
    }

    var metrics: QuitMetrics { MetricsCalculator.calculate(data: data) }

    func completeSetup(startDate: Date, cigarettesPerDay: Int, cigarettesPerPack: Int, pricePerPack: Double) {
        var updated = data
        updated.hasCompletedSetup = true
        updated.profile = QuitProfile(
            originalQuitDate: startDate,
            cigarettesPerDay: max(1, cigarettesPerDay),
            cigarettesPerPack: max(1, cigarettesPerPack),
            pricePerPack: max(0, pricePerPack)
        )
        updated.attempts = [QuitAttempt(startedAt: startDate)]
        commit(updated)
    }

    func updateProfile(cigarettesPerDay: Int, cigarettesPerPack: Int, pricePerPack: Double) {
        var updated = data
        updated.profile.cigarettesPerDay = max(1, cigarettesPerDay)
        updated.profile.cigarettesPerPack = max(1, cigarettesPerPack)
        updated.profile.pricePerPack = max(0, pricePerPack)
        commit(updated)
    }

    func checkIn(status: DailyCheckIn.Status, cigarettes: Int = 0, now: Date = Date(), calendar: Calendar = .current) {
        var updated = data
        let startOfToday = calendar.startOfDay(for: now)
        updated.checkIns.removeAll { calendar.isDate($0.date, inSameDayAs: startOfToday) }
        updated.checkIns.append(DailyCheckIn(
            date: now,
            status: status,
            cigarettesSmoked: status == .smoked ? max(1, cigarettes) : 0
        ))
        updated.checkIns.sort { $0.date > $1.date }
        commit(updated)
    }

    func addCraving(intensity: Int, trigger: String, resisted: Bool, date: Date = Date()) {
        var updated = data
        updated.cravings.append(CravingRecord(
            date: date,
            intensity: min(5, max(1, intensity)),
            trigger: trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未填写" : trigger,
            resisted: resisted
        ))
        updated.cravings.sort { $0.date > $1.date }
        commit(updated)
    }

    func restartAttempt(at date: Date = Date()) {
        var updated = data
        if let index = updated.attempts.lastIndex(where: { $0.endedAt == nil }) {
            updated.attempts[index].endedAt = date
        }
        updated.attempts.append(QuitAttempt(startedAt: date))
        commit(updated)
    }

    func setReminder(enabled: Bool, hour: Int, minute: Int) {
        var updated = data
        updated.reminder = ReminderSettings(enabled: enabled, hour: hour, minute: minute)
        commit(updated)
    }

    func deleteCraving(id: UUID) {
        var updated = data
        updated.cravings.removeAll { $0.id == id }
        commit(updated)
    }

    private func commit(_ updated: AppData) {
        data = updated
        do {
            let encoded = try encoder.encode(updated)
            try encoded.write(to: fileURL, options: [.atomic, .completeFileProtection])
            lastSaveError = nil
        } catch {
            lastSaveError = "数据保存失败：\(error.localizedDescription)"
        }
    }
}

