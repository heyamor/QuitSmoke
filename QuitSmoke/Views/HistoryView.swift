import Charts
import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var period: ReviewPeriod = .week
    @State private var showingRelapse = false
    @State private var showingWellness = false

    private var recentDays: [DaySummary] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let checkIn = store.data.checkIns.first { calendar.isDate($0.date, inSameDayAs: date) }
            let cravings = store.data.cravings.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return DaySummary(date: date, checkIn: checkIn, cravings: cravings)
        }
    }

    private var cravingTrend: [TrendPoint] {
        let calendar = Calendar.current
        let count = period == .week ? 7 : 30
        return (0..<count).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let total = store.data.cravings.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return TrendPoint(date: calendar.startOfDay(for: date), count: total)
        }
    }

    private var triggerRanking: [TriggerSummary] {
        let grouped = Dictionary(grouping: store.data.cravings) { craving in
            craving.trigger.isEmpty ? "未填写" : craving.trigger
        }
        return grouped.map { TriggerSummary(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                overview
                Picker("回顾周期", selection: $period) {
                    ForEach(ReviewPeriod.allCases) { value in
                        Text(value.title).tag(value)
                    }
                }
                .pickerStyle(.segmented)
                trendChart
                triggerOverview
                checkInChart
                relapseSection
                wellnessSection
                recentRecords
                attempts
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("历史与统计")
        .sheet(isPresented: $showingRelapse) { AddRelapseView() }
        .sheet(isPresented: $showingWellness) { AddWellnessEntryView() }
    }

    private var overview: some View {
        HStack(spacing: 4) {
            StatItem(value: "\(store.data.checkIns.filter { $0.status == .smokeFree }.count)", label: "无烟打卡")
            Divider().frame(height: 42)
            StatItem(value: "\(store.data.cravings.count)", label: "烟瘾记录")
            Divider().frame(height: 42)
            StatItem(value: "\(store.metrics.resistedRate)%", label: "扛过率")
            Divider().frame(height: 42)
            StatItem(value: AppFormatters.duration(store.metrics.longestElapsed), label: "最长纪录")
        }
        .appCard()
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("想抽次数趋势").font(.headline)
                Spacer()
                Text(period == .week ? "最近 7 天" : "最近 30 天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if store.data.cravings.isEmpty {
                Text("记录几次烟瘾后，这里会显示趋势。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
            } else {
                Chart(cravingTrend) { point in
                    LineMark(
                        x: .value("日期", point.date),
                        y: .value("次数", point.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.primary)
                    AreaMark(
                        x: .value("日期", point.date),
                        y: .value("次数", point.count)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.primary.opacity(0.12))
                    PointMark(
                        x: .value("日期", point.date),
                        y: .value("次数", point.count)
                    )
                    .foregroundStyle(Theme.primary)
                }
                .chartYScale(domain: 0...max(1, cravingTrend.map(\.count).max() ?? 1))
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: period == .week ? 7 : 5)) }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 170)
            }
        }
        .appCard()
    }

    private var triggerOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高频触发场景").font(.headline)
            if triggerRanking.isEmpty {
                Text("记录烟瘾后会在这里看到自己的触发规律。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(triggerRanking.prefix(5)) { item in
                    HStack(spacing: 10) {
                        Text(item.name)
                        Spacer()
                        Text("\(item.count) 次")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.primary)
                    }
                    if item.id != triggerRanking.prefix(5).last?.id { Divider() }
                }
            }
        }
        .appCard()
    }

    private var checkInChart: some View {
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

    private var relapseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("复吸记录").font(.headline)
                Spacer()
                Button { showingRelapse = true } label: {
                    Label("添加", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }
            if store.data.relapses.isEmpty {
                Text("偶尔没忍住也可以如实记下来，不会清空历史。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.data.relapses.prefix(5)) { relapse in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(Theme.warm)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("吸了 \(relapse.cigarettes) 支 · \(relapse.reason)")
                                .font(.subheadline.weight(.semibold))
                            Text(AppFormatters.dateTime.string(from: relapse.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !relapse.note.isEmpty {
                                Text(relapse.note).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) { store.deleteRelapse(id: relapse.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .appCard()
    }

    private var wellnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("身体状态").font(.headline)
                Spacer()
                Button { showingWellness = true } label: {
                    Label("添加", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }
            if store.data.wellnessEntries.isEmpty {
                Text("记录体重、睡眠和精力，看看它们和戒烟过程的关系。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.data.wellnessEntries.prefix(5)) { entry in
                    HStack {
                        Text(AppFormatters.shortDate.string(from: entry.date))
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(wellnessText(entry))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(role: .destructive) { store.deleteWellnessEntry(id: entry.id) } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
            HStack {
                Text("戒烟阶段").font(.headline)
                Spacer()
                Text("最长 \(AppFormatters.duration(store.metrics.longestElapsed))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

    private func wellnessText(_ entry: WellnessEntry) -> String {
        var values: [String] = []
        if let weight = entry.weight { values.append(String(format: "%.1f kg", weight)) }
        if let sleep = entry.sleepHours { values.append(String(format: "睡眠 %.1f h", sleep)) }
        if let energy = entry.energy { values.append("精力 \(energy)/5") }
        return values.joined(separator: " · ")
    }
}

private enum ReviewPeriod: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
    var title: String { self == .week ? "周" : "月" }
}

private struct TrendPoint: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

private struct TriggerSummary: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            Text(value).font(.caption.weight(.bold)).minimumScaleFactor(0.6)
            Text(label).font(.caption2).foregroundStyle(.secondary)
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
