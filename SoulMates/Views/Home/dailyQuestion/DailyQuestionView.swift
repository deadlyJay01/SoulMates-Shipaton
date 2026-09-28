//
//  DailyQuestionView.swift
//  SoulMates
//

import SwiftUI

struct DailyQuestionView: View {
    @StateObject private var viewModel = DailyQuestionViewModel()
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss

    // Local selected option before user hits "Submit"
    @State private var draftSelection: String? = nil

    private let gradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Text("🔥")
                        Text("\(viewModel.currentStreak) Day Streak")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Question Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("TODAY'S QUESTION")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                                Text(viewModel.todaysQuestion.question)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(22)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 20)

                            // Options List
                            VStack(spacing: 12) {
                                ForEach(viewModel.todaysQuestion.options, id: \.self) { option in
                                    let isChosen = (viewModel.myAnswer ?? draftSelection) == option

                                    OptionRow(
                                        optionText: option,
                                        isMySelected: isChosen,
                                        isPartnerSelected: viewModel.partnerAnswer == option,
                                        showPartner: viewModel.bothAnswered,
                                        partnerName: storage.partnerName.isEmpty ? "Partner" : storage.partnerName,
                                        gradient: gradient
                                    ) {
                                        // Allow toggling between choices only if not submitted yet
                                        if viewModel.myAnswer == nil {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                draftSelection = option
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Submit Confirmation Button (Only visible when pending submission)
                            if viewModel.myAnswer == nil {
                                Button {
                                    if let selection = draftSelection {
                                        Task {
                                            await viewModel.submitAnswer(selection)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        if viewModel.isSubmitting {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Submit Answer")
                                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        Capsule().fill(
                                            draftSelection != nil
                                            ? gradient
                                            : LinearGradient(colors: [Color.white.opacity(0.12)], startPoint: .leading, endPoint: .trailing)
                                        )
                                    )
                                    .shadow(
                                        color: draftSelection != nil ? Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35) : .clear,
                                        radius: 10,
                                        y: 4
                                    )
                                }
                                .disabled(draftSelection == nil || viewModel.isSubmitting)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            }

                            // Status Banners
                            if viewModel.myAnswer != nil && !viewModel.bothAnswered {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.yellow)

                                    let partner = storage.partnerName.isEmpty ? "Partner" : storage.partnerName
                                    Text("Waiting for \(partner) to answer to reveal results!")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            } else if viewModel.bothAnswered {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.pink)
                                    Text("Both completed today! Answers revealed. 🔥")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.pink.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadDailyData()
            if let existing = viewModel.myAnswer {
                draftSelection = existing
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - Option Row Component
struct OptionRow: View {
    let optionText: String
    let isMySelected: Bool
    let isPartnerSelected: Bool
    let showPartner: Bool
    let partnerName: String
    let gradient: LinearGradient
    let action: () -> Void

    private var bothChoseThis: Bool {
        showPartner && isMySelected && isPartnerSelected
    }

    private var onlyPartnerChoseThis: Bool {
        showPartner && !isMySelected && isPartnerSelected
    }

    private var onlyIChoseThis: Bool {
        showPartner && isMySelected && !isPartnerSelected
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text(optionText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    if isMySelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    } else if onlyPartnerChoseThis {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                    }
                }

                // MARK: - Result Badges (When Revealed)
                if showPartner {
                    if bothChoseThis {
                        // 1. Both chose the same!
                        HStack(spacing: 6) {
                            Text("🎉")
                                .font(.system(size: 12))
                            Text("Yay! You both chose this")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.35))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    } else if onlyIChoseThis {
                        // 2. You chose this
                        HStack(spacing: 5) {
                            Text("👤")
                                .font(.system(size: 11))
                            Text("You chose this")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                    } else if onlyPartnerChoseThis {
                        // 3. Partner chose this
                        HStack(spacing: 5) {
                            Text("❤️")
                                .font(.system(size: 11))
                            Text("\(partnerName) chose this")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 1.0, green: 0.5, blue: 0.7))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isMySelected
                        ? AnyShapeStyle(gradient)
                        : (onlyPartnerChoseThis
                            ? AnyShapeStyle(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.14))
                            : AnyShapeStyle(Color.white.opacity(0.06)))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isMySelected
                                ? Color.white.opacity(0.4)
                                : (onlyPartnerChoseThis
                                    ? Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.7)
                                    : Color.white.opacity(0.12)),
                                lineWidth: (isMySelected || onlyPartnerChoseThis) ? 1.8 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}


#Preview("Both Chose Same (Match)") {
    DailyQuestionPreviewContainer(state: .bothMatched)
        .preferredColorScheme(.dark)
}

#Preview("Different Choices (Mismatch)") {
    DailyQuestionPreviewContainer(state: .differentChoices)
        .preferredColorScheme(.dark)
}

#Preview("Waiting for Partner") {
    DailyQuestionPreviewContainer(state: .waitingForPartner)
        .preferredColorScheme(.dark)
}

private enum PreviewDailyState {
    case unanswered
    case waitingForPartner
    case bothMatched
    case differentChoices
}

private struct DailyQuestionPreviewContainer: View {
    let state: PreviewDailyState
    @State private var draftSelection: String? = nil

    private let sampleQuestion = DailyQuestion(
        id: 4,
        question: "What was your very first impression of me?",
        options: [
            "Instantly charming and warm",
            "Mysterious and hard to read",
            "Hilarious and full of energy",
            "Polite, quiet, and sweet"
        ]
    )

    private let gradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())

                    Spacer()

                    HStack(spacing: 6) {
                        Text("🔥")
                        Text("11 Day Streak")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TODAY'S QUESTION")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                            Text(sampleQuestion.question)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)

                        VStack(spacing: 12) {
                            ForEach(sampleQuestion.options, id: \.self) { option in
                                let isMySelected: Bool = {
                                    switch state {
                                    case .unanswered: return draftSelection == option
                                    case .waitingForPartner, .bothMatched, .differentChoices:
                                        return option == sampleQuestion.options[0]
                                    }
                                }()

                                let isPartnerSelected: Bool = {
                                    switch state {
                                    case .unanswered, .waitingForPartner: return false
                                    case .bothMatched: return option == sampleQuestion.options[0]
                                    case .differentChoices: return option == sampleQuestion.options[1]
                                    }
                                }()

                                let isRevealed = (state == .bothMatched || state == .differentChoices)

                                OptionRow(
                                    optionText: option,
                                    isMySelected: isMySelected,
                                    isPartnerSelected: isPartnerSelected,
                                    showPartner: isRevealed,
                                    partnerName: "Tirth",
                                    gradient: gradient
                                ) { }
                            }
                        }
                        .padding(.horizontal, 20)

                        if state == .bothMatched {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.pink)
                                Text("It's a match! Both answered the same! 🎉")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.pink.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.pink.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
