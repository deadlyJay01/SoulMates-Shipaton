//
//  SoulMatesApp.swift
//  SoulMates
//

import SwiftUI
import WidgetKit
import RevenueCat

@main
struct SoulMatesApp: App {
    @StateObject private var storageManager = AppStorageManager()
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingLaunchScreen: Bool = true

    init() {
        Purchases.configure(withAPIKey: "test_xpIHAXGCwjcmBEygcHZXybzIQjc")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main Application Root
                ContentView()
                    .environmentObject(storageManager)
                    .preferredColorScheme(.dark)

                // Seamless Animated Splash Overlay
                if isShowingLaunchScreen {
                    LaunchScreenView()
                        .environmentObject(storageManager)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .opacity.combined(with: .scale(scale: 1.08))
                        ))
                        .zIndex(999)
                }
            }
            .task {
                let startTime = Date()

                // Execute all background startup syncs concurrently
                async let syncCouple: () = storageManager.syncCoupleRelationshipData()
                async let syncSubscription: () = storageManager.fetchSubscriptionAndTrialStatus()
                
                _ = await (syncCouple, syncSubscription)
                storageManager.syncAllWidgetData()

                // Guarantee minimum splash display time (~1.2s) to avoid jarring screen jumps
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingDelay = max(0, 1.2 - elapsed)
                try? await Task.sleep(nanoseconds: UInt64(remainingDelay * 1_000_000_000))

                withAnimation(.easeInOut(duration: 0.45)) {
                    isShowingLaunchScreen = false
                }
            }
            .onAppear {
                storageManager.refreshTotalDaysTogether()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await storageManager.syncCoupleRelationshipData()
                        await storageManager.fetchSubscriptionAndTrialStatus()
                        storageManager.syncAllWidgetData()
                    }
                }
            }
        }
    }
}
