import SwiftUI

struct AddRelapseView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var cigarettes = 1
    @State private var reason = ""
    @State private var note = ""

    private let commonReasons = ["压力", "社交", "饮酒", "习惯", "情绪波动"]

    var body: some View {
        NavigationStack {
            Form {
                Section("这次记录") {
                    DatePicker("时间", selection: $date, in: ...Date())
                    Stepper("吸了 (cigarettes) 支", value: $cigarettes, in: 1...100)
                }
                Section("原因") {
                    TextField("例如：加班后没忍住", text: $reason)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonReasons, id: \.self) { item in
                                Button(item) { reason = item }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.capsule)
                            }
                        }
                    }
                }
                Section("补充") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("记下当时发生了什么，方便以后回看")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle("记录复吸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.addRelapse(cigarettes: cigarettes, reason: reason, note: note, date: date)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
