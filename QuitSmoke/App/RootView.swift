import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("今日", systemImage: "house.fill") }

            NavigationStack { CravingsView() }
                .tabItem { Label("烟瘾", systemImage: "waveform.path.ecg") }

            NavigationStack { HistoryView() }
                .tabItem { Label("历史", systemImage: "chart.bar.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .fullScreenCover(isPresented: Binding(
            get: { !store.data.hasCompletedSetup },
            set: { _ in }
        )) {
            OnboardingView()
                .environmentObject(store)
                .interactiveDismissDisabled()
        }
    }
}
