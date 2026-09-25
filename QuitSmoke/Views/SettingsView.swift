import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var cigarettesPerDay = 10
    @State private var cigarettesPerPack = 20
    @State private var pricePerPack = 30.0
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var showingRestartConfirmation = false
    @State private var showingNotificationDenied = false
    @State private var saved = false

    var body: some View {
        Form {
            Section("原吸烟情况") {
                Stepper("原来每天 \(cigarettesPerDay) 支", value: $cigarettesPerDay, in: 1...100)
                Stepper("每包 \(cigarettesPerPack) 支", value: $cigarettesPerPack, in: 1...100)
                HStack {
                    Text("每包价格")
                    Spacer()
                    TextField("30", value: $pricePerPack, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                    Text("元").foregroundStyle(.secondary)
                }
                Button(saved ? "已保存" : "保存修改") {
                    store.updateProfile(
                        cigarettesPerDay: cigarettesPerDay,
                        cigarettesPerPack: cigarettesPerPack,
                        pricePerPack: pricePerPack
                    )
                    saved = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        saved = false
                    }
                }
                .disabled(saved)
            }

            Section("每日提醒") {
                Toggle("提醒我完成打卡", isOn: $reminderEnabled)
                    .onChange(of: reminderEnabled) { _, value in
                        updateReminder(enabled: value)
                    }
                if reminderEnabled {
                    DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, _ in updateReminder(enabled: true) }
                }
            }

            Section("戒烟计时") {
                LabeledContent("当前开始时间") {
                    Text(AppFormatters.dateTime.string(from: store.data.currentAttempt?.startedAt ?? store.data.profile.originalQuitDate))
                }
                Button("重新开始戒烟计时", role: .destructive) {
                    showingRestartConfirmation = true
                }
            } footer: {
                Text("重新开始只会新增一个戒烟阶段。历史打卡、烟瘾记录和累计少抽数量都会保留。")
            }

            Section("数据与隐私") {
                Label("数据仅保存在本机", systemImage: "iphone.and.arrow.forward")
                Label("无需账号，不连接服务器", systemImage: "lock.shield.fill")
                LabeledContent("戒烟阶段", value: "\(store.data.attempts.count) 个")
                LabeledContent("打卡记录", value: "\(store.data.checkIns.count) 条")
                LabeledContent("烟瘾记录", value: "\(store.data.cravings.count) 条")
            }

            Section {
                HStack {
                    Text("无烟日记")
                    Spacer()
                    Text("1.0").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .onAppear(perform: loadValues)
        .confirmationDialog(
            "重新开始戒烟计时？",
            isPresented: $showingRestartConfirmation,
            titleVisibility: .visible
        ) {
            Button("从现在重新开始", role: .destructive) { store.restartAttempt() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("已有记录不会被删除。")
        }
        .alert("通知未开启", isPresented: $showingNotificationDenied) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("请前往 iPhone“设置 > 通知 > 无烟日记”允许通知。")
        }
        .alert("保存提示", isPresented: Binding(
            get: { store.lastSaveError != nil },
            set: { if !$0 { store.lastSaveError = nil } }
        )) {
            Button("知道了") { store.lastSaveError = nil }
        } message: {
            Text(store.lastSaveError ?? "")
        }
    }

    private func loadValues() {
        cigarettesPerDay = store.data.profile.cigarettesPerDay
        cigarettesPerPack = store.data.profile.cigarettesPerPack
        pricePerPack = store.data.profile.pricePerPack
        reminderEnabled = store.data.reminder.enabled
        var components = DateComponents()
        components.hour = store.data.reminder.hour
        components.minute = store.data.reminder.minute
        reminderTime = Calendar.current.date(from: components) ?? Date()
    }

    private func updateReminder(enabled: Bool) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let hour = components.hour ?? 20
        let minute = components.minute ?? 0
        Task {
            let success = await NotificationService.configure(enabled: enabled, hour: hour, minute: minute)
            if success {
                store.setReminder(enabled: enabled, hour: hour, minute: minute)
            } else {
                reminderEnabled = false
                store.setReminder(enabled: false, hour: hour, minute: minute)
                showingNotificationDenied = true
            }
        }
    }
}

