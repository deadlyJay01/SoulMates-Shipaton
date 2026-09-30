//
//  SelfieViewModel.swift
//  SoulMates
//

import SwiftUI
import Supabase
import Combine

@MainActor
final class SelfieViewModel: ObservableObject {
    @Published var mySelfie: CoupleSelfie? = nil
    @Published var partnerSelfie: CoupleSelfie? = nil
    @Published var isLoading: Bool = true
    @Published var isUploading: Bool = false
    @Published var bothUploaded: Bool = false
    @Published var nudgeSentToday: Bool = false
    @Published var showNudgeReceivedBanner: Bool = false
    @Published var timeRemainingString: String = "24h window"

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private var coupleId: UUID? = nil
    private var partnerId: UUID? = nil
    private var selfieChannel: RealtimeChannelV2?
    private var nudgeChannel: RealtimeChannelV2?
    private var isSubscribed: Bool = false
    private var hasRecordedViewThisSession: Bool = false

    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    // Initial Setup
    func start() async {
        isLoading = true
        guard let cId = await SupabaseService.shared.fetchCoupleId(),
              let myUID = currentUserId else {
            isLoading = false
            return
        }
        self.coupleId = cId
        await fetchPartnerId(coupleId: cId, myUID: myUID)
        await fetchSelfiesOnly()
        await subscribeToRealtimeChannels(coupleId: cId, myUID: myUID)
        isLoading = false
    }

    // Isolated Fetch (Never destroys and recreates channels)
    func fetchSelfiesOnly() async {
        guard let cId = self.coupleId, let myUID = currentUserId else { return }

        let twentyFourHoursAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-24 * 3600))

        do {
            let fetched: [CoupleSelfie] = try await client
                .from("couple_selfies")
                .select()
                .eq("couple_id", value: cId.uuidString)
                .gte("created_at", value: twentyFourHoursAgo)
                .order("created_at", ascending: false)
                .execute()
                .value

            let mine = fetched.first(where: { $0.userId == myUID })
            let partner = fetched.first(where: { $0.userId != myUID })

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.mySelfie = mine
                self.partnerSelfie = partner
                self.bothUploaded = (mine != nil && partner != nil) || (mine?.isTogether == true)
            }

            if let earliestDate = [mine?.createdAt, partner?.createdAt].compactMap({ $0 }).min() {
                let expiresAt = earliestDate.addingTimeInterval(24 * 3600)
                let remaining = max(0, expiresAt.timeIntervalSince(Date()))
                let hours = Int(remaining) / 3600
                let mins = (Int(remaining) % 3600) / 60
                self.timeRemainingString = "\(hours)h \(mins)m left"
            } else {
                self.timeRemainingString = "New moment ready"
            }

            let todayKey = DailyQuestionBank.dateKey()
            let nudges: [UUID] = (try? await client
                .from("photo_requests")
                .select("id")
                .eq("couple_id", value: cId.uuidString)
                .eq("sender_id", value: myUID.uuidString)
                .eq("date_key", value: todayKey)
                .execute()
                .value) ?? []

            self.nudgeSentToday = !nudges.isEmpty

            if let partner = partner, self.bothUploaded, !hasRecordedViewThisSession {
                hasRecordedViewThisSession = true
                await recordView(selfieId: partner.id)
            }
        } catch {
            print("Failed to fetch rolling selfies:", error)
        }
    }

    private func fetchPartnerId(coupleId: UUID, myUID: UUID) async {
        struct CoupleRow: Codable {
            let user1Id: UUID
            let user2Id: UUID
            enum CodingKeys: String, CodingKey {
                case user1Id = "user1_id"
                case user2Id = "user2_id"
            }
        }
        do {
            let couple: CoupleRow = try await client
                .from("couples")
                .select("user1_id, user2_id")
                .eq("id", value: coupleId.uuidString)
                .single()
                .execute()
                .value
            self.partnerId = (couple.user1Id == myUID) ? couple.user2Id : couple.user1Id
        } catch {
            print("Failed to fetch partner id:", error)
        }
    }

    // Upload (Handles First Upload & Photo Updates)
    func uploadSelfie(image: UIImage, caption: String) async -> Bool {
        guard let coupleId = self.coupleId,
              let myUID = currentUserId,
              let imageData = image.jpegData(compressionQuality: 0.75) else { return false }

        isUploading = true
        let nowKey = "\(Int(Date().timeIntervalSince1970))"
        let fileName = "\(coupleId.uuidString)/\(nowKey)_\(myUID.uuidString).jpg"

        do {
            _ = try await client.storage
                .from("couple-selfies")
                .upload(fileName, data: imageData, options: FileOptions(upsert: true))

            let publicURL = try client.storage
                .from("couple-selfies")
                .getPublicURL(path: fileName)

            if let existing = mySelfie {
                // Update existing record
                struct UpdatePayload: Codable {
                    let image_url: String
                    let caption: String
                    let created_at: String
                }

                let update = UpdatePayload(
                    image_url: publicURL.absoluteString,
                    caption: caption,
                    created_at: ISO8601DateFormatter().string(from: Date())
                )

                try await client.from("couple_selfies")
                    .update(update)
                    .eq("id", value: existing.id.uuidString)
                    .execute()
            } else {
                // Insert new daily record
                struct InsertPayload: Codable {
                    let couple_id: String
                    let user_id: String
                    let image_url: String
                    let date_key: String
                    let caption: String
                }

                let todayKey = DailyQuestionBank.dateKey()
                let insert = InsertPayload(
                    couple_id: coupleId.uuidString,
                    user_id: myUID.uuidString,
                    image_url: publicURL.absoluteString,
                    date_key: todayKey,
                    caption: caption
                )

                try await client.from("couple_selfies").insert(insert).execute()
            }

            await fetchSelfiesOnly()
            isUploading = false
            return true
        } catch {
            print("Selfie upload error:", error)
            isUploading = false
            return false
        }
    }

    func recordView(selfieId: UUID) async {
        do {
            try await client.rpc("increment_selfie_view", params: ["target_selfie_id": selfieId.uuidString]).execute()
        } catch {
            print("Error recording view:", error)
        }
    }

    func sendPhotoNudge() async {
        guard let coupleId = self.coupleId,
              let myUID = currentUserId,
              !nudgeSentToday else { return }

        let todayKey = DailyQuestionBank.dateKey()

        struct NudgePayload: Codable {
            let couple_id: String
            let sender_id: String
            let date_key: String
        }

        let payload = NudgePayload(
            couple_id: coupleId.uuidString,
            sender_id: myUID.uuidString,
            date_key: todayKey
        )

        do {
            try await client.from("photo_requests").insert(payload).execute()
            self.nudgeSentToday = true
        } catch {
            print("Error sending nudge:", error)
        }
    }

    // Realtime Subscriptions (Guarded Single Registration)
    private func subscribeToRealtimeChannels(coupleId: UUID, myUID: UUID) async {
        guard !isSubscribed else { return }
        isSubscribed = true

        // 1. Couple Selfies Channel
        let sChannel = client.realtimeV2.channel("public:selfies:\(coupleId.uuidString.lowercased())")
        self.selfieChannel = sChannel

        let selfieChanges = sChannel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "couple_selfies"
        )

        Task {
            for await _ in selfieChanges {
                await self.fetchSelfiesOnly()
            }
        }
        await sChannel.subscribe()

        // 2. Photo Nudge Requests Channel
        let nChannel = client.realtimeV2.channel("public:nudges:\(coupleId.uuidString.lowercased())")
        self.nudgeChannel = nChannel

        let nudgeChanges = nChannel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "photo_requests"
        )

        Task { [weak self] in
            for await insert in nudgeChanges {
                guard let self = self else { return }
                var rawSenderString: String? = nil
                if let stringVal = insert.record["sender_id"]?.stringValue {
                    rawSenderString = stringVal
                } else if let dict = try? JSONSerialization.data(withJSONObject: insert.record),
                          let json = try? JSONSerialization.jsonObject(with: dict) as? [String: Any],
                          let sender = json["sender_id"] as? String {
                    rawSenderString = sender
                }

                guard let rawSender = rawSenderString,
                      let senderUUID = UUID(uuidString: rawSender) else { continue }

                if senderUUID != myUID && self.mySelfie == nil {
                    await MainActor.run {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            self.showNudgeReceivedBanner = true
                        }
                    }
                }
            }
        }
        await nChannel.subscribe()
    }

    func cleanup() {
        isSubscribed = false
        if let sc = selfieChannel { Task { await client.realtimeV2.removeChannel(sc) } }
        if let nc = nudgeChannel { Task { await client.realtimeV2.removeChannel(nc) } }
    }
}
