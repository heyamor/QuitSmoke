import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    private var recentDays: [DaySummary] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let checkIn = store.data.checkIns.first { calendar.isDate($0.date, inSameDayAs: date) }
            let cravings = store.data.cravings.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return DaySummary(date: date, checkIn: checkIn, cravings: cravings)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overview
                weeklyChart
                recentRecords
                attempts
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("历史与统计")
    }

    private var overview: some View {
        HStack {
            StatItem(value: "\(store.data.checkIns.filter { $0.status == .smokeFree }.count)", label: "无烟打卡")
            Divider().frame(height: 42)
            StatItem(value: "\(store.data.cravings.count)", label: "烟瘾记录")
            Divider().frame(height: 42)
            StatItem(value: "\(store.metrics.resistedRate)%", label: "扛过率")
        }
        .appCard()
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最近 7 天").font(.headline)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(recentDays) { day in
                    VStack(spacing: 7) {
                        ZStack(alignment: .bottom) {
                            Capsule().fill(Color.secondary.opacity(0.1)).frame(height: 72)
                            Capsule()
                                .fill(day.color.gradient)
                                .frame(height: day.barHeight)
                        }
                        Text(day.weekday).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(day.weekday)，\(day.description)")
                }
            }
            HStack(spacing: 14) {
                Label("无烟", systemImage: "circle.fill").foregroundStyle(Theme.primary)
                Label("吸烟", systemImage: "circle.fill").foregroundStyle(Theme.warm)
                Label("未打卡", systemImage: "circle.fill").foregroundStyle(.secondary.opacity(0.35))
            }
            .font(.caption)
        }
        .appCard()
    }

    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近打卡").font(.headline)
            if store.data.checkIns.isEmpty {
                Text("完成今日打卡后会显示在这里。")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(store.data.checkIns.prefix(8)) { checkIn in
                    HStack {
                        Image(systemName: checkIn.status == .smokeFree ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(checkIn.status == .smokeFree ? Theme.primary : Theme.warm)
                        Text(AppFormatters.shortDate.string(from: checkIn.date))
                        Spacer()
                        Text(checkIn.status == .smokeFree ? "无烟" : "吸烟 \(checkIn.cigarettesSmoked) 支")
                            .foregroundStyle(.secondary)
                    }
                    if checkIn.id != store.data.checkIns.prefix(8).last?.id { Divider() }
                }
            }
        }
        .appCard()
    }

    private var attempts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("戒烟阶段").font(.headline)
            ForEach(store.data.attempts.indices.reversed(), id: \.self) { index in
                let attempt = store.data.attempts[index]
                HStack(alignment: .top) {
                    Image(systemName: attempt.endedAt == nil ? "location.fill" : "clock.arrow.circlepath")
                        .foregroundStyle(attempt.endedAt == nil ? Theme.primary : .secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(attempt.endedAt == nil ? "当前阶段" : "第 \(index + 1) 次")
                            .font(.subheadline.weight(.semibold))
                        Text(attemptText(attempt)).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
        .appCard()
    }

    private func attemptText(_ attempt: QuitAttempt) -> String {
        let start = AppFormatters.dateTime.string(from: attempt.startedAt)
        guard let end = attempt.endedAt else { return "开始于 \(start)" }
        return "\(start) — \(AppFormatters.dateTime.string(from: end))"
    }
}

private struct StatItem: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DaySummary: Identifiable {
    let date: Date
    let checkIn: DailyCheckIn?
    let cravings: Int
    var id: Date { date }
    var weekday: String { date.formatted(.dateTime.weekday(.narrow)) }
    var color: Color {
        guard let checkIn else { return .secondary.opacity(0.3) }
        return checkIn.status == .smokeFree ? Theme.primary : Theme.warm
    }
    var barHeight: CGFloat {
        guard let checkIn else { return max(8, CGFloat(cravings) * 9) }
        return checkIn.status == .smokeFree ? 72 : max(18, 58 - CGFloat(checkIn.cigarettesSmoked) * 3)
    }
    var description: String {
        guard let checkIn else { return "未打卡" }
        return checkIn.status == .smokeFree ? "无烟" : "吸烟 \(checkIn.cigarettesSmoked) 支"
    }
}
