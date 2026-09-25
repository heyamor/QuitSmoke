import SwiftUI

struct CheckInSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let existing: DailyCheckIn?

    @State private var selected: DailyCheckIn.Status = .smokeFree
    @State private var cigarettes = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Picker("今日状态", selection: $selected) {
                    Text("无烟").tag(DailyCheckIn.Status.smokeFree)
                    Text("吸烟了").tag(DailyCheckIn.Status.smoked)
                }
                .pickerStyle(.segmented)

                if selected == .smoked {
                    VStack(spacing: 10) {
                        Text("今天吸了几支？").font(.headline)
                        Stepper("\(cigarettes) 支", value: $cigarettes, in: 1...100)
                            .font(.title3.bold())
                        Text("这不会清空之前的坚持和记录。")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    .appCard()
                } else {
                    ContentUnavailableView("今天无烟", systemImage: "leaf.fill", description: Text("很棒，把这一天记下来。"))
                }

                Spacer()
                Button("保存打卡") {
                    store.checkIn(status: selected, cigarettes: cigarettes)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("今日打卡")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onAppear {
                guard let existing else { return }
                selected = existing.status
                cigarettes = max(1, existing.cigarettesSmoked)
            }
        }
    }
}

