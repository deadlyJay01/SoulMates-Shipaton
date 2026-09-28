//
//  SupabaseService.swift
//  SoulMates
//

import Foundation
import Auth
import Supabase
import UIKit

enum SupabaseServiceError: LocalizedError {
    case invalidPhoneNumber
    case emailConfirmationRequired
    case imageUploadFailed(String)
    case profileSaveFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Enter a valid 10-digit mobile number."
        case .emailConfirmationRequired:
            return "Turn off Confirm email in Supabase Authentication -> Email. This app uses your phone number and password, not email confirmation."
        case .imageUploadFailed(let message):
            return "Your account was created, but the profile image could not be uploaded: \(message)"
        case .profileSaveFailed(let message):
            return "Your account was created, but the profile could not be saved: \(message)"
        }
    }
}

/// Owns the authenticated Supabase client and the app's profile persistence.
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://dzqkgselypjfeafjkidb.supabase.co")!,
            supabaseKey: "sb_publishable_RT8RtBnjkOLei_laSrxRIw_jATAEutN",
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }

    /// The app accepts a 10-digit Indian mobile number and adds +91 only for Supabase storage.
    func normalizedPhone(_ phone: String) throws -> String {
        let digits = phone.filter(\.isNumber)
        guard digits.count == 10 else {
            throw SupabaseServiceError.invalidPhoneNumber
        }
        return "+91\(digits)"
    }

    private func authEmail(for phone: String) -> String {
        "phone-\(phone.dropFirst())@soulmates.app"
    }

    /// Creates an account from the mobile-number/password fields and writes the onboarding profile.
    func signUpAndSaveProfile(phone: String, password: String, storage: AppStorageManager) async throws -> SignUpResult {
        let normalizedPhone = try normalizedPhone(phone)
        let response: AuthResponse
        do {
            response = try await client.auth.signUp(email: authEmail(for: normalizedPhone), password: password)
        } catch let error as AuthError {
            if error.errorCode == .emailExists || error.message.localizedCaseInsensitiveContains("already registered") {
                return .existingAccount
            }
            throw error
        }

        if response.session == nil, response.user.identities?.isEmpty == true {
            return .existingAccount
        }
        guard let session = response.session else { throw SupabaseServiceError.emailConfirmationRequired }

        var uploadedPath: String? = nil
        do {
            uploadedPath = try await uploadProfileImageIfNeeded(userID: session.user.id, storage: storage)
        } catch {
            throw SupabaseServiceError.imageUploadFailed(error.localizedDescription)
        }

        do {
            try await upsertProfile(userID: session.user.id, phone: normalizedPhone, imagePath: uploadedPath, storage: storage)
        } catch {
            throw SupabaseServiceError.profileSaveFailed(error.localizedDescription)
        }
        return .profileSaved
    }

    /// Logs in and completely syncs the authentic remote profile, overriding any onboarding draft values.
    func signInAndLoadProfile(phone: String, password: String, storage: AppStorageManager) async throws {
        let normalizedPhone = try normalizedPhone(phone)
        let session = try await client.auth.signIn(email: authEmail(for: normalizedPhone), password: password)

        let profile: SoulMatesProfile = try await client
            .from("profiles")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        await MainActor.run {
            profile.apply(to: storage)
            storage.profileImageData = Data()
        }

        if let path = profile.profileImagePath, !path.isEmpty {
            do {
                let data = try await client.storage
                    .from("profile-images")
                    .download(path: path)

                await MainActor.run {
                    storage.profileImageData = data
                    storage.hasProfileImage = true
                }
            } catch {
                print("Failed to download profile photo on sign in:", error)
            }
        }
    }

    /// Uploads profile image with a timestamped path to bust cache and trigger Postgres updates
    private func uploadProfileImageIfNeeded(userID: UUID, storage: AppStorageManager) async throws -> String? {
        guard storage.hasProfileImage, !storage.profileImageData.isEmpty else { return nil }

        let finalData: Data
        if let uiImage = UIImage(data: storage.profileImageData),
           let normalized = uiImage.normalizedJPEGData() {
            finalData = normalized
        } else {
            finalData = storage.profileImageData
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = "\(userID.uuidString.lowercased())/profile_\(timestamp).jpg"

        try await client.storage
            .from("profile-images")
            .upload(
                imagePath,
                data: finalData,
                options: FileOptions(cacheControl: "0", contentType: "image/jpeg", upsert: true)
            )
        return imagePath
    }

    private func upsertProfile(userID: UUID, phone: String, imagePath: String?, storage: AppStorageManager) async throws {
        let profile = SoulMatesProfile(
            id: userID,
            userName: storage.userName,
            userGender: storage.userGender,
            userPhone: phone,
            relationshipType: storage.relationshipType,
            anniversaryDateTimestamp: storage.anniversaryDateTimestamp,
            totalDaysTogether: storage.totalDaysTogether,
            hasProfileImage: storage.hasProfileImage,
            profileImagePath: imagePath
        )
        try await client.from("profiles").upsert(profile).execute()
    }

    func signOut(storage: AppStorageManager) async throws {
            try await client.auth.signOut()
            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: "has_skipped_partner_invite")
                storage.clearAllSessionData()
            }
        }
    /// Updates the user profile, uploads the fresh image, and pushes new path to Supabase
    func updateProfile(name: String, gender: Int, relationshipType: Int, storage: AppStorageManager) async throws {
        guard let currentUID = client.auth.currentUser?.id else { return }

        var newImagePath: String? = nil
        if storage.hasProfileImage && !storage.profileImageData.isEmpty {
            newImagePath = try await uploadProfileImageIfNeeded(userID: currentUID, storage: storage)
        }

        var updates: [String: AnyJSON] = [
            "user_name": .string(name),
            "user_gender": .integer(gender),
            "relationship_type": .integer(relationshipType),
            "has_profile_image": .bool(storage.hasProfileImage),
            "updated_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]

        if let path = newImagePath {
            updates["profile_image_path"] = .string(path)
        } else if !storage.hasProfileImage {
            updates["profile_image_path"] = .null
        }

        try await client.from("profiles")
            .update(updates)
            .eq("id", value: currentUID.uuidString)
            .execute()

        await MainActor.run {
            storage.userName = name
            storage.userGender = gender
            storage.relationshipType = relationshipType
        }
    }
}

// MARK: - Decodable Profile Model (Fully Null-Safe)
private struct SoulMatesProfile: Codable {
    let id: UUID
    let userName: String?
    let userGender: Int?
    let userPhone: String?
    let relationshipType: Int?
    let anniversaryDateTimestamp: Double?
    let totalDaysTogether: Int?
    let hasProfileImage: Bool?
    let profileImagePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userName = "user_name"
        case userGender = "user_gender"
        case userPhone = "user_phone"
        case relationshipType = "relationship_type"
        case anniversaryDateTimestamp = "anniversary_date_timestamp"
        case totalDaysTogether = "total_days_together"
        case hasProfileImage = "has_profile_image"
        case profileImagePath = "profile_image_path"
    }

    func apply(to storage: AppStorageManager) {
        storage.userName = userName ?? ""
        storage.userGender = userGender ?? 0
        storage.userPhone = userPhone ?? ""
        storage.relationshipType = relationshipType ?? 0
        storage.anniversaryDateTimestamp = anniversaryDateTimestamp ?? 0
        storage.totalDaysTogether = totalDaysTogether ?? 0
        storage.hasProfileImage = hasProfileImage ?? false
        storage.refreshTotalDaysTogether()
    }
}

enum SignUpResult {
    case profileSaved
    case existingAccount
}

// MARK: - Image Compression Helper
private extension UIImage {
    func normalizedJPEGData(compressionQuality: CGFloat = 0.8) -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1.0

        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        let cleanImage = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
        return cleanImage.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - Couple Note Model
struct CoupleNoteRecord: Codable, Identifiable {
    var id: UUID?
    let coupleId: UUID
    let userId: UUID
    let content: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
    }

    var isValid24Hr: Bool {
        guard let createdAt = createdAt else { return true }
        return Date().timeIntervalSince(createdAt) < (24 * 3600)
    }
}

extension SupabaseService {
    func fetchCoupleId() async -> UUID? {
        guard let uid = client.auth.currentUser?.id else { return nil }
        struct CoupleIDRow: Codable { let id: UUID }

        let rows: [CoupleIDRow] = (try? await client
            .from("couples")
            .select("id")
            .or("user1_id.eq.\(uid.uuidString),user2_id.eq.\(uid.uuidString)")
            .limit(1)
            .execute()
            .value) ?? []

        return rows.first?.id
    }

    func fetchCoupleNotes(coupleId: UUID) async -> [CoupleNoteRecord] {
        let records: [CoupleNoteRecord] = (try? await client
            .from("couple_notes")
            .select()
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value) ?? []

        return records.filter { $0.isValid24Hr }
    }

    func saveNote(content: String, coupleId: UUID) async throws {
        guard let currentUID = client.auth.currentUser?.id else { return }

        struct UpsertNotePayload: Codable {
            let couple_id: String
            let user_id: String
            let content: String
            let created_at: String
        }

        let isoDate = ISO8601DateFormatter().string(from: Date())
        let payload = UpsertNotePayload(
            couple_id: coupleId.uuidString,
            user_id: currentUID.uuidString,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            created_at: isoDate
        )

        try await client
            .from("couple_notes")
            .upsert(payload, onConflict: "couple_id,user_id")
            .execute()
    }

    // MARK: - Break Connection Method
        func breakConnection(storage: AppStorageManager) async throws {
            // 1. Call atomic deletion RPC in database
            try await client.rpc("break_couple_connection").execute()

            // 2. Clear local partner & couple Pro data
            await MainActor.run {
                storage.partnerName = ""
                storage.partnerProfileImageData = Data()
                storage.partnerHasProfileImage = false
                storage.relationshipType = 0
                storage.anniversaryDateTimestamp = 0
                storage.totalDaysTogether = 0
                storage.isLiveDistanceEnabled = false
                storage.calculatedDistanceKm = 0
                storage.isCouplePro = false
                storage.recalculateProAccess()
                storage.syncAllWidgetData()
            }
        }
        
        // MARK: - Verify & Live Sync Partner Status
        func verifyAndSyncPartnerStatus(storage: AppStorageManager) async {
            guard let currentUID = client.auth.currentUser?.id else { return }

            struct CoupleRow: Codable {
                let id: UUID
                let user1_id: UUID
                let user2_id: UUID
                let is_couple_pro: Bool?
            }

            let coupleList: [CoupleRow] = (try? await client
                .from("couples")
                .select("id, user1_id, user2_id, is_couple_pro")
                .or("user1_id.eq.\(currentUID.uuidString),user2_id.eq.\(currentUID.uuidString)")
                .limit(1)
                .execute()
                .value) ?? []

            if coupleList.isEmpty {
                await MainActor.run {
                    if !storage.partnerName.isEmpty {
                        storage.partnerName = ""
                        storage.partnerProfileImageData = Data()
                        storage.partnerHasProfileImage = false
                        storage.relationshipType = 0
                        storage.anniversaryDateTimestamp = 0
                        storage.totalDaysTogether = 0
                        storage.isLiveDistanceEnabled = false
                        storage.calculatedDistanceKm = 0
                        storage.partnerState = ""
                        storage.partnerCity = ""
                        storage.isCouplePro = false
                        storage.recalculateProAccess()
                        storage.syncAllWidgetData()
                    }
                }
            } else if let couple = coupleList.first {
                let partnerUID = (couple.user1_id == currentUID) ? couple.user2_id : couple.user1_id
                
                await MainActor.run {
                    storage.isCouplePro = couple.is_couple_pro ?? false
                    storage.recalculateProAccess()
                }

                struct PartnerNameRecord: Codable {
                    let userName: String?
                    enum CodingKeys: String, CodingKey {
                        case userName = "user_name"
                    }
                }
                
                if storage.partnerName.isEmpty || storage.partnerName.lowercased() == "partner" {
                    if let p: PartnerNameRecord = try? await client
                        .from("profiles")
                        .select("user_name")
                        .eq("id", value: partnerUID.uuidString)
                        .single()
                        .execute()
                        .value,
                       let name = p.userName, !name.isEmpty {
                        await MainActor.run {
                            storage.partnerName = name
                        }
                    }
                }
            }
        }
}
