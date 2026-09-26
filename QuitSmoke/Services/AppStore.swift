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
        self.fileURL = folder.appendingPathComponent("quit-smoke-data.json")

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

    func completeSetup(startDate: Date, cigarettesPerDay: Int, cigarettesPerPack: Int, pricePerPack: Double, smokingYears: Int = 0) {
        var updated = data
        updated.hasCompletedSetup = true
        updated.profile = QuitProfile(
            originalQuitDate: startDate,
            cigarettesPerDay: max(1, cigarettesPerDay),
            cigarettesPerPack: max(1, cigarettesPerPack),
            pricePerPack: max(0, pricePerPack),
            smokingYears: max(0, smokingYears)
        )
        updated.attempts = [QuitAttempt(startedAt: startDate)]
        commit(updated)
    }

    func updateProfile(cigarettesPerDay: Int, cigarettesPerPack: Int, pricePerPack: Double, smokingYears: Int? = nil) {
        var updated = data
        updated.profile.cigarettesPerDay = max(1, cigarettesPerDay)
        updated.profile.cigarettesPerPack = max(1, cigarettesPerPack)
        updated.profile.pricePerPack = max(0, pricePerPack)
        if let smokingYears {
            updated.profile.smokingYears = max(0, smokingYears)
        }
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

    func addCraving(
        intensity: Int,
        trigger: String,
        resisted: Bool,
        emotion: String = "",
        note: String = "",
        date: Date = Date()
    ) {
        var updated = data
        let cleanTrigger = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTrigger = cleanTrigger.isEmpty ? "未填写" : cleanTrigger
        updated.cravings.append(CravingRecord(
            date: date,
            intensity: min(5, max(1, intensity)),
            trigger: normalizedTrigger,
            resisted: resisted,
            emotion: emotion.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        if !cleanTrigger.isEmpty && !updated.customTriggers.contains(cleanTrigger) {
            updated.customTriggers.append(cleanTrigger)
            updated.customTriggers.sort()
        }
        updated.cravings.sort { $0.date > $1.date }
        commit(updated)
    }

    func addRelapse(cigarettes: Int, reason: String, note: String = "", date: Date = Date()) {
        var updated = data
        updated.relapses.append(RelapseRecord(
            date: date,
            cigarettes: max(1, cigarettes),
            reason: reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未填写" : reason,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        updated.relapses.sort { $0.date > $1.date }
        commit(updated)
    }

    func deleteRelapse(id: UUID) {
        var updated = data
        updated.relapses.removeAll { $0.id == id }
        commit(updated)
    }

    func addWellnessEntry(weight: Double?, sleepHours: Double?, energy: Int?, date: Date = Date()) {
        var updated = data
        updated.wellnessEntries.append(WellnessEntry(
            date: date,
            weight: weight,
            sleepHours: sleepHours,
            energy: energy
        ))
        updated.wellnessEntries.sort { $0.date > $1.date }
        commit(updated)
    }

    func deleteWellnessEntry(id: UUID) {
        var updated = data
        updated.wellnessEntries.removeAll { $0.id == id }
        commit(updated)
    }

    func addCustomTrigger(_ trigger: String) {
        let clean = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        var updated = data
        guard !updated.customTriggers.contains(clean) else { return }
        updated.customTriggers.append(clean)
        updated.customTriggers.sort()
        commit(updated)
    }

    func deleteCustomTrigger(_ trigger: String) {
        var updated = data
        updated.customTriggers.removeAll { $0 == trigger }
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
        setReminders(enabled: enabled, times: [ReminderTime(hour: hour, minute: minute)])
    }

    func setReminders(enabled: Bool, times: [ReminderTime]) {
        var updated = data
        let first = times.first ?? ReminderTime(hour: 20, minute: 0)
        updated.reminder = ReminderSettings(
            enabled: enabled,
            hour: first.hour,
            minute: first.minute,
            times: times
        )
        commit(updated)
    }

    func deleteCraving(id: UUID) {
        var updated = data
        updated.cravings.removeAll { $0.id == id }
        commit(updated)
    }

    func exportJSONData() throws -> Data {
        try encoder.encode(data)
    }

    func exportCSVData() throws -> Data {
        let formatter = ISO8601DateFormatter()
        var rows = [
            csvRow(["类型", "时间", "状态", "数量", "强度", "触发场景", "情绪", "原因", "是否扛过", "备注", "体重", "睡眠小时", "精力"])
        ]

        for item in data.checkIns.sorted(by: { $0.date < $1.date }) {
            rows.append(csvRow([
                "每日打卡", formatter.string(from: item.date),
                item.status == .smokeFree ? "无烟" : "吸烟",
                item.status == .smoked ? "\(item.cigarettesSmoked)" : "",
                "", "", "", "", "", "", "", "", ""
            ]))
        }
        for item in data.cravings.sorted(by: { $0.date < $1.date }) {
            rows.append(csvRow([
                "烟瘾", formatter.string(from: item.date), "", "", "\(item.intensity)",
                item.trigger, item.emotion, "", item.resisted ? "是" : "否", item.note, "", "", ""
            ]))
        }
        for item in data.relapses.sorted(by: { $0.date < $1.date }) {
            rows.append(csvRow([
                "复吸", formatter.string(from: item.date), "", "\(item.cigarettes)", "", "", "", item.reason, "", item.note, "", "", ""
            ]))
        }
        for item in data.wellnessEntries.sorted(by: { $0.date < $1.date }) {
            rows.append(csvRow([
                "身体记录", formatter.string(from: item.date), "", "", "", "", "", "", "", "",
                item.weight.map { String(format: "%.1f", $0) } ?? "",
                item.sleepHours.map { String(format: "%.1f", $0) } ?? "",
                item.energy.map(String.init) ?? ""
            ]))
        }

        guard let result = rows.joined(separator: "\n").data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return result
    }

    private func csvRow(_ values: [String]) -> String {
        values.map { value in
            let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }.joined(separator: ",")
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
