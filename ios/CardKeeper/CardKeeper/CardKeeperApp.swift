import SwiftUI
import UIKit

@main
struct CardKeeperApp: App {
    @StateObject private var store = Store()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.976, green: 0.976, blue: 0.988, alpha: 1)
        appearance.shadowColor = UIColor(white: 0, alpha: 0.08)

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            HomeView()
                .tag(0)
                .tabItem { Label("卡片", systemImage: "creditcard") }

            BillsView()
                .tag(1)
                .tabItem { Label("账单", systemImage: "list.bullet.rectangle") }

            ActivitiesView()
                .tag(2)
                .tabItem { Label("活动", systemImage: "sparkles") }

            StatsView()
                .tag(3)
                .tabItem { Label("统计", systemImage: "chart.bar") }

            ProfileView()
                .tag(4)
                .tabItem { Label("我的", systemImage: "person") }
        }
        .tint(Palette.blue)
        .onAppear {
            Notifier.shared.requestPermission()
            Notifier.shared.refresh(store: store)
        }
    }
}
