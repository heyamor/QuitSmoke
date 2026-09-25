import Foundation

struct QuitMetrics {
    let elapsed: TimeInterval
    let fewerCigarettes: Int
    let moneySaved: Double
    let smokeFreeStreak: Int
    let totalCravings: Int
    let resistedCravings: Int

    var resistedRate: Int {
        guard totalCravings > 0 else { return 0 }
        return Int((Double(resistedCravings) / Double(totalCravings) * 100).rounded())
    }
}

enum MetricsCalculator {
    static func calculate(data: AppData, now: Date = Date(), calendar: Calendar = .current) -> QuitMetrics {
        let currentStart = data.currentAttempt?.startedAt ?? data.profile.originalQuitDate
        let elapsed = max(0, now.timeIntervalSince(currentStart))
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
            fewerCigarettes: fewer,
            moneySaved: saved,
            smokeFreeStreak: streak,
            totalCravings: data.cravings.count,
            resistedCravings: resisted
        )
    }

    private static func maxDate(_ lhs: Date, _ rhs: Date?) -> Date {
        guard let rhs else { return lhs }
        return max(lhs, rhs)
    }
}

