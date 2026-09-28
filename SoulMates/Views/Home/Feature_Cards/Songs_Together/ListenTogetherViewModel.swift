//
//  ListenTogetherViewModel.swift
//  SoulMates
//

import SwiftUI
import AVFoundation
import Supabase
import Combine

@MainActor
final class ListenTogetherViewModel: ObservableObject {
    @Published var activeSession: CoupleMusicSessionRecord? = nil
    @Published var currentTrack: SongTrack = SongTrack.catalogue[0]
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var duration: Double = 1.0

    // Alerts & Sheet routing
    @Published var isWaitingForPartnerAccept: Bool = false
    @Published var showIncomingInviteAlert: Bool = false
    @Published var showMustPairFirstAlert: Bool = false
    @Published var showRejectedAlert: Bool = false
    @Published var showEndedAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isPlayerPresented: Bool = false

    // Liked songs shared set
    @Published var likedTrackIds: Set<Int> = []

    var isPaired: Bool {
        activeSession?.status == "active"
    }

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: AnyCancellable?
    private var realtimeChannel: RealtimeChannelV2?
    private var coupleId: UUID? = nil
    private var partnerId: UUID? = nil
    private var isColdStart: Bool = true

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    var currentUserId: UUID? {
        client.auth.currentUser?.id
    }

    // MARK: - Payloads for Type-Safe Updates
    private struct SessionUpdatePayload: Codable {
        let track_id: Int
        let is_playing: Bool
        let seek_seconds: Double
        let status: String
        let last_action_by: String
        let updated_at: String
    }

    // MARK: - Lifecycle
    func start() async {
        guard let cid = await SupabaseService.shared.fetchCoupleId(),
              let myUID = currentUserId else { return }
        self.coupleId = cid

        await fetchPartnerId(coupleId: cid, myUID: myUID)
        await fetchLikedSongs()
        await subscribeToSyncChannel(coupleId: cid)
        await checkExistingSession(initialLoad: true)
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
        if let couple: CoupleRow = try? await client
            .from("couples")
            .select("user1_id, user2_id")
            .eq("id", value: coupleId.uuidString)
            .single()
            .execute()
            .value {
            self.partnerId = (couple.user1Id == myUID) ? couple.user2Id : couple.user1Id
        }
    }

    // MARK: - Audio Engine
    private func setupAudio(for track: SongTrack) {
        if let url = Bundle.main.url(forResource: track.audioFileName, withExtension: track.audioFileExtension) {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                self.duration = audioPlayer?.duration ?? track.durationSeconds
            } catch {
                print("AVAudioPlayer error: \(error)")
            }
        } else {
            self.duration = track.durationSeconds
        }
    }

    private func runLocalTimer() {
        progressTimer?.cancel()
        progressTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            if player.isPlaying {
                self.currentTime = player.currentTime
            }
        }
    }

    // MARK: - Pair / Unpair Flow
    func handlePairUnpairButton(actorName: String) async {
        if isPaired {
            await endListening(actorName: actorName)
        } else {
            await requestListenTogether(track: currentTrack, myName: actorName)
        }
    }

    // MARK: - Row Tap Dispatcher
    func handleRowPlayTap(track: SongTrack, actorName: String) async {
        guard isPaired else {
            // Requirement 1: Prompt alert if unpaired
            self.showMustPairFirstAlert = true
            return
        }

        if currentTrack.id == track.id {
            await togglePlayPause(actorName: actorName)
        } else {
            await changeTrack(to: track, actorName: actorName)
        }
    }

    // MARK: - Synchronized Actions
    func requestListenTogether(track: SongTrack, myName: String) async {
        guard let cid = coupleId, let myUID = currentUserId, let pId = partnerId else { return }
        self.currentTrack = track
        setupAudio(for: track)

        let session = CoupleMusicSessionRecord(
            id: nil,
            coupleId: cid,
            initiatedBy: myUID,
            partnerId: pId,
            trackId: track.id,
            isPlaying: false,
            seekSeconds: 0,
            status: "invited",
            lastActionBy: myName,
            updatedAt: Date()
        )

        do {
            try await client.from("couple_music_sessions").upsert(session, onConflict: "couple_id").execute()
            // Requirement 3: User 1 sees waiting alert with Cancel button
            self.isWaitingForPartnerAccept = true
        } catch {
            print("Failed to invite partner: \(error)")
        }
    }

    func cancelPairInvite(actorName: String) async {
        self.isWaitingForPartnerAccept = false
        guard let cid = coupleId else { return }

        let payload = SessionUpdatePayload(
            track_id: currentTrack.id,
            is_playing: false,
            seek_seconds: 0.0,
            status: "ended",
            last_action_by: actorName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await client.from("couple_music_sessions")
            .update(payload)
            .eq("couple_id", value: cid.uuidString)
            .execute()
    }

    func acceptInvite(partnerName: String) async {
        guard let cid = coupleId else { return }
        self.showIncomingInviteAlert = false

        // Requirement 3: Sync to the exact track chosen by the inviter
        if let sessionTrackId = activeSession?.trackId,
           let matchedTrack = SongTrack.catalogue.first(where: { $0.id == sessionTrackId }) {
            self.currentTrack = matchedTrack
        }

        setupAudio(for: currentTrack)
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        self.isPlaying = true
        runLocalTimer()
        self.isPlayerPresented = true

        let payload = SessionUpdatePayload(
            track_id: currentTrack.id,
            is_playing: true,
            seek_seconds: 0.0,
            status: "active",
            last_action_by: partnerName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            try await client.from("couple_music_sessions")
                .update(payload)
                .eq("couple_id", value: cid.uuidString)
                .execute()
        } catch {
            print("Accept error: \(error)")
        }
    }

    func declineInvite(myName: String) async {
        guard let cid = coupleId else { return }
        self.showIncomingInviteAlert = false

        let payload = SessionUpdatePayload(
            track_id: currentTrack.id,
            is_playing: false,
            seek_seconds: 0.0,
            status: "declined",
            last_action_by: myName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await client.from("couple_music_sessions")
            .update(payload)
            .eq("couple_id", value: cid.uuidString)
            .execute()
    }

    func togglePlayPause(actorName: String) async {
        guard let cid = coupleId, isPaired else {
            self.showMustPairFirstAlert = true
            return
        }

        let nextPlayState = !isPlaying
        let currentSeek = audioPlayer?.currentTime ?? currentTime

        if nextPlayState {
            audioPlayer?.currentTime = currentSeek
            audioPlayer?.play()
        } else {
            audioPlayer?.pause()
        }
        self.isPlaying = nextPlayState

        let payload = SessionUpdatePayload(
            track_id: currentTrack.id,
            is_playing: nextPlayState,
            seek_seconds: currentSeek,
            status: "active",
            last_action_by: actorName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await client.from("couple_music_sessions")
            .update(payload)
            .eq("couple_id", value: cid.uuidString)
            .execute()
    }

    func changeTrack(to track: SongTrack, actorName: String) async {
        guard let cid = coupleId, isPaired else {
            self.showMustPairFirstAlert = true
            return
        }

        self.currentTrack = track
        setupAudio(for: track)
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
        self.isPlaying = true
        self.currentTime = 0
        runLocalTimer()

        let payload = SessionUpdatePayload(
            track_id: track.id,
            is_playing: true,
            seek_seconds: 0.0,
            status: "active",
            last_action_by: actorName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await client.from("couple_music_sessions")
            .update(payload)
            .eq("couple_id", value: cid.uuidString)
            .execute()
    }

    func endListening(actorName: String) async {
        guard let cid = coupleId else { return }
        audioPlayer?.stop()
        progressTimer?.cancel()
        self.isPlaying = false
        self.isPlayerPresented = false
        self.isWaitingForPartnerAccept = false

        if var current = self.activeSession {
            current.status = "ended"
            current.isPlaying = false
            current.lastActionBy = actorName
            self.activeSession = current
        }

        let payload = SessionUpdatePayload(
            track_id: currentTrack.id,
            is_playing: false,
            seek_seconds: 0.0,
            status: "ended",
            last_action_by: actorName,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        _ = try? await client.from("couple_music_sessions")
            .update(payload)
            .eq("couple_id", value: cid.uuidString)
            .execute()
    }

    // MARK: - Liked Songs
    func fetchLikedSongs() async {
        guard let cid = coupleId else { return }
        let records: [CoupleLikedSongRecord] = (try? await client
            .from("couple_liked_songs")
            .select()
            .eq("couple_id", value: cid.uuidString)
            .execute()
            .value) ?? []

        self.likedTrackIds = Set(records.map { $0.trackId })
    }

    func toggleLike(trackId: Int, userName: String) async {
        guard let cid = coupleId else { return }

        if likedTrackIds.contains(trackId) {
            likedTrackIds.remove(trackId)
            _ = try? await client
                .from("couple_liked_songs")
                .delete()
                .eq("couple_id", value: cid.uuidString)
                .eq("track_id", value: trackId)
                .execute()
        } else {
            likedTrackIds.insert(trackId)
            struct LikePayload: Codable {
                let couple_id: String
                let track_id: Int
                let liked_by_name: String
            }
            let payload = LikePayload(couple_id: cid.uuidString, track_id: trackId, liked_by_name: userName)
            _ = try? await client.from("couple_liked_songs").upsert(payload, onConflict: "couple_id,track_id").execute()
        }
    }

    // MARK: - Realtime Sync Subscription
    private func checkExistingSession(initialLoad: Bool = false) async {
        guard let cid = coupleId else { return }
        do {
            let session: CoupleMusicSessionRecord = try await client
                .from("couple_music_sessions")
                .select()
                .eq("couple_id", value: cid.uuidString)
                .single()
                .execute()
                .value

            handleSessionUpdate(session, initialLoad: initialLoad)
        } catch {
            print("Session query error: \(error)")
        }
    }

    private func subscribeToSyncChannel(coupleId: UUID) async {
            // Prevent duplicate registrations
            guard realtimeChannel == nil else { return }

            let uniqueTopic = "music_\(coupleId.uuidString.lowercased())_\(UUID().uuidString.prefix(6))"
            let channel = client.realtimeV2.channel(uniqueTopic)
            self.realtimeChannel = channel

            let sessionChanges = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "couple_music_sessions"
            )
            let likeChanges = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "couple_liked_songs"
            )

            Task {
                for await _ in sessionChanges {
                    await self.checkExistingSession(initialLoad: false)
                }
            }
            Task {
                for await _ in likeChanges {
                    await self.fetchLikedSongs()
                }
            }

            await channel.subscribe()
        }

    private func handleSessionUpdate(_ session: CoupleMusicSessionRecord, initialLoad: Bool = false) {
        guard let myUID = currentUserId else { return }

        let previousStatus = self.activeSession?.status
        self.activeSession = session

        // 1. Synchronize track selection
        if let track = SongTrack.catalogue.first(where: { $0.id == session.trackId }) {
            if self.currentTrack.id != track.id {
                self.currentTrack = track
                setupAudio(for: track)
                if session.isPlaying && session.status == "active" {
                    audioPlayer?.currentTime = session.seekSeconds
                    audioPlayer?.play()
                    self.isPlaying = true
                    runLocalTimer()
                }
            }
        }

        switch session.status {
        case "invited":
            if session.partnerId == myUID {
                // Partner sent an invite to me
                if let updated = session.updatedAt, Date().timeIntervalSince(updated) < 300 {
                    self.showIncomingInviteAlert = true
                }
            } else if session.initiatedBy == myUID && !initialLoad {
                self.isWaitingForPartnerAccept = true
            }

        case "active":
            self.showIncomingInviteAlert = false
            self.isWaitingForPartnerAccept = false

            // Requirement: Prevent sheet from auto-popping on app start
            if previousStatus == "invited" && !initialLoad {
                self.isPlayerPresented = true
            }

            if session.isPlaying {
                if !(audioPlayer?.isPlaying ?? false) {
                    audioPlayer?.currentTime = session.seekSeconds
                    audioPlayer?.play()
                    self.isPlaying = true
                    runLocalTimer()
                }
            } else {
                if audioPlayer?.isPlaying ?? false {
                    audioPlayer?.pause()
                    self.isPlaying = false
                }
            }

        case "declined":
            self.isWaitingForPartnerAccept = false
            self.showIncomingInviteAlert = false
            if previousStatus == "invited" && session.initiatedBy == myUID && !initialLoad {
                self.alertMessage = "\(session.lastActionBy) declined your music invite."
                self.showRejectedAlert = true
            }
            audioPlayer?.stop()
            self.isPlaying = false

        case "ended":
            self.isWaitingForPartnerAccept = false
            self.showIncomingInviteAlert = false
            self.isPlayerPresented = false
            audioPlayer?.stop()
            self.isPlaying = false

            // Requirement 4: Alert partner that other user unpaired
            if previousStatus == "active" && session.lastActionBy != (activeSession?.lastActionBy ?? "") && !initialLoad {
                self.alertMessage = "\(session.lastActionBy) unpaired the listening session."
                self.showEndedAlert = true
            }

        default:
            break
        }

        if initialLoad {
            self.isColdStart = false
        }
    }

    func cleanup() {
        audioPlayer?.stop()
        progressTimer?.cancel()
        if let rc = realtimeChannel {
            Task { await client.realtimeV2.removeChannel(rc) }
        }
    }
}
