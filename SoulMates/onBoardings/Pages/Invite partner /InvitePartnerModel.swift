//
//  InvitePartnerModel.swift
//  SoulMates
//

import Foundation

struct ProfileInviteCode: Codable {
    let inviteCode: String?

    enum CodingKeys: String, CodingKey {
        case inviteCode = "invite_code"
    }
}

struct PartnerProfileData: Codable {
    let id: UUID
    let userName: String?
    let anniversaryDateTimestamp: Double?
    let relationshipType: Int?
    let totalDaysTogether: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case anniversaryDateTimestamp = "anniversary_date_timestamp"
        case relationshipType = "relationship_type"
        case totalDaysTogether = "total_days_together"
    }
}

struct CouplePairingPayload: Codable {
    let user1Id: UUID
    let user2Id: UUID

    enum CodingKeys: String, CodingKey {
        case user1Id = "user1_id"
        case user2Id = "user2_id"
    }
}
