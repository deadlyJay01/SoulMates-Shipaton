//
//  DailyQuestionViewModel.swift
//  SoulMates
//

import SwiftUI
import Supabase
import Combine

@MainActor
final class DailyQuestionViewModel: ObservableObject {
    @Published var todaysQuestion: DailyQuestion = DailyQuestionBank.questionForDate()
    @Published var myAnswer: String? = nil
    @Published var partnerAnswer: String? = nil
    @Published var isSubmitting: Bool = false
    @Published var isLoading: Bool = true
    @Published var currentStreak: Int = 0
    @Published var bothAnswered: Bool = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    private var coupleId: UUID? = nil
    private var realtimeChannel: RealtimeChannelV2?

    struct ResponseRecord: Codable {
        let userId: UUID
        let dateKey: String
        let selectedOption: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case dateKey = "date_key"
            case selectedOption = "selected_option"
        }
    }

    func loadDailyData() async {
        isLoading = true
        guard let cId = await SupabaseService.shared.fetchCoupleId(),
              let myUID = client.auth.currentUser?.id else {
            isLoading = false
            return
        }
        self.coupleId = cId

        await fetchTodayResponses(coupleId: cId, myUID: myUID)
        await calculateStreak(coupleId: cId)
        await subscribeToDailyResponses(coupleId: cId, myUID: myUID)
        isLoading = false
    }

    func fetchTodayResponses(coupleId: UUID, myUID: UUID) async {
        let todayKey = DailyQuestionBank.dateKey()

        do {
            let responses: [ResponseRecord] = try await client
                .from("daily_question_responses")
                .select("user_id, date_key, selected_option")
                .eq("couple_id", value: coupleId.uuidString)
                .eq("date_key", value: todayKey)
                .execute()
                .value

            let myResp = responses.first(where: { $0.userId == myUID })
            let partnerResp = responses.first(where: { $0.userId != myUID })

            self.myAnswer = myResp?.selectedOption
            
            // Only reveal partner's answer if both have completed today
            if myResp != nil && partnerResp != nil {
                self.partnerAnswer = partnerResp?.selectedOption
                self.bothAnswered = true
            } else {
                self.partnerAnswer = nil
                self.bothAnswered = false
            }
        } catch {
            print("Error loading daily responses:", error)
        }
    }

    func submitAnswer(_ option: String) async {
        guard let coupleId = self.coupleId,
              let myUID = client.auth.currentUser?.id else { return }

        isSubmitting = true
        let todayKey = DailyQuestionBank.dateKey()

        struct InsertPayload: Codable {
            let couple_id: String
            let user_id: String
            let question_id: Int
            let date_key: String
            let selected_option: String
        }

        let payload = InsertPayload(
            couple_id: coupleId.uuidString,
            user_id: myUID.uuidString,
            question_id: todaysQuestion.id,
            date_key: todayKey,
            selected_option: option
        )

        do {
            try await client
                .from("daily_question_responses")
                .upsert(payload)
                .execute()

            self.myAnswer = option
            await fetchTodayResponses(coupleId: coupleId, myUID: myUID)
            await calculateStreak(coupleId: coupleId)
        } catch {
            print("Error submitting daily answer:", error)
        }
        isSubmitting = false
    }

    // MARK: - Consecutive Streak Calculation
        func calculateStreak(coupleId: UUID) async {
            do {
                let rows: [ResponseRecord] = try await client
                    .from("daily_question_responses")
                    .select("user_id, date_key, selected_option")
                    .eq("couple_id", value: coupleId.uuidString)
                    .order("date_key", ascending: false)
                    .execute()
                    .value

                var responsesByDate: [String: Set<UUID>] = [:]
                for row in rows {
                    responsesByDate[row.dateKey, default: []].insert(row.userId)
                }

                let calendar = Calendar.current
                var checkDate = Date()
                var streak = 0

                let todayKey = DailyQuestionBank.dateKey(for: checkDate)
                let todayCount = responsesByDate[todayKey]?.count ?? 0

                // If today has answers (both or at least user completed), begin tally
                if todayCount >= 2 {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else if let myUID = client.auth.currentUser?.id,
                          responsesByDate[todayKey]?.contains(myUID) == true {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else {
                    // If today is not answered yet, check if yesterday was completed
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                        self.currentStreak = 0
                        return
                    }
                    let yesterdayKey = DailyQuestionBank.dateKey(for: yesterday)
                    if (responsesByDate[yesterdayKey]?.count ?? 0) == 0 {
                        self.currentStreak = 0
                        return
                    }
                    checkDate = yesterday
                }

                // Count every consecutive previous day
                while true {
                    let key = DailyQuestionBank.dateKey(for: checkDate)
                    if (responsesByDate[key]?.count ?? 0) >= 1 {
                        streak += 1
                        guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                        checkDate = prev
                    } else {
                        break
                    }
                }

                self.currentStreak = streak
            } catch {
                print("Streak calculation error:", error)
                self.currentStreak = 0
            }
        }

    private func subscribeToDailyResponses(coupleId: UUID, myUID: UUID) async {
            // Prevent duplicate channel registrations
            guard realtimeChannel == nil else { return }

            let uniqueTopic = "daily_\(coupleId.uuidString.lowercased())_\(UUID().uuidString.prefix(6))"
            let channel = client.realtimeV2.channel(uniqueTopic)
            self.realtimeChannel = channel

            let changes = channel.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "daily_question_responses"
            )

            Task {
                for await _ in changes {
                    await self.fetchTodayResponses(coupleId: coupleId, myUID: myUID)
                    await self.calculateStreak(coupleId: coupleId)
                }
            }

            await channel.subscribe()
        }

    func cleanup() {
        if let channel = realtimeChannel {
            Task {
                await client.realtimeV2.removeChannel(channel)
            }
        }
    }
}
