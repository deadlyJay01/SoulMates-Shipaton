//
//  SelfieModel.swift
//  SoulMates
//

import Foundation

struct CoupleSelfie: Codable, Identifiable, Equatable {
    let id: UUID
    let coupleId: UUID
    let userId: UUID
    let imageUrl: String
    let dateKey: String
    let caption: String?
    var viewCount: Int
    let isTogether: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case userId = "user_id"
        case imageUrl = "image_url"
        case dateKey = "date_key"
        case caption
        case viewCount = "view_count"
        case isTogether = "is_together"
        case createdAt = "created_at"
    }
}
