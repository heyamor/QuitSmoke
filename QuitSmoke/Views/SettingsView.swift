import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var cigarettesPerDay = 10
    @State private var cigarettesPerPack = 20
    @State private var pricePerPack = 30.0
    @State private var smokingYears = 0
    @State private var reminderEnabled = false
    @State private var reminderTimes: [ReminderTime] = []
    @State private var showingRestartConfirmation = false
    @State private var showingNotificationDenied = false
    @State private var saved = false
    @State private var exportDocument: QuitSmokeExportDocument?
    @State private var exportType: UTType = .json
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        Form {
            Section("原吸烟情况") {
                Stepper("原来每天 \(cigarettesPerDay) 支", value: $cigarettesPerDay, in: 1...100)
                Stepper("每包 \(cigarettesPerPack) 支", value: $cigarettesPerPack, in: 1...100)
                Stepper("烟龄约 \(smokingYears) 年", value: $smokingYears, in: 0...80)
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
                        pricePerPack: pricePerPack,
                        smokingYears: smokingYears
                    )
                    saved = true
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        saved = false
                    }
                }
                .disabled(saved)
            }

            Section("自定义提醒") {
                Toggle("开启提醒", isOn: Binding(
                    get: { reminderEnabled },
                    set: { value in
                        reminderEnabled = value
                        if value && reminderTimes.isEmpty {
                            reminderTimes = [ReminderTime(hour: 20, minute: 0)]
                        }
                        updateReminders()
                    }
                ))
                if reminderTimes.isEmpty {
                    Text("打开提醒后可以添加多个时间点。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reminderTimes) { time in
                        HStack {
                            DatePicker(
                                time.label,
                                selection: timeBinding(for: time.id),
                                displayedComponents: .hourAndMinute
                            )
                            Button {
                                reminderTimes.removeAll { $0.id == time.id }
                                if reminderTimes.isEmpty { reminderEnabled = false }
                                updateReminders()
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Button {
                    reminderTimes.append(ReminderTime(hour: 20, minute: 0, label: "新提醒"))
                    reminderEnabled = true
                    updateReminders()
                } label: {
                    Label("添加提醒时间", systemImage: "plus")
                }
            }

            Section {
                LabeledContent("当前开始时间") {
                    Text(AppFormatters.dateTime.string(from: store.data.currentAttempt?.startedAt ?? store.data.profile.originalQuitDate))
                }
                Button("重新开始戒烟计时", role: .destructive) {
                    showingRestartConfirmation = true
                }
            } header: {
                Text("戒烟计时")
            } footer: {
                Text("重新开始只会新增一个戒烟阶段。历史打卡、复吸记录和累计少抽数量都会保留。")
            }

            Section("数据导出") {
                Button {
                    prepareExport(type: .json, data: try? store.exportJSONData())
                } label: {
                    Label("导出 JSON", systemImage: "curlybraces.square")
                }
                Button {
                    prepareExport(type: .commaSeparatedText, data: try? store.exportCSVData())
                } label: {
                    Label("导出 CSV 表格", systemImage: "tablecells")
                }
            }

            Section("数据与隐私") {
                Label("数据仅保存在本机", systemImage: "iphone.and.arrow.forward")
                Label("无需账号，不连接服务器", systemImage: "lock.shield.fill")
                LabeledContent("戒烟阶段", value: "\(store.data.attempts.count) 个")
                LabeledContent("打卡记录", value: "\(store.data.checkIns.count) 条")
                LabeledContent("复吸记录", value: "\(store.data.relapses.count) 条")
                LabeledContent("身体记录", value: "\(store.data.wellnessEntries.count) 条")
            }

            Section {
                HStack {
                    Text("无烟日记")
                    Spacer()
                    Text("1.3").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
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
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: exportType,
            defaultFilename: "无烟日记-数据"
        ) { result in
            if case let .failure(error) = result {
                exportError = "导出失败：\(error.localizedDescription)"
            }
        }
        .alert("导出失败", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("知道了") { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
    }

    private func loadValues() {
        cigarettesPerDay = store.data.profile.cigarettesPerDay
        cigarettesPerPack = store.data.profile.cigarettesPerPack
        pricePerPack = store.data.profile.pricePerPack
        smokingYears = store.data.profile.smokingYears
        reminderEnabled = store.data.reminder.enabled
        reminderTimes = store.data.reminder.times
        if reminderTimes.isEmpty && reminderEnabled {
            reminderTimes = [ReminderTime(hour: store.data.reminder.hour, minute: store.data.reminder.minute)]
        }
    }

    private func timeBinding(for id: UUID) -> Binding<Date> {
        Binding(
            get: {
                guard let time = reminderTimes.first(where: { $0.id == id }) else { return Date() }
                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { value in
                guard let index = reminderTimes.firstIndex(where: { $0.id == id }) else { return }
                let components = Calendar.current.dateComponents([.hour, .minute], from: value)
                reminderTimes[index].hour = components.hour ?? 20
                reminderTimes[index].minute = components.minute ?? 0
                updateReminders()
            }
        )
    }

    private func updateReminders() {
        let times = reminderTimes
        let enabled = reminderEnabled && !times.isEmpty
        Task {
            let success = await NotificationService.configure(enabled: enabled, times: times)
            if success {
                store.setReminders(enabled: enabled, times: times)
            } else {
                reminderEnabled = false
                store.setReminders(enabled: false, times: times)
                showingNotificationDenied = true
            }
        }
    }

    private func prepareExport(type: UTType, data: Data?) {
        guard let data else {
            exportError = "导出失败，请稍后重试。"
            return
        }
        exportType = type
        exportDocument = QuitSmokeExportDocument(data: data)
        isExporting = true
    }
}
