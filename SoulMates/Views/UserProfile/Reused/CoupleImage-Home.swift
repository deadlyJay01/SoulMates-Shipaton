//
//  CoupleImage_Home.swift
//  SoulMates
//

import SwiftUI
import Supabase

struct CoupleImage_Home: View {
    @EnvironmentObject private var storage: AppStorageManager

    var Image1: String? = nil
    var Image2: String? = nil
    var Size: Bool? = nil
    var avatarSize: CGFloat? = nil
    var onAddPartnerTap: (() -> Void)? = nil

    @State private var userImage: UIImage?
    @State private var partnerImage: UIImage?
    @State private var currentUserName: String = ""
    @State private var partnerName: String = ""
    @State private var partnerId: String? = nil
    @State private var hasPartner: Bool = false
    @State private var animateAura = false

    @State private var profileChannel: RealtimeChannelV2?
    @State private var isSubscribed = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private var resolvedSize: CGFloat {
        if let size = avatarSize { return size }
        if let isLarge = Size { return isLarge ? 64 : 44 }
        return 64
    }

    private var resolvedOverlap: CGFloat {
        resolvedSize > 50 ? -14 : -9
    }

    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: resolvedOverlap) {
            // MARK: - Left Avatar (Current User)
            avatarView(
                image: userImage,
                name: currentUserName.isEmpty ? storage.userName : currentUserName,
                size: resolvedSize
            )
            .zIndex(1)

            // MARK: - Right Avatar (Partner or Add Partner Button)
            Group {
                if hasPartner {
                    avatarView(
                        image: partnerImage,
                        name: partnerName,
                        size: resolvedSize
                    )
                } else {
                    addPartnerButton(size: resolvedSize)
                }
            }
            .zIndex(0)
        }
        .onAppear {
            syncLocalUser()
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                animateAura = true
            }
        }
        // Sync when user changes local photo
        .onChange(of: storage.profileImageData) { _, _ in
            syncLocalUser()
        }
        .onChange(of: storage.userName) { _, newName in
            currentUserName = newName
        }
        // Instantly react when partner's photo updates in storage
        .onChange(of: storage.partnerProfileImageData) { _, newData in
            if !newData.isEmpty, let img = UIImage(data: newData) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.partnerImage = img
                    self.hasPartner = true
                }
            }
        }
        .onChange(of: storage.partnerName) { _, newName in
            if !newName.isEmpty && newName.lowercased() != "partner" {
                self.partnerName = newName
                self.hasPartner = true
            }
        }
        .task {
            syncLocalUser()
            await fetchCoupleAvatars()
        }
        .onDisappear {
            isSubscribed = false
            if let ch = profileChannel {
                Task { await client.realtimeV2.removeChannel(ch) }
            }
        }
    }

    // MARK: - Local User & Partner Cache Sync
    private func syncLocalUser() {
        if storage.hasProfileImage && !storage.profileImageData.isEmpty {
            userImage = UIImage(data: storage.profileImageData)
        } else {
            userImage = nil
        }
        currentUserName = storage.userName

        if storage.partnerHasProfileImage && !storage.partnerProfileImageData.isEmpty {
            partnerImage = UIImage(data: storage.partnerProfileImageData)
            hasPartner = true
        }
        if !storage.partnerName.isEmpty && storage.partnerName.lowercased() != "partner" {
            partnerName = storage.partnerName
            hasPartner = true
        }
    }

    // MARK: - Avatar View
    @ViewBuilder
    private func avatarView(image: UIImage?, name: String, size: CGFloat) -> some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(accentGradient, lineWidth: max(1.5, size * 0.035))
                    )
                    .overlay(glassRim(size: size))
                    .shadow(
                        color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(animateAura ? 0.4 : 0.2),
                        radius: size * 0.18,
                        y: 4
                    )
            } else {
                neonMonogramPlaceholder(name: name, size: size)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Add Partner Button
    @ViewBuilder
    private func addPartnerButton(size: CGFloat) -> some View {
        let scale = size / 210.0

        Button {
            onAddPartnerTap?()
        } label: {
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
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: max(4, 20 * scale),
                            endRadius: max(15, 90 * scale)
                        )
                    )

                Image(systemName: "plus")
                    .font(.system(size: max(18, 65 * scale), weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.5), radius: 8 * scale)
            }
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(accentGradient, lineWidth: max(1.5, 3 * scale))
            }
            .overlay {
                glassRim(size: size)
            }
            .shadow(
                color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(animateAura ? 0.45 : 0.25),
                radius: max(5, 24 * scale),
                x: 0,
                y: max(2, 8 * scale)
            )
            .shadow(
                color: Color(red: 0.65, green: 0.22, blue: 0.88).opacity(animateAura ? 0.35 : 0.18),
                radius: max(7, 30 * scale),
                x: 0,
                y: max(3, 12 * scale)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Placeholder
    @ViewBuilder
    private func neonMonogramPlaceholder(name: String, size: CGFloat) -> some View {
        let initial = name.first.map(String.init) ?? ""
        let scale = size / 210.0

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
                .font(.system(size: max(12, 88 * scale), weight: .black, design: .rounded))
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
            glassRim(size: size)
        }
        .shadow(
            color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(animateAura ? 0.45 : 0.25),
            radius: max(5, 24 * scale),
            x: 0,
            y: max(2, 8 * scale)
        )
        .shadow(
            color: Color(red: 0.65, green: 0.22, blue: 0.88).opacity(animateAura ? 0.35 : 0.18),
            radius: max(7, 30 * scale),
            x: 0,
            y: max(3, 12 * scale)
        )
    }

    private func glassRim(size: CGFloat) -> some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.55), .clear, .white.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: max(1.0, size * 0.02)
            )
    }

    // MARK: - Supabase Query & Realtime
    private func fetchCoupleAvatars() async {
        syncLocalUser()

        guard let currentUser = client.auth.currentUser else { return }

        struct ProfileRecord: Codable {
            let userName: String?
            let profileImagePath: String?

            enum CodingKeys: String, CodingKey {
                case userName = "user_name"
                case profileImagePath = "profile_image_path"
            }
        }

        // 1. Fetch user's own remote image if missing locally
        if userImage == nil {
            if let myProfile: ProfileRecord = try? await client
                .from("profiles")
                .select("user_name, profile_image_path")
                .eq("id", value: currentUser.id.uuidString)
                .single()
                .execute()
                .value {

                if let name = myProfile.userName, !name.isEmpty {
                    await MainActor.run { currentUserName = name }
                }

                if let path = myProfile.profileImagePath,
                   let downloaded = await downloadImage(fromPath: path, userId: currentUser.id.uuidString) {
                    await MainActor.run {
                        self.userImage = downloaded
                        if let data = downloaded.jpegData(compressionQuality: 0.8) {
                            self.storage.profileImageData = data
                            self.storage.hasProfileImage = true
                        }
                    }
                }
            }
        }

        // 2. Discover partner and fetch current profile
        do {
            struct CoupleRow: Codable {
                let user1_id: String?
                let user2_id: String?
            }

            var coupleList: [CoupleRow] = (try? await client
                .from("couples")
                .select("user1_id, user2_id")
                .eq("user1_id", value: currentUser.id.uuidString)
                .limit(1)
                .execute()
                .value) ?? []

            if coupleList.isEmpty {
                coupleList = (try? await client
                    .from("couples")
                    .select("user1_id, user2_id")
                    .eq("user2_id", value: currentUser.id.uuidString)
                    .limit(1)
                    .execute()
                    .value) ?? []
            }

            guard let couple = coupleList.first else {
                await MainActor.run {
                    self.hasPartner = false
                    self.partnerImage = nil
                    self.partnerName = ""
                }
                return
            }

            let partnerID = (couple.user1_id?.lowercased() == currentUser.id.uuidString.lowercased())
                ? couple.user2_id
                : couple.user1_id

            if let partnerID = partnerID,
               !partnerID.isEmpty,
               partnerID.lowercased() != currentUser.id.uuidString.lowercased() {

                self.partnerId = partnerID

                if let partnerProfile: ProfileRecord = try? await client
                    .from("profiles")
                    .select("user_name, profile_image_path")
                    .eq("id", value: partnerID)
                    .single()
                    .execute()
                    .value {

                    let pImg = await downloadImage(fromPath: partnerProfile.profileImagePath, userId: partnerID)

                    await MainActor.run {
                        self.hasPartner = true
                        self.partnerName = partnerProfile.userName ?? "Partner"
                        if let pImg = pImg {
                            self.partnerImage = pImg
                        }

                        self.storage.partnerName = partnerProfile.userName ?? "Partner"
                        if let pData = pImg?.jpegData(compressionQuality: 0.8) {
                            self.storage.partnerProfileImageData = pData
                            self.storage.partnerHasProfileImage = true
                        }
                    }
                }

                await subscribeToProfileChanges(currentUID: currentUser.id.uuidString)
            } else {
                await MainActor.run {
                    self.hasPartner = false
                    self.partnerImage = nil
                    self.partnerName = ""
                }
            }
        }
    }

    // MARK: - Reliable Realtime Listener for Profile Updates
    private func subscribeToProfileChanges(currentUID: String) async {
        guard !isSubscribed else { return }
        isSubscribed = true

        // Dedicated channel prevents collisions across multiple avatar views
        let channelName = "profiles_sync_\(currentUID.lowercased())_\(UUID().uuidString.prefix(8))"
        let channel = client.realtimeV2.channel(channelName)
        self.profileChannel = channel

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "profiles"
        )

        Task {
            for await _ in changes {
                // Fetch fresh profile metadata and download the new image directly
                await self.fetchCoupleAvatars()
            }
        }
        await channel.subscribe()
    }

    private func downloadImage(fromPath customPath: String?, userId: String) async -> UIImage? {
        var potentialPaths: [String] = []

        if let path = customPath, !path.isEmpty {
            potentialPaths.append(path)
        }
        potentialPaths.append("\(userId.lowercased())/profile.jpg")

        for path in potentialPaths {
            if let data = try? await client.storage.from("profile-images").download(path: path) {
                if let img = UIImage(data: data) {
                    return img
                }
            }
        }
        return nil
    }
}
