//
//  MainTabView.swift
//  SoulMates
//
//  Created by Jay on 02/09/26.
//

import SwiftUI
import Supabase
import WidgetKit

struct ContentView: View {
    @EnvironmentObject private var storage: AppStorageManager

    var body: some View {
        Group {
            if storage.isLoggedIn {
                RootGatekeeperView()
            } else {
                NavigationStack {
                    Greeting()
                }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var musicViewModel = ListenTogetherViewModel()
    @State private var coupleRealtimeChannel: RealtimeChannelV2?

    // Tab Navigation State (Tag 3 = CoupleSelfieView)
    @State private var selectedTab: Int = 0

    private var actorName: String {
        storage.userName.isEmpty ? "Partner" : storage.userName
    }

    private var partnerDisplayName: String {
        storage.partnerName.isEmpty ? "your partner" : storage.partnerName
    }

    // MARK: - Tabs (split out of body so the compiler can handle it easily)
    private var tabs: some View {
        TabView(selection: $selectedTab) {
            HomePageView()
                .tabItem {
                    Image(systemName: "house")
                }
                .tag(0)

            ChatView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                }
                .tag(1)

            Games()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                }
                .tag(2)

            CoupleSelfieView()
                .tabItem {
                    Image(systemName: "camera.fill")
                }
                .tag(3)

            UserProfile()
                .tabItem {
                    Image(systemName: "person")
                }
                .tag(4)
        }
        .accentColor(Color.red.opacity(0.6))
    }

    var body: some View {
        tabs
            .environmentObject(musicViewModel)
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .task {
                // Initial verification on app start
                await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)
                await musicViewModel.start()
                await subscribeToCoupleDisconnection()
                syncWidgets()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)
                        syncWidgets()
                    }
                }
            }
            .sheet(isPresented: $musicViewModel.isPlayerPresented) {
                SyncedPlayerView(viewModel: musicViewModel)
            }
            .modifier(
                MusicAlertsModifier(
                    musicViewModel: musicViewModel,
                    actorName: actorName,
                    partnerDisplayName: partnerDisplayName
                )
            )
    }

    // MARK: - Deep Link Handler
    private func handleDeepLink(_ url: URL) {
        // Widget 1 tap -> open the Selfie tab directly
        if url == WidgetSharedData.deepLinkSelfieURL || (url.scheme == "soulmates" && url.host == "couple-selfie") {
            selectedTab = 3
        }
    }

    // MARK: - Widget Synchronization Helper
    private func syncWidgets() {
        WidgetSharedData.saveTotalDays(storage.totalDaysTogether)
    }

    // MARK: - Instant Live Disconnect Listener
    private func subscribeToCoupleDisconnection() async {
        guard let currentUID = SupabaseService.shared.client.auth.currentUser?.id else { return }

        guard coupleRealtimeChannel == nil else { return }

        let client = SupabaseService.shared.client
        let uniqueTopic = "couple_monitor_\(currentUID.uuidString.lowercased())_\(UUID().uuidString.prefix(6))"
        let channel = client.realtimeV2.channel(uniqueTopic)
        self.coupleRealtimeChannel = channel

        let coupleChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "couples"
        )
        let profileChanges = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles"
        )

        Task {
            for await _ in coupleChanges {
                await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)
                syncWidgets()
            }
        }
        Task {
            for await _ in profileChanges {
                await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)
                syncWidgets()
            }
        }

        await channel.subscribe()
    }
}

// MARK: - All the music-related alerts in one place
private struct MusicAlertsModifier: ViewModifier {
    @ObservedObject var musicViewModel: ListenTogetherViewModel
    let actorName: String
    let partnerDisplayName: String

    private var incomingInviteTitle: String {
        let name = musicViewModel.activeSession?.lastActionBy ?? "Partner"
        return "\(name) wants to listen together!"
    }

    func body(content: Content) -> some View {
        content
            .alert("Pair First", isPresented: $musicViewModel.showMustPairFirstAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please pair with your partner first to listen to songs together.")
            }
            .alert("Waiting for \(partnerDisplayName)", isPresented: $musicViewModel.isWaitingForPartnerAccept) {
                Button("Cancel Invite", role: .destructive) {
                    Task {
                        await musicViewModel.cancelPairInvite(actorName: actorName)
                    }
                }
            } message: {
                Text("Waiting for \(partnerDisplayName) to accept your invite to listen together...")
            }
            .alert(incomingInviteTitle, isPresented: $musicViewModel.showIncomingInviteAlert) {
                Button("Decline", role: .cancel) {
                    Task {
                        await musicViewModel.declineInvite(myName: actorName)
                    }
                }
                Button("Accept 🎶") {
                    Task {
                        await musicViewModel.acceptInvite(partnerName: actorName)
                    }
                }
            } message: {
                Text("Would you like to tune in and listen in sync?")
            }
            .alert(musicViewModel.alertMessage, isPresented: $musicViewModel.showEndedAlert) {
                Button("OK", role: .cancel) { }
            }
            .alert(musicViewModel.alertMessage, isPresented: $musicViewModel.showRejectedAlert) {
                Button("OK", role: .cancel) { }
            }
    }
}
