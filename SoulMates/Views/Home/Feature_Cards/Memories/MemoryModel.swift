//
//  MemoryModel.swift
//  SoulMates
//

import Foundation
import SwiftUI
import Supabase
import PhotosUI

struct CoupleMemory: Identifiable, Codable {
    let id: UUID
    let coupleId: UUID
    let uploadedBy: UUID
    let uploaderName: String
    let memoryDate: String
    let description: String?
    let photoUrls: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case uploadedBy = "uploaded_by"
        case uploaderName = "uploader_name"
        case memoryDate = "memory_date"
        case description
        case photoUrls = "photo_urls"
        case createdAt = "created_at"
    }
    
    var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: memoryDate) ?? Date()
    }
    
    var displayDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: parsedDate)
    }
}

// MARK: - Supabase Service Extension for Memories
extension SupabaseService {
    
    /// Fetches the user's active couple ID
    func fetchCurrentCoupleId() async throws -> UUID? {
        guard let currentUID = client.auth.currentUser?.id else { return nil }
        
        struct CoupleCheck: Codable {
            let id: UUID
        }
        
        let results: [CoupleCheck] = try await client
            .from("couples")
            .select("id")
            .or("user1_id.eq.\(currentUID.uuidString),user2_id.eq.\(currentUID.uuidString)")
            .limit(1)
            .execute()
            .value
            
        return results.first?.id
    }

    /// Fetches all memories sorted chronologically by memory_date descending
    func fetchMemories(for coupleId: UUID) async throws -> [CoupleMemory] {
        return try await client
            .from("memories")
            .select()
            .eq("couple_id", value: coupleId.uuidString)
            .order("memory_date", ascending: false)
            .execute()
            .value
    }
    
    /// Uploads an array of UIImages and returns the public URLs
    func uploadMemoryPhotos(images: [UIImage], coupleId: UUID) async throws -> [String] {
        var uploadedURLs: [String] = []
        
        for image in images {
            guard let data = image.jpegData(compressionQuality: 0.75) else { continue }
            let fileName = "\(coupleId.uuidString)/\(UUID().uuidString).jpg"
            
            try await client.storage
                .from("memory-images")
                .upload(fileName, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            
            let publicURL = try client.storage
                .from("memory-images")
                .getPublicURL(path: fileName)
            
            uploadedURLs.append(publicURL.absoluteString)
        }
        
        return uploadedURLs
    }

    /// Inserts a new memory record (Read-only once stored)
    func createMemory(
        coupleId: UUID,
        uploaderName: String,
        date: Date,
        description: String,
        photoUrls: [String]
    ) async throws {
        guard let currentUID = client.auth.currentUser?.id else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        struct NewMemoryPayload: Codable {
            let couple_id: UUID
            let uploaded_by: UUID
            let uploader_name: String
            let memory_date: String
            let description: String
            let photo_urls: [String]
        }
        
        let payload = NewMemoryPayload(
            couple_id: coupleId,
            uploaded_by: currentUID,
            uploader_name: uploaderName,
            memory_date: dateString,
            description: description,
            photo_urls: photoUrls
        )
        
        try await client
            .from("memories")
            .insert(payload)
            .execute()
    }

    /// Permanently deletes a single memory
    func deleteMemory(id: UUID) async throws {
        try await client
            .from("memories")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
