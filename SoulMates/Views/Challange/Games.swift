//
//  Games.swift
//  SoulMates
//
//  Created by Jay on 16/09/26.
//

import SwiftUI

struct Games: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var isAppeared = false
    @State private var glowPulse = false

    private var hasPartner: Bool {
        let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "partner"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                onBoarding_Background()

                if !hasPartner {
                    UnpairedPlaceholderView(
                        title: "Games Require Two",
                        subtitle: "Connect with your partner to play couple mini-games, quizzes, and daily trivia."
                    )
                } else {
                    VStack(spacing: 0) {
                        // MARK: - Header Bar
                        HStack {
                            Text("PLAY TOGETHER")
                                .padding(.bottom, 20)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundStyle(.white)
                                .shadow(
                                    color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(glowPulse ? 0.45 : 0.15),
                                    radius: glowPulse ? 14 : 6,
                                    x: 0,
                                    y: 2
                                )
                            Spacer()
                        }
                        .padding(.top, 10)
                        .opacity(isAppeared ? 1 : 0)
                        .offset(y: isAppeared ? 0 : -14)

                        // MARK: - Categories List
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 32) {
                                ForEach(Array(quizCategories.enumerated()), id: \.element.id) { index, category in
                                    CategorySection(category: category)
                                        .opacity(isAppeared ? 1 : 0)
                                        .offset(y: isAppeared ? 0 : 25)
                                        .animation(
                                            .spring(response: 0.55, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.08),
                                            value: isAppeared
                                        )
                                }
                            }
                            .padding(.top, 24)
                            .padding(.bottom, 40)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onAppear {
                if hasPartner {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isAppeared = true
                    }

                    withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }

                    Task {
                        await SupabaseQuizManager.shared.syncCoupleQuizResponses()
                    }
                }
            }
        }
    }
}

// MARK: - Category Horizontal Scroll Section
struct CategorySection: View {
    let category: QuizCategory

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(category.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Spacer()

                Button { } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(category.games) { game in
                        NavigationLink {
                            QuizView(game: game)
                        } label: {
                            QuizGameCard(game: game)
                        }
                        .buttonStyle(GameCardButtonStyle())
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 2)
            }
        }
    }
}

// MARK: - Game Card Press ButtonStyle
struct GameCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

#Preview {
    Games()
        .environmentObject(AppStorageManager())
}
