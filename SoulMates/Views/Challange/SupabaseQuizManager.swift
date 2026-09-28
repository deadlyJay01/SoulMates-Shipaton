//
//  SupabaseQuizManager.swift
//  SoulMates
//
//  Created by Jay on 17/09/26.
//

import Foundation
import Supabase
import Combine

// MARK: - Supabase Table Payload Model

struct SupabaseQuizResponse: Codable, Identifiable {
    var id: UUID?
    let coupleId: UUID
    let userId: UUID
    let gameId: String
    let answers: [SavedQuizAnswer]
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case userId = "user_id"
        case gameId = "game_id"
        case answers
        case completedAt = "completed_at"
    }
}

// MARK: - Quiz Synchronization Service

@MainActor
final class SupabaseQuizManager: ObservableObject {
    static let shared = SupabaseQuizManager()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    @Published var completedGameIDs: Set<String> = []
    @Published var myAnswersByGame: [String: [SavedQuizAnswer]] = [:]
    @Published var partnerAnswersByGame: [String: [SavedQuizAnswer]] = [:]

    private var currentUID: String {
        client.auth.currentUser?.id.uuidString ?? "guest"
    }

    private var localKeyPrefix: String {
        "supabase_cached_quiz_\(currentUID)_"
    }

    init() {
        loadFromLocalStorage()
    }

    /// Fetches all quiz submissions for the couple
    func syncCoupleQuizResponses() async {
        guard let currentUser = client.auth.currentUser else { return }

        do {
            // Find couple record where the current user is user1 or user2
            let couples: [[String: String]] = try await client
                .from("couples")
                .select("id")
                .or("user1_id.eq.\(currentUser.id.uuidString),user2_id.eq.\(currentUser.id.uuidString)")
                .limit(1)
                .execute()
                .value

            guard let coupleRow = couples.first,
                  let coupleIdStr = coupleRow["id"],
                  let coupleId = UUID(uuidString: coupleIdStr) else {
                return
            }

            // Fetch all quiz responses for this couple
            let responses: [SupabaseQuizResponse] = try await client
                .from("quiz_responses")
                .select()
                .eq("couple_id", value: coupleId.uuidString)
                .execute()
                .value

            var myGames = Set<String>()
            var myMap: [String: [SavedQuizAnswer]] = [:]
            var partnerMap: [String: [SavedQuizAnswer]] = [:]

            for res in responses {
                if res.userId == currentUser.id {
                    myGames.insert(res.gameId)
                    myMap[res.gameId] = res.answers
                } else {
                    partnerMap[res.gameId] = res.answers
                }
            }

            self.completedGameIDs = myGames
            self.myAnswersByGame = myMap
            self.partnerAnswersByGame = partnerMap
            self.saveToLocalStorage()
        } catch {
            print("Failed to sync quiz responses from Supabase:", error)
        }
    }

    /// Submits quiz answers to Supabase and updates local storage
    func submitQuiz(gameID: String, answers: [SavedQuizAnswer]) async throws {
        guard let currentUser = client.auth.currentUser else { return }

        // Find couple record
        let couples: [[String: String]] = try await client
            .from("couples")
            .select("id")
            .or("user1_id.eq.\(currentUser.id.uuidString),user2_id.eq.\(currentUser.id.uuidString)")
            .limit(1)
            .execute()
            .value

        guard let coupleRow = couples.first,
              let coupleIdStr = coupleRow["id"],
              let coupleId = UUID(uuidString: coupleIdStr) else {
            return
        }

        let payload = SupabaseQuizResponse(
            coupleId: coupleId,
            userId: currentUser.id,
            gameId: gameID,
            answers: answers
        )

        // Targeted upsert on composite unique key
        try await client
            .from("quiz_responses")
            .upsert(payload, onConflict: "user_id,game_id")
            .execute()

        // Update local memory and cache
        self.completedGameIDs.insert(gameID)
        self.myAnswersByGame[gameID] = answers
        self.saveToLocalStorage()
    }

    func isCompleted(gameID: String) -> Bool {
        completedGameIDs.contains(gameID) || (myAnswersByGame[gameID] != nil && !myAnswersByGame[gameID]!.isEmpty)
    }

    func getMyAnswers(gameID: String) -> [SavedQuizAnswer] {
        myAnswersByGame[gameID] ?? []
    }

    func getPartnerAnswers(gameID: String) -> [SavedQuizAnswer]? {
        partnerAnswersByGame[gameID]
    }

    private func saveToLocalStorage() {
        if let data = try? JSONEncoder().encode(Array(completedGameIDs)) {
            UserDefaults.standard.set(data, forKey: localKeyPrefix + "completed_ids")
        }
        if let data = try? JSONEncoder().encode(myAnswersByGame) {
            UserDefaults.standard.set(data, forKey: localKeyPrefix + "my_answers")
        }
        if let data = try? JSONEncoder().encode(partnerAnswersByGame) {
            UserDefaults.standard.set(data, forKey: localKeyPrefix + "partner_answers")
        }
    }

    private func loadFromLocalStorage() {
        if let data = UserDefaults.standard.data(forKey: localKeyPrefix + "completed_ids"),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            self.completedGameIDs = Set(ids)
        }
        if let data = UserDefaults.standard.data(forKey: localKeyPrefix + "my_answers"),
           let map = try? JSONDecoder().decode([String: [SavedQuizAnswer]].self, from: data) {
            self.myAnswersByGame = map
        }
        if let data = UserDefaults.standard.data(forKey: localKeyPrefix + "partner_answers"),
           let map = try? JSONDecoder().decode([String: [SavedQuizAnswer]].self, from: data) {
            self.partnerAnswersByGame = map
        }
    }
    func clearCache() {
        self.completedGameIDs.removeAll()
        self.myAnswersByGame.removeAll()
        self.partnerAnswersByGame.removeAll()
    }
}
