//
//  ChatViewModel.swift
//  SoulMates
//

import SwiftUI
import Supabase
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var messageText: String = ""
    @Published var isLoading: Bool = true
    @Published var coupleId: UUID? = nil
    @Published var isUploadingAudio: Bool = false

    let audioManager = AudioRecorderManager()
    private var cancellables: Set<AnyCancellable> = []

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    private var realtimeChannel: RealtimeChannelV2?

    init() {
        // Forward audioManager's state changes to ChatViewModel so SwiftUI re-renders in real time
        audioManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func initializeChat() async {
        isLoading = true
        guard let coupleId = await SupabaseService.shared.fetchCoupleId() else {
            isLoading = false
            return
        }
        self.coupleId = coupleId
        await loadMessages(coupleId: coupleId)
        await subscribeToMessages(coupleId: coupleId)
        isLoading = false
    }

    // MARK: - Fetch Active Messages (< 24 Hours)
    func loadMessages(coupleId: UUID) async {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 3600)
        let isoDate = ISO8601DateFormatter().string(from: twentyFourHoursAgo)

        do {
            let fetched: [ChatMessage] = try await client
                .from("messages")
                .select()
                .eq("couple_id", value: coupleId.uuidString)
                .gte("created_at", value: isoDate)
                .order("created_at", ascending: true)
                .execute()
                .value

            self.messages = fetched.filter { $0.isWithin24Hours }
        } catch {
            print("Failed to fetch messages:", error)
        }
    }

    // MARK: - Send Text Message
    func sendMessage() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              let coupleId = coupleId,
              let senderId = currentUserId else { return }

        messageText = ""

        struct NewMessagePayload: Codable {
            let couple_id: String
            let sender_id: String
            let content: String
        }

        let payload = NewMessagePayload(
            couple_id: coupleId.uuidString,
            sender_id: senderId.uuidString,
            content: text
        )

        do {
            try await client
                .from("messages")
                .insert(payload)
                .execute()
        } catch {
            print("Failed to send message:", error)
        }
    }

    // MARK: - Upload and Send Voice Note
    func sendVoiceNote(fileURL: URL) async {
        guard let coupleId = coupleId,
              let senderId = currentUserId,
              let audioData = try? Data(contentsOf: fileURL) else { return }

        isUploadingAudio = true
        let fileName = "\(coupleId.uuidString)/\(UUID().uuidString).m4a"

        do {
            _ = try await client.storage
                .from("chat-voice-notes")
                .upload(fileName, data: audioData, options: FileOptions(contentType: "audio/m4a", upsert: true))

            let publicURL = try client.storage
                .from("chat-voice-notes")
                .getPublicURL(path: fileName)

            struct NewMessagePayload: Codable {
                let couple_id: String
                let sender_id: String
                let content: String
            }

            let payload = NewMessagePayload(
                couple_id: coupleId.uuidString,
                sender_id: senderId.uuidString,
                content: "[voice]\(publicURL.absoluteString)"
            )

            try await client
                .from("messages")
                .insert(payload)
                .execute()

            try? FileManager.default.removeItem(at: fileURL)
        } catch {
            print("Failed to upload audio message:", error)
        }
        isUploadingAudio = false
    }

    // MARK: - Realtime Stream
    private func subscribeToMessages(coupleId: UUID) async {
        let channel = client.realtimeV2.channel("public:messages:\(coupleId.uuidString)")
        self.realtimeChannel = channel

        let insertions = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "messages"
        )

        Task {
            for await _ in insertions {
                await self.loadMessages(coupleId: coupleId)
            }
        }

        do {
            try await channel.subscribe()
        } catch {
            print("Realtime subscription error:", error)
        }
    }

    func cleanup() {
        audioManager.stopPlayback()
        if let channel = realtimeChannel {
            Task {
                await client.realtimeV2.removeChannel(channel)
            }
        }
    }
}
