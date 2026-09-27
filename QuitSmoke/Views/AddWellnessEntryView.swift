import SwiftUI

struct AddWellnessEntryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var weight = ""
    @State private var sleepHours = ""
    @State private var energy = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    DatePicker("记录时间", selection: $date, in: ...Date(), displayedComponents: .date)
                }
                Section("身体状态") {
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("可选", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text("kg").foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("睡眠")
                        Spacer()
                        TextField("可选", text: $sleepHours)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                        Text("小时").foregroundStyle(.secondary)
                    }
                    Stepper("精力 \(energy)/5", value: $energy, in: 1...5)
                }
                Section {
                    Text("只记录你愿意记录的项目，留空即可。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("身体记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addWellnessEntry(
                            weight: Double(weight.trimmingCharacters(in: .whitespacesAndNewlines)),
                            sleepHours: Double(sleepHours.trimmingCharacters(in: .whitespacesAndNewlines)),
                            energy: energy
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
