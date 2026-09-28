//
//  RootGatekeeperView.swift
//  SoulMates
//

import SwiftUI
import Supabase
import Combine

struct RootGatekeeperView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var isChecking: Bool = true
    @State private var hasPartner: Bool = false
    @AppStorage("has_skipped_partner_invite") private var hasSkippedPartnerInvite = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private var shouldShowMainTab: Bool {
        hasPartner || !storage.partnerName.isEmpty || hasSkippedPartnerInvite
    }

    var body: some View {
        Group {
            if isChecking {
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            } else if !storage.isLoggedIn {
                Greeting()
            } else if shouldShowMainTab {
                MainTabView()
            } else {
                NavigationStack {
                    InvitePartnerView(onFinished: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.hasSkippedPartnerInvite = true
                            self.hasPartner = true
                        }
                    })
                }
            }
        }
        .task {
            await verifyCoupleStatus()
        }
    }

    private func verifyCoupleStatus() async {
        guard let currentUID = client.auth.currentUser?.id else {
            isChecking = false
            hasPartner = false
            return
        }

        do {
            struct ProfileSync: Codable {
                let userName: String?
                let anniversaryDateTimestamp: Double?
                let totalDaysTogether: Int?
                let relationshipType: Int?
                let hasProfileImage: Bool?

                enum CodingKeys: String, CodingKey {
                    case userName = "user_name"
                    case anniversaryDateTimestamp = "anniversary_date_timestamp"
                    case totalDaysTogether = "total_days_together"
                    case relationshipType = "relationship_type"
                    case hasProfileImage = "has_profile_image"
                }
            }

            if let profile: ProfileSync = try? await client
                .from("profiles")
                .select("user_name, anniversary_date_timestamp, total_days_together, relationship_type, has_profile_image")
                .eq("id", value: currentUID.uuidString)
                .single()
                .execute()
                .value {

                await MainActor.run {
                    if let name = profile.userName, storage.userName.isEmpty {
                        storage.userName = name
                    }
                    if let timestamp = profile.anniversaryDateTimestamp, timestamp > 0 {
                        storage.anniversaryDateTimestamp = timestamp
                    }
                    if let days = profile.totalDaysTogether, days > 0 {
                        storage.totalDaysTogether = days
                    }
                    if let type = profile.relationshipType, type > 0 {
                        storage.relationshipType = type
                    }
                    if let hasImg = profile.hasProfileImage {
                        storage.hasProfileImage = hasImg
                    }
                }
            }

            // Check pairing status in couples table
            let coupleRows: [[String: String?]] = try await client
                .from("couples")
                .select("id, user1_id, user2_id")
                .or("user1_id.eq.\(currentUID.uuidString),user2_id.eq.\(currentUID.uuidString)")
                .limit(1)
                .execute()
                .value

            if let couple = coupleRows.first {
                let u1 = couple["user1_id"] ?? nil
                let u2 = couple["user2_id"] ?? nil
                hasPartner = (u1 != nil && u2 != nil)
            } else {
                hasPartner = false
            }
        } catch {
            print("Couple verification error:", error)
            hasPartner = false
        }

        isChecking = false
    }
}

#Preview {
    RootGatekeeperView()
        .environmentObject(AppStorageManager())
}
