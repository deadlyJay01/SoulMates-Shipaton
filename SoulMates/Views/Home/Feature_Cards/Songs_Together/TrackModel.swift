//
//  TrackModel.swift
//  SoulMates
//

import Foundation

struct SongTrack: Identifiable, Equatable, Codable {
    let id: Int
    let title: String
    let artist: String
    let durationSeconds: Double
    let coverImageName: String
    let audioFileName: String
    let audioFileExtension: String

    var formattedDuration: String {
        let mins = Int(durationSeconds) / 60
        let secs = Int(durationSeconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // Static 10 bundled couple tracks
    static let catalogue: [SongTrack] = [
        SongTrack(id: 1, title: "Golden Hour Reverie", artist: "SoulMates Acoustic", durationSeconds: 198, coverImageName: "cover_1", audioFileName: "track_1", audioFileExtension: "mp3"),
        SongTrack(id: 2, title: "Midnight Whispers", artist: "Luna & The Stars", durationSeconds: 214, coverImageName: "cover_2", audioFileName: "track_2", audioFileExtension: "mp3"),
        SongTrack(id: 3, title: "Wrapped In You", artist: "Velvet Breeze", durationSeconds: 184, coverImageName: "cover_3", audioFileName: "track_3", audioFileExtension: "mp3"),
        SongTrack(id: 4, title: "Coffee & Rainy Days", artist: "Lo-Fi Romance", durationSeconds: 165, coverImageName: "cover_4", audioFileName: "track_4", audioFileExtension: "mp3"),
        SongTrack(id: 5, title: "Spontaneous Highway", artist: "Sunset Boulevard", durationSeconds: 242, coverImageName: "cover_5", audioFileName: "track_5", audioFileExtension: "mp3"),
        SongTrack(id: 6, title: "Forehead Kisses", artist: "Honeydew Acoustic", durationSeconds: 176, coverImageName: "cover_6", audioFileName: "track_6", audioFileExtension: "mp3"),
        SongTrack(id: 7, title: "Constellations", artist: "Starlight Echoes", durationSeconds: 205, coverImageName: "cover_7", audioFileName: "track_7", audioFileExtension: "mp3"),
        SongTrack(id: 8, title: "Slow Dance at 2 AM", artist: "The Vinyl Trio", durationSeconds: 228, coverImageName: "cover_8", audioFileName: "track_8", audioFileExtension: "mp3"),
        SongTrack(id: 9, title: "Holding Hands in Silence", artist: "Cider Melodies", durationSeconds: 192, coverImageName: "cover_9", audioFileName: "track_9", audioFileExtension: "mp3"),
        SongTrack(id: 10, title: "Our Little Secret", artist: "Jay & Tirth Beats", durationSeconds: 210, coverImageName: "cover_10", audioFileName: "track_10", audioFileExtension: "mp3")
    ]
}

struct CoupleMusicSessionRecord: Codable {
    let id: UUID?
    let coupleId: UUID
    let initiatedBy: UUID
    let partnerId: UUID
    var trackId: Int
    var isPlaying: Bool
    var seekSeconds: Double
    var status: String // "invited", "active", "declined", "ended"
    var lastActionBy: String
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case initiatedBy = "initiated_by"
        case partnerId = "partner_id"
        case trackId = "track_id"
        case isPlaying = "is_playing"
        case seekSeconds = "seek_seconds"
        case status
        case lastActionBy = "last_action_by"
        case updatedAt = "updated_at"
    }
}

struct CoupleLikedSongRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let coupleId: UUID
    let trackId: Int
    let likedByName: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case trackId = "track_id"
        case likedByName = "liked_by_name"
    }
}
