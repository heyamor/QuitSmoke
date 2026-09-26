import SwiftUI

struct CravingsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAdd = false

    var body: some View {
        Group {
            if store.data.cravings.isEmpty {
                ContentUnavailableView(
                    "还没有烟瘾记录",
                    systemImage: "waveform.path.ecg",
                    description: Text("记录出现的时刻和触发原因，会更容易发现规律。")
                )
            } else {
                List {
                    Section {
                        ForEach(store.data.cravings) { craving in
                            CravingRow(craving: craving)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                store.deleteCraving(id: store.data.cravings[index].id)
                            }
                        }
                    } header: {
                        Text("共记录 \(store.data.cravings.count) 次")
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("烟瘾记录")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Label("记录烟瘾", systemImage: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { AddCravingView() }
    }
}

private struct CravingRow: View {
    let craving: CravingRecord

    var body: some View {
        HStack(spacing: 13) {
            VStack(spacing: 3) {
                Text("\(craving.intensity)").font(.title2.bold())
                Text("强度").font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(intensityColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(intensityColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(craving.trigger).font(.headline)
                HStack(spacing: 6) {
                    Text(AppFormatters.dateTime.string(from: craving.date))
                    if !craving.emotion.isEmpty {
                        Text("·")
                        Text(craving.emotion)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if !craving.note.isEmpty {
                    Text(craving.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Label(craving.resisted ? "扛过" : "没扛过", systemImage: craving.resisted ? "checkmark.circle.fill" : "arrow.uturn.backward.circle")
                .labelStyle(.iconOnly)
                .foregroundStyle(craving.resisted ? Theme.primary : Theme.warm)
                .accessibilityLabel(craving.resisted ? "扛过去了" : "没有扛过去")
        }
        .padding(.vertical, 4)
    }

    private var intensityColor: Color {
        craving.intensity >= 4 ? .red : (craving.intensity >= 3 ? .orange : Theme.primary)
    }
}
