//
//  ChatMessageModel.swift
//  SoulMates
//

import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let coupleId: UUID
    let senderId: UUID
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case senderId = "sender_id"
        case content
        case createdAt = "created_at"
    }

    /// Checks if this message is a stored audio note
    var isVoiceNote: Bool {
        content.hasPrefix("[voice]") || (content.hasPrefix("https://") && content.contains("chat-voice-notes"))
    }

    /// Extracts clean audio URL if it is a voice note
    var voiceAudioURL: String? {
        if content.hasPrefix("[voice]") {
            return String(content.dropFirst(7))
        } else if isVoiceNote {
            return content
        }
        return nil
    }

    /// Validates if the message is within the 24-hour window
    var isWithin24Hours: Bool {
        Date().timeIntervalSince(createdAt) < (24 * 3600)
    }

    /// Localized formatted time (e.g., "10:42 AM")
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
