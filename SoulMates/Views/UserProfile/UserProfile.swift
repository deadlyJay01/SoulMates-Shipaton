//
//  UserProfile.swift
//  SoulMates
//
//  Created by Jay on 17/09/26.
//

import SwiftUI
import PhotosUI
import Photos
import AVFoundation
import UserNotifications

enum AppPermissionType: String, Identifiable {
    case camera = "Camera Access"
    case photos = "Photo Library"
    case microphone = "Microphone Access"
    case notifications = "Notifications"

    var id: String { rawValue }

    var enableMessage: String {
        switch self {
        case .camera:
            return "Allow camera access to capture daily Soul Glimpse selfies with your partner."
        case .photos:
            return "Allow photo library access to upload photos and save couple memories."
        case .microphone:
            return "Allow microphone access to record and send voice notes in Chat."
        case .notifications:
            return "Allow notifications so you never miss daily questions, sparks, or notes from your partner."
        }
    }

    var disableMessage: String {
        switch self {
        case .camera:
            return "Are you sure you want to turn off camera access? You won't be able to take live snapshots."
        case .photos:
            return "Are you sure you want to turn off photo library access? You won't be able to pick photos from your library."
        case .microphone:
            return "Are you sure you want to turn off microphone access? You won't be able to send voice notes."
        case .notifications:
            return "Are you sure you want to turn off notifications? You won't receive partner alerts or nudges."
        }
    }
}

struct UserProfile: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var userImage: UIImage? = nil
    
    // Sheets & Alerts
    @State private var showLogoutConfirmation = false
    @State private var showBreakConnectionAlert = false
    @State private var isBreakingConnection = false
    @State private var showEditProfileSheet = false
    @State private var showLocationSheet = false
    @State private var showInvitePartnerSheet = false
    @State private var showCloseDistanceAlert = false
    @State private var showDatePickerSheet = false
    @State private var showManageProSheet = false
    
    // Coming Soon Feature Sheet
    @State private var showComingSoonSheet = false
    @State private var comingSoonFeatureName = ""

    // Permissions State
    @State private var cameraAllowed = false
    @State private var photosAllowed = false
    @State private var micAllowed = false
    @State private var notifsAllowed = false

    // Manual Disable User Flags
    @AppStorage("user_disabled_camera") private var userDisabledCamera = false
    @AppStorage("user_disabled_photos") private var userDisabledPhotos = false
    @AppStorage("user_disabled_mic") private var userDisabledMic = false
    @AppStorage("user_disabled_notifs") private var userDisabledNotifs = false

    // Permission Alert Routing
    @State private var showAllowAlert = false
    @State private var showDisableAlert = false
    @State private var activePermission: AppPermissionType? = nil

    private var hasPartner: Bool {
        let name = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.lowercased() != "partner"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                onBoarding_Background()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerSection
                        avatarSection
                        exploreProCard
                        relationshipCard
                        permissionsCard
                        supportCard
                        logoutButtonSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .alert("Feature for long-distance relationship", isPresented: $showCloseDistanceAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Distance tracking is only available when your relationship type is set to Long-Distance.")
            }
            // Classic Allow Permission Alert
            .alert("Allow \(activePermission?.rawValue ?? "Permission")?", isPresented: $showAllowAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Allow") {
                    handleAllowConfirmed()
                }
            } message: {
                Text(activePermission?.enableMessage ?? "SoulMates requires this permission to enable the feature.")
            }
            // Confirm Turn Off Permission Alert
            .alert("Turn Off \(activePermission?.rawValue ?? "Permission")?", isPresented: $showDisableAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    handleDisableConfirmed()
                }
            } message: {
                Text(activePermission?.disableMessage ?? "Are you sure you want to turn off this permission?")
            }
            .sheet(isPresented: $showEditProfileSheet, onDismiss: {
                refreshImage()
            }) {
                EditProfileSheet()
            }
            .sheet(isPresented: $showLocationSheet) {
                PartnerLocationSheet()
            }
            .sheet(isPresented: $showInvitePartnerSheet) {
                NavigationStack {
                    InvitePartnerView()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showDatePickerSheet) {
                AnniversaryPickerSheet(currentTimestamp: storage.anniversaryDateTimestamp) { newDate in
                    Task {
                        await storage.updateAnniversaryDate(newDate)
                    }
                }
            }
            .sheet(isPresented: $showComingSoonSheet) {
                ComingSoonView(featureName: comingSoonFeatureName)
                    .presentationDetents([.fraction(0.48)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showManageProSheet) {
                ManageProSubscriptionView()
                    .environmentObject(storage)
            }
            .task {
                await storage.syncCoupleRelationshipData()
                await storage.fetchSubscriptionAndTrialStatus()
                await checkAllPermissions()
            }
            .onAppear {
                refreshImage()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await storage.fetchSubscriptionAndTrialStatus()
                        await checkAllPermissions()
                    }
                }
            }
            .onChange(of: storage.profileImageData) { _, _ in
                refreshImage()
            }
        }
    }

    private func refreshImage() {
        if !storage.profileImageData.isEmpty,
           let uiImage = UIImage(data: storage.profileImageData) {
            self.userImage = uiImage
        } else {
            self.userImage = nil
        }
    }

    // Subviews

    private var headerSection: some View {
        HStack {
            Text("Settings")
                .foregroundStyle(.white)
                .font(.system(size: 32, weight: .black, design: .rounded))
            
            Spacer()
            
            Button {
                showEditProfileSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .frame(width: 44, height: 44)
        }
        .padding(.top, 10)
    }

    private var avatarSection: some View {
        VStack(spacing: 14) {
            if let userImage = userImage {
                Image(uiImage: userImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 14)
            } else {
                ProfileAvatarPlaceholder(
                    initial: storage.userName.isEmpty ? "U" : String(storage.userName.prefix(1)),
                    size: 140
                )
            }

            // User Name + Pro Gold Star
            HStack(spacing: 8) {
                Text(storage.userName.isEmpty ? "User" : storage.userName)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                if storage.isProUser {
                    Text("PRO")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 0.72, green: 0.53, blue: 0.04), lineWidth: 1.5)
                                )
                        )
                }
            }
            
            if !storage.userPhone.isEmpty {
                Text(storage.userPhone)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Explore / Manage Pro Card
    private var exploreProCard: some View {
        Group {
            if storage.isProUser {
                Button {
                    showManageProSheet = true
                } label: {
                    proCardContent
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    detailProView()
                } label: {
                    proCardContent
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var proCardContent: some View {
        HStack(spacing: 14) {
            // Crown Badge Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.42),
                                Color(red: 0.65, green: 0.22, blue: 0.88)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 8, y: 2)

                Image(systemName: storage.isProUser ? "crown.fill" : "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }

            // Copy Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(storage.isProUser ? "PRO MEMBER" : "SOULMATES PRO")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                    // Remaining Days Badge
                    Text(storage.isProUser ? "\(storage.proDaysRemaining)D LEFT" : "\(storage.freeTrialDaysRemaining)D FREE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.14), in: Capsule())
                }

                Text(storage.isProUser ? "SoulMates Pro" : "Unlock SoulMates Pro")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(storage.isProUser ? "All couple features active" : "Music sync, memories & quizzes")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Action Pill
            HStack(spacing: 4) {
                Text(storage.isProUser ? "Manage" : "Explore")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.25, blue: 0.42),
                        Color(red: 0.65, green: 0.22, blue: 0.88)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: Capsule()
            )
            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 6, y: 2)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.06))

                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let pulse = 0.8 + 0.2 * sin(time * 1.6)

                    ZStack {
                        AngularGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18),
                                .clear,
                                Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.16),
                                .clear,
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18)
                            ],
                            center: .center,
                            angle: .radians(time * 0.4)
                        )
                        .blur(radius: 26)

                        RadialGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.14 * pulse),
                                .clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: 160
                        )
                        .blur(radius: 12)
                    }
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.40),
                            Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.20),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var relationshipCard: some View {
        VStack(spacing: 16) {
            HStack {
                Label("Relationship Type", systemImage: "heart.fill")
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Spacer()
                Picker("Type", selection: Binding(
                    get: { storage.relationshipType },
                    set: { newType in
                        Task {
                            await storage.updateRelationshipType(newType)
                            if newType == 1 && storage.isLiveDistanceEnabled {
                                storage.isLiveDistanceEnabled = false
                            }
                        }
                    }
                )) {
                    Text("Select").tag(0)
                    Text("Close").tag(1)
                    Text("Long-Distance").tag(2)
                }
                .pickerStyle(.menu)
                .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
            }

            Divider().background(Color.white.opacity(0.15))

            Button {
                if hasPartner {
                    showDatePickerSheet = true
                } else {
                    showInvitePartnerSheet = true
                }
            } label: {
                HStack {
                    Text("Relationship Start")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    Spacer()
                    HStack(spacing: 6) {
                        Text(formattedDate(from: storage.anniversaryDateTimestamp))
                            .foregroundStyle(.white)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    }
                }
            }

            Divider().background(Color.white.opacity(0.15))

            HStack {
                Text("Next Anniversary")
                    .foregroundStyle(.white)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                Spacer()
                Text(nextAnniversaryText())
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }

            Divider().background(Color.white.opacity(0.15))

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Distance Tracking")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    if storage.isLiveDistanceEnabled && storage.calculatedDistanceKm > 0 {
                        Text("\(storage.calculatedDistanceKm) KM apart")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    }
                }

                Spacer()

                if storage.isLiveDistanceEnabled {
                    Button {
                        if !hasPartner {
                            showInvitePartnerSheet = true
                        } else {
                            showLocationSheet = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Change")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Toggle("", isOn: Binding(
                    get: { storage.isLiveDistanceEnabled },
                    set: { val in
                        if val {
                            guard hasPartner else {
                                showInvitePartnerSheet = true
                                return
                            }
                            guard storage.relationshipType == 2 else {
                                showCloseDistanceAlert = true
                                return
                            }
                            showLocationSheet = true
                        } else {
                            storage.isLiveDistanceEnabled = false
                        }
                    }
                ))
                .labelsHidden()
                .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: storage.isLiveDistanceEnabled)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Permissions Card
    private var permissionsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("APP PERMISSIONS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
            }

            // 1. Camera Access
            Toggle(isOn: Binding(
                get: { cameraAllowed },
                set: { turnOn in
                    if turnOn {
                        requestEnableCamera()
                    } else {
                        triggerDisablePrompt(for: .camera)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Camera Access", systemImage: "camera.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    Text("Take daily Soul Glimpse selfies & update profile")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))

            Divider().background(Color.white.opacity(0.10))

            // 2. Photo Library
            Toggle(isOn: Binding(
                get: { photosAllowed },
                set: { turnOn in
                    if turnOn {
                        requestEnablePhotos()
                    } else {
                        triggerDisablePrompt(for: .photos)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Photo Library", systemImage: "photo.stack.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    Text("Select saved photos & save to couple memories")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))

            Divider().background(Color.white.opacity(0.10))

            // 3. Microphone Access
            Toggle(isOn: Binding(
                get: { micAllowed },
                set: { turnOn in
                    if turnOn {
                        requestEnableMic()
                    } else {
                        triggerDisablePrompt(for: .microphone)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Microphone Access", systemImage: "mic.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    Text("Record disappearing voice notes in Chat")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))

            Divider().background(Color.white.opacity(0.10))

            // 4. Notifications
            Toggle(isOn: Binding(
                get: { notifsAllowed },
                set: { turnOn in
                    if turnOn {
                        requestEnableNotifications()
                    } else {
                        triggerDisablePrompt(for: .notifications)
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Notifications", systemImage: "bell.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                    Text("Daily questions, selfie nudges & partner notes")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var supportCard: some View {
        VStack(spacing: 12) {
            Button {
                comingSoonFeatureName = "Feedback Form"
                showComingSoonSheet = true
            } label: {
                SettingsRow(icon: "envelope.fill", title: "Give Feedback")
            }
            .buttonStyle(.plain)

            Button {
                comingSoonFeatureName = "App Store Rating"
                showComingSoonSheet = true
            } label: {
                SettingsRow(icon: "star.fill", title: "Rate SoulMates on App Store")
            }
            .buttonStyle(.plain)

            HStack {
                Label("Support Contact", systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.white)
                Spacer()
                Text("support@soulmates.com")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
            }
            .padding(.vertical, 8)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Bottom Actions Row
    private var logoutButtonSection: some View {
        HStack(spacing: 12) {
            if hasPartner {
                Button(role: .destructive) {
                    showBreakConnectionAlert = true
                } label: {
                    HStack(spacing: 6) {
                        if isBreakingConnection {
                            ProgressView()
                                .tint(.red)
                        } else {
                            Image(systemName: "heart.slash.fill")
                            Text("Break Connection")
                        }
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.red.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .disabled(isBreakingConnection)
            }

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Log Out")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.red.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            Spacer()
        }
        .padding(.top, 4)
        .padding(.bottom, 30)
        .alert("Break Connection?", isPresented: $showBreakConnectionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm & Delete All", role: .destructive) {
                performBreakConnection()
            }
        } message: {
            Text("This will permanently delete all your shared memories, love notes, dates, chats, and quiz history. Both of you will be unpaired immediately, allowing you to link with a new partner. This cannot be undone.")
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to log out? You will need to sign in again to access your account.")
        }
    }

    private func performBreakConnection() {
            isBreakingConnection = true
            Task {
                do {
                    try await SupabaseService.shared.breakConnection(storage: storage)
                    await MainActor.run {
                        isBreakingConnection = false
                        storage.partnerName = ""
                        storage.partnerProfileImageData = Data()
                        storage.partnerHasProfileImage = false
                        storage.relationshipType = 0
                        storage.anniversaryDateTimestamp = 0
                        storage.totalDaysTogether = 0
                        storage.isLiveDistanceEnabled = false
                        storage.calculatedDistanceKm = 0
                        storage.isCouplePro = false
                        storage.recalculateProAccess()
                        storage.syncAllWidgetData()
                    }
                } catch {
                    print("Failed to break connection:", error)
                    await MainActor.run {
                        isBreakingConnection = false
                    }
                }
            }
        }

        private func performLogout() {
            Task {
                do {
                    try await SupabaseService.shared.signOut(storage: storage)
                } catch {
                    print("Sign out error:", error)
                }
                await MainActor.run {
                    storage.clearAllSessionData()
                }
            }
        }

    // MARK: - Permission Verification
    private func checkAllPermissions() async {
        let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let micStatus = AVAudioSession.sharedInstance().recordPermission
        let center = UNUserNotificationCenter.current()
        let notifSettings = await center.notificationSettings()

        await MainActor.run {
            self.cameraAllowed = (camStatus == .authorized) && !userDisabledCamera
            self.photosAllowed = (photoStatus == .authorized || photoStatus == .limited) && !userDisabledPhotos
            self.micAllowed = (micStatus == .granted) && !userDisabledMic
            self.notifsAllowed = (notifSettings.authorizationStatus == .authorized || notifSettings.authorizationStatus == .provisional) && !userDisabledNotifs
        }
    }

    // MARK: - Enable Actions
    private func requestEnableCamera() {
        userDisabledCamera = false
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraAllowed = granted
                }
            }
        case .authorized:
            self.cameraAllowed = true
        case .denied, .restricted:
            self.activePermission = .camera
            self.showAllowAlert = true
        @unknown default:
            break
        }
    }

    private func requestEnablePhotos() {
        userDisabledPhotos = false
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.photosAllowed = (newStatus == .authorized || newStatus == .limited)
                }
            }
        case .authorized, .limited:
            self.photosAllowed = true
        case .denied, .restricted:
            self.activePermission = .photos
            self.showAllowAlert = true
        @unknown default:
            break
        }
    }

    private func requestEnableMic() {
        userDisabledMic = false
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.micAllowed = granted
                }
            }
        case .granted:
            self.micAllowed = true
        case .denied:
            self.activePermission = .microphone
            self.showAllowAlert = true
        @unknown default:
            break
        }
    }

    private func requestEnableNotifications() {
        userDisabledNotifs = false
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            self.notifsAllowed = granted
                        }
                    }
                case .authorized, .provisional, .ephemeral:
                    self.notifsAllowed = true
                case .denied:
                    self.activePermission = .notifications
                    self.showAllowAlert = true
                @unknown default:
                    break
                }
            }
        }
    }

    private func handleAllowConfirmed() {
        guard let permission = activePermission else { return }
        switch permission {
        case .camera:
            userDisabledCamera = false
        case .photos:
            userDisabledPhotos = false
        case .microphone:
            userDisabledMic = false
        case .notifications:
            userDisabledNotifs = false
        }
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Disable Actions
    private func triggerDisablePrompt(for permission: AppPermissionType) {
        self.activePermission = permission
        self.showDisableAlert = true
    }

    private func handleDisableConfirmed() {
        guard let permission = activePermission else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            switch permission {
            case .camera:
                self.userDisabledCamera = true
                self.cameraAllowed = false
            case .photos:
                self.userDisabledPhotos = true
                self.photosAllowed = false
            case .microphone:
                self.userDisabledMic = true
                self.micAllowed = false
            case .notifications:
                self.userDisabledNotifs = true
                self.notifsAllowed = false
            }
        }
    }

    // MARK: - Helpers
    private func formattedDate(from timestamp: Double) -> String {
        guard timestamp > 0 else { return "Set Date" }
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func nextAnniversaryText() -> String {
        guard storage.anniversaryDateTimestamp > 0 else { return "N/A" }
        let calendar = Calendar.current
        let anniversary = Date(timeIntervalSince1970: storage.anniversaryDateTimestamp)
        let now = Date()
        
        var nextComponents = calendar.dateComponents([.month, .day], from: anniversary)
        nextComponents.year = calendar.component(.year, from: now)
        
        var nextDate = calendar.date(from: nextComponents) ?? now
        if nextDate < calendar.startOfDay(for: now) {
            nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate) ?? nextDate
        }
        
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: nextDate)).day ?? 0
        return days == 0 ? "Today! 🎉" : "in \(days) days"
    }
}



// MARK: - Coming Soon Sheet Component
struct ComingSoonView: View {
    @Environment(\.dismiss) private var dismiss
    let featureName: String

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.06, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 14)

                Text("\(featureName) Coming Soon!")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("We're currently fine-tuning SoulMates for our official App Store release. This feature is not available quite yet — we're so sorry for the wait!\n\nCheck back in the upcoming update. Thank you for being an early soulmate! 💖")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .lineSpacing(4)

                Button {
                    dismiss()
                } label: {
                    Text("Got it ✨")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.3), radius: 8, y: 3)
                }
                .padding(.horizontal, 36)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Anniversary Date Picker Sheet
struct AnniversaryPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date

    let onSave: (Date) -> Void

    init(currentTimestamp: Double, onSave: @escaping (Date) -> Void) {
        self.onSave = onSave
        if currentTimestamp > 0 {
            _selectedDate = State(initialValue: Date(timeIntervalSince1970: currentTimestamp))
        } else {
            _selectedDate = State(initialValue: Date())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("Select the day your journey began")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.top, 6)

                        DatePicker(
                            "",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)

                        Button {
                            onSave(selectedDate)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Save Anniversary Date")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 8, y: 3)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Relationship Start")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(selectedDate)
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                }
            }
        }
        .presentationDetents([.fraction(0.72)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var gender: Int = 0
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var previewImage: UIImage? = nil
    @State private var isSaving = false
    @State private var showSavedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.04, blue: 0.08).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let previewImage {
                                        Image(uiImage: previewImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else if !storage.profileImageData.isEmpty,
                                              let image = UIImage(data: storage.profileImageData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                    } else {
                                        ProfileAvatarPlaceholder(
                                            initial: name.isEmpty ? "U" : String(name.prefix(1)),
                                            size: 120
                                        )
                                    }

                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(
                                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                            .frame(width: 38, height: 38)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))

                                        Image(systemName: "pencil")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                    .offset(x: 4, y: 4)
                                }
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        await MainActor.run {
                                            self.previewImage = uiImage
                                            self.storage.profileImageData = data
                                            self.storage.hasProfileImage = true
                                        }
                                    }
                                }
                            }

                            if storage.hasProfileImage || previewImage != nil {
                                Button(role: .destructive) {
                                    previewImage = nil
                                    storage.profileImageData = Data()
                                    storage.hasProfileImage = false
                                } label: {
                                    Text("Remove Photo")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.red.opacity(0.85))
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 10)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            CustomInputField(
                                icon: "person.fill",
                                placeholder: "Enter your name",
                                text: $name
                            )
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gender")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Picker("Gender", selection: $gender) {
                                Text("Select").tag(0)
                                Text("Male").tag(1)
                                Text("Female").tag(2)
                                Text("Other").tag(3)
                            }
                            .pickerStyle(.segmented)
                        }

                        Button {
                            isSaving = true
                            Task {
                                try? await SupabaseService.shared.updateProfile(
                                    name: name,
                                    gender: gender,
                                    relationshipType: storage.relationshipType,
                                    storage: storage
                                )
                                await MainActor.run {
                                    isSaving = false
                                    showSavedAlert = true
                                }
                            }
                        } label: {
                            Text(isSaving ? "Saving..." : "Save Changes")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(isSaving)
                        .padding(.top, 10)

                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .alert("Profile saved successfully", isPresented: $showSavedAlert) {
                Button("OK") { dismiss() }
            }
            .onAppear {
                name = storage.userName
                gender = storage.userGender
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Partner Location Sheet
struct PartnerLocationSheet: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss

    let states = ["Gujarat", "Maharashtra", "Karnataka", "Delhi", "Rajasthan"]
    let cities = ["Ahmedabad", "Mumbai", "Bengaluru", "New Delhi", "Jaipur", "Surat", "Pune"]

    @State private var uState = "Gujarat"
    @State private var uCity = "Ahmedabad"
    @State private var pState = "Maharashtra"
    @State private var pCity = "Mumbai"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.04, blue: 0.08).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YOUR LOCATION")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        
                        HStack {
                            Picker("State", selection: $uState) {
                                ForEach(states, id: \.self) { Text($0) }
                            }
                            Picker("City", selection: $uCity) {
                                ForEach(cities, id: \.self) { Text($0) }
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("PARTNER'S LOCATION")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        
                        HStack {
                            Picker("State", selection: $pState) {
                                ForEach(states, id: \.self) { Text($0) }
                            }
                            Picker("City", selection: $pCity) {
                                ForEach(cities, id: \.self) { Text($0) }
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)

                    Button {
                        storage.userState = uState
                        storage.userCity = uCity
                        storage.partnerState = pState
                        storage.partnerCity = pCity
                        if storage.calculatedDistanceKm == 0 {
                            storage.calculatedDistanceKm = 520
                        }
                        storage.isLiveDistanceEnabled = true
                        dismiss()
                    } label: {
                        Text("Confirm Locations")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Distance Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Avatar Glow & Aura Design Placeholder
struct ProfileAvatarPlaceholder: View {
    let initial: String
    let size: CGFloat

    private var scale: CGFloat {
        size / 140.0
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.35, green: 0.08, blue: 0.30).opacity(0.65),
                            Color(red: 0.16, green: 0.06, blue: 0.22).opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.28),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: max(4, 20 * scale),
                        endRadius: max(15, 90 * scale)
                    )
                )

            Text(initial.uppercased())
                .font(.system(size: max(12, 60 * scale), weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4),
                    radius: max(2, 10 * scale)
                )
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .stroke(accentGradient, lineWidth: max(1.5, 3 * scale))
        }
        .overlay {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, 2 * scale)
                )
                .padding(1)
        }
        .shadow(
            color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35),
            radius: max(5, 20 * scale),
            x: 0,
            y: max(2, 6 * scale)
        )
        .shadow(
            color: Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.25),
            radius: max(7, 26 * scale),
            x: 0,
            y: max(3, 10 * scale)
        )
    }
}

// MARK: - Reusable Row Component
struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.white)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}
