import Foundation

struct QuitMetrics {
    let elapsed: TimeInterval
    let longestElapsed: TimeInterval
    let fewerCigarettes: Int
    let moneySaved: Double
    let smokeFreeStreak: Int
    let totalCravings: Int
    let resistedCravings: Int
    let relapseCount: Int

    var resistedRate: Int {
        guard totalCravings > 0 else { return 0 }
        return Int((Double(resistedCravings) / Double(totalCravings) * 100).rounded())
    }
}

struct RecoveryMilestone: Identifiable {
    let id: Int
    let hours: Double
    let title: String
    let subtitle: String

    static let all: [RecoveryMilestone] = [
        RecoveryMilestone(id: 1, hours: 1, title: "第一个小时", subtitle: "开始把注意力放回自己"),
        RecoveryMilestone(id: 2, hours: 12, title: "半天", subtitle: "稳定度过一个重要节点"),
        RecoveryMilestone(id: 3, hours: 24, title: "无烟一日", subtitle: "完成第一个完整无烟日"),
        RecoveryMilestone(id: 4, hours: 72, title: "三天", subtitle: "继续建立新的节奏"),
        RecoveryMilestone(id: 5, hours: 168, title: "一周", subtitle: "一周的选择已经留下痕迹"),
        RecoveryMilestone(id: 6, hours: 720, title: "一个月", subtitle: "把改变变成日常"),
        RecoveryMilestone(id: 7, hours: 2160, title: "三个月", subtitle: "长期坚持的里程碑"),
        RecoveryMilestone(id: 8, hours: 8760, title: "一年", subtitle: "完成一整年的新生活")
    ]

    func progress(elapsed: TimeInterval) -> Double {
        min(1, max(0, elapsed / (hours * 3_600)))
    }
}

enum MetricsCalculator {
    static func calculate(data: AppData, now: Date = Date(), calendar: Calendar = .current) -> QuitMetrics {
        let currentStart = data.currentAttempt?.startedAt ?? data.profile.originalQuitDate
        let elapsed = max(0, now.timeIntervalSince(currentStart))
        let longestElapsed = data.attempts.map { attempt in
            max(0, (attempt.endedAt ?? now).timeIntervalSince(attempt.startedAt))
        }.max() ?? elapsed
        let overallElapsed = max(0, now.timeIntervalSince(data.profile.originalQuitDate))
        let expected = Int((overallElapsed / 86_400) * Double(data.profile.cigarettesPerDay))
        let smoked = data.checkIns.reduce(0) { $0 + max(0, $1.cigarettesSmoked) }
        let fewer = max(0, expected - smoked)
        let unitPrice = data.profile.pricePerPack / Double(max(1, data.profile.cigarettesPerPack))
        let saved = Double(fewer) * unitPrice

        let latestSmokeDate = data.checkIns
            .filter { $0.status == .smoked && $0.cigarettesSmoked > 0 }
            .map(\.date)
            .max()
        let streakStart = maxDate(currentStart, latestSmokeDate.map { calendar.startOfDay(for: $0).addingTimeInterval(86_400) })
        let streak = max(0, calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: streakStart),
            to: calendar.startOfDay(for: now)
        ).day ?? 0)

        let resisted = data.cravings.filter(\.resisted).count
        return QuitMetrics(
            elapsed: elapsed,
            longestElapsed: max(longestElapsed, elapsed),
            fewerCigarettes: fewer,
            moneySaved: saved,
            smokeFreeStreak: streak,
            totalCravings: data.cravings.count,
            resistedCravings: resisted,
            relapseCount: data.relapses.count
        )
    }

    private static func maxDate(_ lhs: Date, _ rhs: Date?) -> Date {
        guard let rhs else { return lhs }
        return max(lhs, rhs)
    }
}
