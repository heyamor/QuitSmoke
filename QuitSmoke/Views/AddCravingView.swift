import SwiftUI

struct AddCravingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var intensity = 3
    @State private var trigger = ""
    @State private var resisted = true

    private let commonTriggers = ["压力", "饭后", "社交", "无聊", "习惯", "饮酒"]

    var body: some View {
        NavigationStack {
            Form {
                Section("烟瘾强度") {
                    HStack {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                intensity = value
                            } label: {
                                Text("\(value)")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(intensity == value ? Theme.primary : Color(uiColor: .secondarySystemGroupedBackground))
                                    .foregroundStyle(intensity == value ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("触发原因") {
                    TextField("例如：工作压力、饭后、社交", text: $trigger)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonTriggers, id: \.self) { item in
                                Button(item) { trigger = item }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                            }
                        }
                    }
                }

                Section {
                    Toggle("这次扛过去了", isOn: $resisted)
                } footer: {
                    Text("如实记录就好，没有任何一次记录是失败。")
                }
            }
            .navigationTitle("记录烟瘾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addCraving(intensity: intensity, trigger: trigger, resisted: resisted)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

