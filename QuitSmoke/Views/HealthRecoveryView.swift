import SwiftUI

struct HealthRecoveryView: View {
    @EnvironmentObject private var store: AppStore
    @State private var now = Date()
    @State private var showingWellness = false

    private var metrics: QuitMetrics {
        MetricsCalculator.calculate(data: store.data, now: now)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                stageCard
                timelineCard
                wellnessCard
                disclaimerCard
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollIndicators(.hidden)
        .navigationTitle("健康恢复")
        .sheet(isPresented: $showingWellness) { AddWellnessEntryView() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                now = Date()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("健康恢复度", systemImage: "heart.text.square.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.86))
                    Text("\(metrics.recoveryPercent)%")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white.opacity(0.9))
            }
            ProgressView(value: metrics.recoveryProgress)
                .tint(.white)
                .scaleEffect(y: 1.5)
            Text("这是基于连续无烟时间的激励指数，不是医学检测结果。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(
                colors: [Theme.primary, Theme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.12))
                .allowsHitTesting(false)
        }
        .shadow(color: Theme.primary.opacity(0.22), radius: 18, y: 8)
    }

    private var stageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("当前阶段", systemImage: "flag.checkered")
                .font(.headline)
            Text(metrics.currentRecoveryStage.title)
                .font(.title2.bold())
            Text(metrics.currentRecoveryStage.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let next = metrics.nextRecoveryStage {
                Divider()
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .foregroundStyle(Theme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("下一里程碑：\(next.title)")
                            .font(.subheadline.weight(.semibold))
                        let remaining = max(0, next.hours * 3_600 - metrics.elapsed)
                        Text("还需约 \(AppFormatters.duration(remaining))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("恢复里程碑").font(.headline)
            ForEach(HealthRecoveryMilestone.all) { milestone in
                milestoneRow(milestone)
            }
        }
        .appCard()
    }

    private func milestoneRow(_ milestone: HealthRecoveryMilestone) -> some View {
        let reached = metrics.elapsed >= milestone.hours * 3_600
        let current = milestone.id == metrics.currentRecoveryStage.id
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: reached ? "checkmark.circle.fill" : (current ? "circle.inset.filled" : "circle"))
                .font(.title3)
                .foregroundStyle(reached || current ? Theme.primary : .secondary.opacity(0.45))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(milestone.title)
                        .font(.subheadline.weight(current ? .bold : .semibold))
                    Spacer()
                    Text("\(milestone.targetPercent)%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(reached || current ? Theme.primary : .secondary)
                }
                Text(milestone.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(reached || current ? 1 : 0.62)
    }

    private var wellnessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("身体状态", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Button { showingWellness = true } label: {
                    Label("记录", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                }
            }
            if let latest = store.data.wellnessEntries.first {
                Text("最近记录 · \(AppFormatters.shortDate.string(from: latest.date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(wellnessText(latest))
                    .font(.subheadline)
            } else {
                Text("记录体重、睡眠和精力，观察自己的状态变化。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var disclaimerCard: some View {
        Label {
            Text("恢复度只用于个人记录和激励，身体状况如有疑问请咨询专业医务人员。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private func wellnessText(_ entry: WellnessEntry) -> String {
        var values: [String] = []
        if let weight = entry.weight { values.append(String(format: "体重 %.1f kg", weight)) }
        if let sleep = entry.sleepHours { values.append(String(format: "睡眠 %.1f 小时", sleep)) }
        if let energy = entry.energy { values.append("精力 \(energy)/5") }
        return values.isEmpty ? "没有填写具体项目" : values.joined(separator: " · ")
    }
}
