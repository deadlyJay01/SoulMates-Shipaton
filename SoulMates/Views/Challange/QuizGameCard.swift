//
//  QuizGameCard.swift
//  SoulMates
//

import SwiftUI

struct QuizGameCard: View {
    let game: QuizGame

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: Top Section (Emoji & Completion Check)
            HStack {
                Text(game.emoji)
                    .font(.system(size: 38))

                Spacer()

                if QuizStorage.isCompleted(gameID: game.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(color: game.color.opacity(0.8), radius: 6)
                }
            }

            Spacer(minLength: 4)

            // MARK: Title
            Text(game.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            // MARK: Description
            Text(game.description)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 170, height: 170)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [
                            game.color.opacity(0.75),
                            game.color.opacity(0.25),
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.25),
                            game.color.opacity(0.3),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        }
        .shadow(color: game.color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Quiz Persistence

enum QuizStorage {
    private static let keyPrefix = "quiz_answers_"

    static func saveAnswers(gameID: String, answers: [SavedQuizAnswer]) {
        let key = keyPrefix + gameID
        do {
            let data = try JSONEncoder().encode(answers)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Could not save answers for \(gameID):", error)
        }
    }

    static func getAnswers(gameID: String) -> [SavedQuizAnswer] {
        let key = keyPrefix + gameID
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([SavedQuizAnswer].self, from: data)
        } catch {
            print("Could not decode answers for \(gameID):", error)
            return []
        }
    }

    static func isCompleted(gameID: String) -> Bool {
        return !getAnswers(gameID: gameID).isEmpty
    }
}

#Preview {
    QuizGameCard(game: quizCategories[0].games[0])
        .padding()
        .background(Color.black)
}
