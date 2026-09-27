import Foundation

struct QuitMetrics {
    let elapsed: TimeInterval
    let longestElapsed: TimeInterval
    let fewerCigarettes: Int
    let moneySaved: Double
    let smokeFreeStreak: Int
    let relapseCount: Int
    let recoveryProgress: Double
    let currentRecoveryStage: HealthRecoveryMilestone
    let nextRecoveryStage: HealthRecoveryMilestone?

    var recoveryPercent: Int {
        Int((recoveryProgress * 100).rounded())
    }
}

/// A motivational timeline based on smoke-free time. It is not a medical measurement.
struct HealthRecoveryMilestone: Identifiable, Equatable {
    let id: Int
    let hours: Double
    let targetPercent: Int
    let title: String
    let subtitle: String

    static let all: [HealthRecoveryMilestone] = [
        HealthRecoveryMilestone(id: 1, hours: 0, targetPercent: 0, title: "起点", subtitle: "从现在开始记录每一个无烟时刻"),
        HealthRecoveryMilestone(id: 2, hours: 24, targetPercent: 10, title: "无烟一日", subtitle: "完成第一个完整无烟日"),
        HealthRecoveryMilestone(id: 3, hours: 72, targetPercent: 20, title: "三天", subtitle: "新的生活节奏正在建立"),
        HealthRecoveryMilestone(id: 4, hours: 168, targetPercent: 30, title: "一周", subtitle: "把改变慢慢变成日常"),
        HealthRecoveryMilestone(id: 5, hours: 720, targetPercent: 45, title: "一个月", subtitle: "坚持已经留下清晰的痕迹"),
        HealthRecoveryMilestone(id: 6, hours: 2_160, targetPercent: 60, title: "三个月", subtitle: "继续把注意力放回自己"),
        HealthRecoveryMilestone(id: 7, hours: 8_760, targetPercent: 75, title: "一年", subtitle: "完成一整年的新生活"),
        HealthRecoveryMilestone(id: 8, hours: 43_800, targetPercent: 88, title: "五年", subtitle: "长期坚持成为生活的一部分"),
        HealthRecoveryMilestone(id: 9, hours: 87_600, targetPercent: 95, title: "十年", subtitle: "继续保持新的选择"),
        HealthRecoveryMilestone(id: 10, hours: 131_400, targetPercent: 100, title: "十五年", subtitle: "达到长期恢复里程碑")
    ]
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

        let recovery = recoveryDetails(elapsed: elapsed)
        return QuitMetrics(
            elapsed: elapsed,
            longestElapsed: max(longestElapsed, elapsed),
            fewerCigarettes: fewer,
            moneySaved: saved,
            smokeFreeStreak: streak,
            relapseCount: data.relapses.count,
            recoveryProgress: recovery.progress,
            currentRecoveryStage: recovery.current,
            nextRecoveryStage: recovery.next
        )
    }

    private static func recoveryDetails(elapsed: TimeInterval) -> (
        progress: Double,
        current: HealthRecoveryMilestone,
        next: HealthRecoveryMilestone?
    ) {
        let hours = max(0, elapsed / 3_600)
        let milestones = HealthRecoveryMilestone.all
        let current = milestones.last(where: { hours >= $0.hours }) ?? milestones[0]
        guard let nextIndex = milestones.firstIndex(where: { hours < $0.hours }) else {
            return (1, current, nil)
        }

        let next = milestones[nextIndex]
        let previous = milestones[max(0, nextIndex - 1)]
        let segmentLength = max(0.001, next.hours - previous.hours)
        let segmentProgress = min(1, max(0, (hours - previous.hours) / segmentLength))
        let percent = Double(previous.targetPercent)
            + segmentProgress * Double(next.targetPercent - previous.targetPercent)
        return (min(1, max(0, percent / 100)), current, next)
    }

    private static func maxDate(_ lhs: Date, _ rhs: Date?) -> Date {
        guard let rhs else { return lhs }
        return max(lhs, rhs)
    }
}
