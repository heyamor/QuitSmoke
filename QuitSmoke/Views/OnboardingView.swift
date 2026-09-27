import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var startDate = Date()
    @State private var cigarettesPerDay = 10
    @State private var cigarettesPerPack = 20
    @State private var pricePerPack = 30.0
    @State private var smokingYears = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Theme.primary)
                        Text("从今天开始，\n把主动权拿回来")
                            .font(.largeTitle.bold())
                        Text("所有记录只保存在这台 iPhone 上。你可以随时调整，也可以重新开始。")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        DatePicker("戒烟开始时间", selection: $startDate, in: ...Date())
                            .padding(.vertical, 12)
                        Divider()
                        Stepper("原来每天约 \(cigarettesPerDay) 支", value: $cigarettesPerDay, in: 1...100)
                            .padding(.vertical, 12)
                        Divider()
                        Stepper("每包 \(cigarettesPerPack) 支", value: $cigarettesPerPack, in: 1...100)
                            .padding(.vertical, 12)
                        Divider()
                        HStack {
                            Text("每包价格")
                            Spacer()
                            TextField("30", value: $pricePerPack, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 90)
                            Text("元").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)
                        Divider()
                        Stepper("烟龄约 \(smokingYears) 年", value: $smokingYears, in: 0...80)
                            .padding(.vertical, 12)
                    }
                    .appCard()

                    Button {
                        store.completeSetup(
                            startDate: startDate,
                            cigarettesPerDay: cigarettesPerDay,
                            cigarettesPerPack: cigarettesPerPack,
                            pricePerPack: pricePerPack,
                            smokingYears: smokingYears
                        )
                    } label: {
                        Text("开始记录")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 16))
                }
                .padding(24)
            }
            .background {
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                    LinearGradient(
                        colors: [Theme.softGreen.opacity(0.85), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .ignoresSafeArea()
            }
            .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("完成") { hideKeyboard() } } }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
