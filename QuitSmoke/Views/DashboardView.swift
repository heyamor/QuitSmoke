import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingCheckIn = false
    @State private var now = Date()

    private var todayCheckIn: DailyCheckIn? {
        store.data.checkIns.first { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                metricGrid
                recoveryCard
                checkInCard
                encouragementCard
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollIndicators(.hidden)
        .navigationTitle("无烟日记")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "leaf.fill").foregroundStyle(Theme.primary)
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            CheckInSheet(existing: todayCheckIn)
                .presentationDetents([.medium])
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                now = Date()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("本次已坚持", systemImage: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(AppFormatters.duration(max(0, now.timeIntervalSince(store.data.currentAttempt?.startedAt ?? now))))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.75)
            Text("你的每一个无烟小时，都在积累。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(colors: [Theme.primary, Theme.secondary], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.12))
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 140, height: 140)
                .blur(radius: 10)
                .offset(x: 34, y: -58)
                .allowsHitTesting(false)
        }
        .shadow(color: Theme.primary.opacity(0.22), radius: 18, y: 8)
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(icon: "minus.circle.fill", value: "\(store.metrics.fewerCigarettes) 支", label: "累计少抽")
            MetricCard(icon: "yensign.circle.fill", value: AppFormatters.currency(store.metrics.moneySaved), label: "累计省下")
            MetricCard(icon: "flame.fill", value: "\(store.metrics.smokeFreeStreak) 天", label: "连续无烟")
            MetricCard(icon: "checkmark.seal.fill", value: "\(store.metrics.resistedRate)%", label: "烟瘾扛过率")
            MetricCard(icon: "trophy.fill", value: AppFormatters.duration(store.metrics.longestElapsed), label: "最长纪录")
        }
    }

    private var recoveryCard: some View {
        let next = RecoveryMilestone.all.first { $0.progress(elapsed: store.metrics.elapsed) < 1 }
            ?? RecoveryMilestone.all.last!
        let progress = next.progress(elapsed: store.metrics.elapsed)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("恢复里程碑").font(.headline)
                    Text(next.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.primary)
            }
            HStack(spacing: 12) {
                ProgressView(value: progress)
                    .tint(Theme.primary)
                Text("\(Int(progress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.primary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RecoveryMilestone.all) { milestone in
                        let completed = milestone.progress(elapsed: store.metrics.elapsed) >= 1
                        Label(milestone.title, systemImage: completed ? "checkmark.circle.fill" : "circle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(completed ? Theme.primary : .secondary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
        }
        .appCard()
    }

    private var checkInCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日打卡").font(.headline)
                    if let todayCheckIn {
                        Text(todayCheckIn.status == .smokeFree ? "今天无烟，做得很好" : "已记录 \(todayCheckIn.cigarettesSmoked) 支，继续就好")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        Text("如实记录，不评判自己").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: todayCheckIn?.status == .smokeFree ? "checkmark.circle.fill" : "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(todayCheckIn?.status == .smokeFree ? Theme.primary : .secondary)
            }
            Button(todayCheckIn == nil ? "记录今天" : "修改今日记录") { showingCheckIn = true }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .appCard()
    }

    private var encouragementCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundStyle(.pink)
                .frame(width: 44, height: 44)
                .background(.pink.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("一次波动不等于失败").font(.headline)
                Text("复吸后保留历史，下一次选择仍然有效。")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }
}

private struct MetricCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Theme.primary)
            Text(value).font(.title3.bold()).minimumScaleFactor(0.75)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }
}
