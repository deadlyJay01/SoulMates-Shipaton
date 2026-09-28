//
//  QuizView.swift
//  SoulMates
//

import SwiftUI

struct QuizView: View {
    let game: QuizGame
    @ObservedObject private var quizManager = SupabaseQuizManager.shared

    @State private var currentQuestion = 0
    @State private var selectedAnswers: [String?]
    @State private var showAnswers = false
    @State private var isAppeared = false
    @State private var isSubmitting = false
    @State private var isCheckingStatus = true

    private let gradientColors = [
        Color(red: 0.95, green: 0.25, blue: 0.42),
        Color(red: 0.65, green: 0.22, blue: 0.88)
    ]

    init(game: QuizGame) {
        self.game = game
        // Always start with nil/unselected answers so nothing is pre-selected
        _selectedAnswers = State(initialValue: Array(repeating: nil, count: game.questions.count))
        _showAnswers = State(initialValue: false)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            onBoarding_Background()

            if isCheckingStatus {
                ProgressView()
                    .tint(.white)
            } else if showAnswers {
                CompletedQuizView(
                    game: game,
                    myAnswers: quizManager.getMyAnswers(gameID: game.id),
                    partnerAnswers: quizManager.getPartnerAnswers(gameID: game.id)
                )
            } else {
                quizQuestionsView
            }
        }
        .navigationBarBackButtonHidden(false)
        .toolbar(.hidden, for: .tabBar)
        .task {
            isCheckingStatus = true
            // 1. Sync live responses for the CURRENT logged-in user from Supabase
            await quizManager.syncCoupleQuizResponses()
            
            // 2. Check if THIS user already completed the quiz
            let myAns = quizManager.getMyAnswers(gameID: game.id)
            if !myAns.isEmpty {
                // Completed: show answers dashboard
                selectedAnswers = myAns.map { $0.answer }
                showAnswers = true
            } else {
                // Not completed: ensure clean, unselected state
                selectedAnswers = Array(repeating: nil, count: game.questions.count)
                showAnswers = false
            }
            isCheckingStatus = false
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAppeared = true
            }
        }
    }

    // MARK: - Safe Answer Accessors

    private var currentAnswer: String? {
        if selectedAnswers.indices.contains(currentQuestion) {
            return selectedAnswers[currentQuestion]
        }
        return nil
    }

    private func setAnswer(_ answer: String) {
        if selectedAnswers.indices.contains(currentQuestion) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                selectedAnswers[currentQuestion] = answer
            }
        }
    }

    // MARK: - Question View

    private var quizQuestionsView: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 14) {
                Text(game.emoji)
                    .font(.system(size: 34))

                VStack(alignment: .leading, spacing: 3) {
                    Text(game.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Question \(currentQuestion + 1) of \(game.questions.count)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .opacity(isAppeared ? 1 : 0)
            .offset(y: isAppeared ? 0 : -8)

            // Progress Bar
            ProgressView(
                value: Double(currentQuestion + 1),
                total: Double(max(1, game.questions.count))
            )
            .tint(gradientColors[0])
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: currentQuestion)
            .padding(.top, 18)
            .padding(.horizontal, 20)

            // Question Card Container with Smooth Slide
            ZStack {
                if game.questions.indices.contains(currentQuestion) {
                    let currentQ = game.questions[currentQuestion]

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Text(currentQ.question)
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 25)

                            VStack(spacing: 14) {
                                ForEach(Array(currentQ.options.enumerated()), id: \.offset) { index, option in
                                    optionCard(
                                        index: index,
                                        option: option,
                                        isSelected: currentAnswer == option
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .padding(.bottom, 24)
                    }
                    .id(currentQuestion)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
                }
            }
            .clipped()

            // Bottom Continue / Finish Button
            Button {
                nextQuestion()
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(currentQuestion == game.questions.count - 1 ? "Finish Quiz" : "Continue")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background {
                    if currentAnswer != nil {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: gradientColors[0].opacity(0.4), radius: 10, y: 4)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    }
                }
            }
            .disabled(currentAnswer == nil || isSubmitting)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentAnswer != nil)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Option Card

    @ViewBuilder
    private func optionCard(index: Int, option: String, isSelected: Bool) -> some View {
        let optionLetters = ["A", "B", "C", "D", "E", "F"]
        let badgeLabel = index < optionLetters.count ? optionLetters[index] : "\(index + 1)"

        Button {
            setAnswer(option)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                        .frame(width: 50, height: 50)

                    Text(badgeLabel)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                }

                Text(option)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.9)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 26, height: 26)

                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(gradientColors[0])
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(
                color: isSelected ? gradientColors[0].opacity(0.35) : Color.clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(CardPressButtonStyle())
    }

    // MARK: - Logic

    private func nextQuestion() {
        if currentQuestion < game.questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentQuestion += 1
            }
        } else {
            finishQuiz()
        }
    }

    private func finishQuiz() {
        var answers: [SavedQuizAnswer] = []
        for (index, q) in game.questions.enumerated() {
            let userAns = (selectedAnswers.indices.contains(index) ? selectedAnswers[index] : nil) ?? ""
            answers.append(SavedQuizAnswer(question: q.question, answer: userAns))
        }

        isSubmitting = true
        Task {
            do {
                try await quizManager.submitQuiz(gameID: game.id, answers: answers)
                await quizManager.syncCoupleQuizResponses()
            } catch {
                print("Failed to upload quiz to Supabase:", error)
            }

            isSubmitting = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showAnswers = true
            }
        }
    }
}

// MARK: - Card Press Animation

struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Completed Quiz View (Side-by-Side Dual Answers)

struct CompletedQuizView: View {
    let game: QuizGame
    let myAnswers: [SavedQuizAnswer]
    let partnerAnswers: [SavedQuizAnswer]?

    @State private var isLoaded = false

    private let primaryPink = Color(red: 0.95, green: 0.25, blue: 0.42)
    private let partnerPurple = Color(red: 0.65, green: 0.22, blue: 0.88)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("🎉")
                        .font(.system(size: 58))

                    Text("Quiz Completed!")
                        .font(.system(size: 26, weight: .heavy))
                        .foregroundStyle(.white)

                    Text(partnerAnswers != nil ? "Compare your answers together" : "Your answers are saved. Waiting for your partner!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                // Game Title
                HStack(spacing: 12) {
                    Text(game.emoji)
                        .font(.system(size: 30))

                    Text(game.title)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)

                    Spacer()
                }

                // Comparison Cards List
                ForEach(Array(myAnswers.enumerated()), id: \.offset) { index, myAns in
                    let partnerAns = partnerAnswers?.indices.contains(index) == true ? partnerAnswers?[index].answer : nil

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Question \(index + 1)")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundStyle(primaryPink)

                        Text(myAns.question)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)

                        // Dual Partner Answers
                        VStack(spacing: 8) {
                            // My Choice
                            HStack(spacing: 10) {
                                Text("You")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(primaryPink)
                                    .frame(width: 50, alignment: .leading)

                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(primaryPink)

                                Text(myAns.answer)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white)

                                Spacer()
                            }
                            .padding(12)
                            .background(primaryPink.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                            // Partner's Choice
                            HStack(spacing: 10) {
                                Text("Partner")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(partnerPurple)
                                    .frame(width: 50, alignment: .leading)

                                Image(systemName: partnerAns != nil ? "checkmark.circle.fill" : "hourglass")
                                    .foregroundStyle(partnerPurple)

                                Text(partnerAns ?? "Waiting to play...")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(partnerAns != nil ? .white : .white.opacity(0.4))
                                    .italic(partnerAns == nil)

                                Spacer()
                            }
                            .padding(12)
                            .background(partnerPurple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }
                    .opacity(isLoaded ? 1.0 : 0.0)
                    .offset(y: isLoaded ? 0 : 20)
                    .animation(
                        .spring(response: 0.45, dampingFraction: 0.8)
                        .delay(Double(index) * 0.06),
                        value: isLoaded
                    )
                }

                Text("You can return anytime to check your answers.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .onAppear {
            isLoaded = true
        }
    }
}


#Preview("Taking Quiz - Fresh State") {
    NavigationStack {
        QuizView(game: quizCategories[0].games[0])
            .environmentObject(AppStorageManager.shared)
    }
}

#Preview("Completed Dashboard - Side by Side") {
    ZStack {
        Color.black.ignoresSafeArea()
        onBoarding_Background()

        CompletedQuizView(
            game: quizCategories[0].games[0],
            myAnswers: [
                SavedQuizAnswer(question: "What do you think I enjoy doing most on a lazy day?", answer: "Watching movies or shows"),
                SavedQuizAnswer(question: "What surprise would make me happiest?", answer: "Romantic date"),
                SavedQuizAnswer(question: "What would I pick for a perfect Sunday?", answer: "Stay home together"),
                SavedQuizAnswer(question: "When I have a rough day, what do I need most?", answer: "A long hug"),
                SavedQuizAnswer(question: "Which small thing matters most to me?", answer: "Quality uninterrupted time")
            ],
            partnerAnswers: [
                SavedQuizAnswer(question: "What do you think I enjoy doing most on a lazy day?", answer: "Gaming all day"),
                SavedQuizAnswer(question: "What surprise would make me happiest?", answer: "Quiet night in"),
                SavedQuizAnswer(question: "What would I pick for a perfect Sunday?", answer: "Try something new"),
                SavedQuizAnswer(question: "When I have a rough day, what do I need most?", answer: "A listening ear"),
                SavedQuizAnswer(question: "Which small thing matters most to me?", answer: "Sweet random texts")
            ]
        )
    }
}
