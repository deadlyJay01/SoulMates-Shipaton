//
//  InvitePartnerViewModel.swift
//  SoulMates
//

import SwiftUI
import Supabase
import Combine

@MainActor
final class InvitePartnerViewModel: ObservableObject {
    @Published var myInviteCode: String = "------"
    @Published var partnerCodeInput: String = ""
    @Published var isLoadingCode: Bool = true
    @Published var isConnecting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isConnected: Bool = false
    @Published var copied: Bool = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }
    
    private var realtimeChannel: RealtimeChannelV2?

    var canSubmit: Bool {
        partnerCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 && !isConnecting
    }

    // MARK: - Load or Generate My Code
    func loadOrCreateMyCode(storage: AppStorageManager) async {
        guard let currentUID = client.auth.currentUser?.id else {
            isLoadingCode = false
            return
        }

        do {
            let profiles: [ProfileInviteCode] = try await client
                .from("profiles")
                .select("invite_code")
                .eq("id", value: currentUID.uuidString)
                .limit(1)
                .execute()
                .value

            if let existingCode = profiles.first?.inviteCode, !existingCode.isEmpty {
                self.myInviteCode = existingCode
            } else {
                let generated = String(currentUID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
                try await client
                    .from("profiles")
                    .update(["invite_code": generated])
                    .eq("id", value: currentUID.uuidString)
                    .execute()

                self.myInviteCode = generated
            }
            
            await subscribeToPairingUpdates(currentUID: currentUID, storage: storage)
            
        } catch {
            print("Error loading invite code:", error)
            self.myInviteCode = String(currentUID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6)).uppercased()
        }

        self.isLoadingCode = false
    }

    func copyCodeToClipboard() {
        UIPasteboard.general.string = myInviteCode
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.copied = false
            }
        }
    }

    // MARK: - Link Partner via Code
    func linkPartner(storage: AppStorageManager) async {
        guard let currentUID = client.auth.currentUser?.id else {
            errorMessage = "Please log in again."
            return
        }

        let cleanCode = partnerCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        isConnecting = true
        errorMessage = nil

        do {
            // 1. Fetch partner profile by entered invite code
            let partners: [PartnerProfileData] = try await client
                .from("profiles")
                .select("id, user_name, anniversary_date_timestamp, relationship_type, total_days_together")
                .eq("invite_code", value: cleanCode)
                .limit(1)
                .execute()
                .value

            guard let partner = partners.first else {
                errorMessage = "Invalid invite code. Check the code and try again."
                isConnecting = false
                return
            }

            if partner.id == currentUID {
                errorMessage = "You cannot enter your own invite code."
                isConnecting = false
                return
            }

            // 2. Link into couple room
            let existingCouple: [[String: String]] = try await client
                .from("couples")
                .select("id")
                .or("user1_id.eq.\(partner.id.uuidString),user2_id.eq.\(partner.id.uuidString),user1_id.eq.\(currentUID.uuidString),user2_id.eq.\(currentUID.uuidString)")
                .limit(1)
                .execute()
                .value

            if let coupleRow = existingCouple.first, let coupleId = coupleRow["id"] {
                try await client
                    .from("couples")
                    .update(["user2_id": currentUID.uuidString])
                    .eq("id", value: coupleId)
                    .execute()
            } else {
                let newRoom = CouplePairingPayload(user1Id: partner.id, user2Id: currentUID)
                try await client
                    .from("couples")
                    .insert(newRoom)
                    .execute()
            }

            // 3. Hydrate partner details to storage immediately
            if let name = partner.userName, !name.isEmpty {
                storage.partnerName = name
            }
            if let timestamp = partner.anniversaryDateTimestamp, timestamp > 0 {
                storage.anniversaryDateTimestamp = timestamp
            }
            if let days = partner.totalDaysTogether, days > 0 {
                storage.totalDaysTogether = days
            }
            if let type = partner.relationshipType, type > 0 {
                storage.relationshipType = type
            }

            storage.refreshTotalDaysTogether()
            await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)

            isConnecting = false
            isConnected = true
        } catch {
            isConnecting = false
            errorMessage = "Invalid invite code. Check the code and try again."
            print("Pairing error:", error)
        }
    }

    // MARK: - Realtime Auto-Detection for Code Sharer
    private func subscribeToPairingUpdates(currentUID: UUID, storage: AppStorageManager) async {
        let channel = client.realtimeV2.channel("public:couples:\(currentUID.uuidString)")
        self.realtimeChannel = channel

        let insertions = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "couples"
        )

        Task {
            for await _ in insertions {
                await checkAndTransitionIfPaired(currentUID: currentUID, storage: storage)
            }
        }

        do {
            try await channel.subscribe()
        } catch {
            print("Failed to subscribe to couples channel:", error)
        }
    }

    func checkAndTransitionIfPaired(currentUID: UUID, storage: AppStorageManager) async {
        do {
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
                if u1 != nil && u2 != nil {
                    await SupabaseService.shared.verifyAndSyncPartnerStatus(storage: storage)
                    await MainActor.run {
                        self.isConnected = true
                    }
                }
            }
        } catch {
            print("Pair check failed:", error)
        }
    }

    func cleanupChannel() {
        if let channel = realtimeChannel {
            Task {
                await client.realtimeV2.removeChannel(channel)
            }
        }
    }
}
