//
//  Challange-Home.swift
//  SoulMates
//
//  Created by Jay on 08/09/26.
//

import SwiftUI

struct Challange_Home: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel = DailyQuestionViewModel()
    @State private var navigate = false
    
    // Partner Alert States
    @State private var showPartnerAlert = false
    @State private var showInviteSheet = false

    // Animation States
    @State private var isAppeared = false
    @State private var heartFloating = false
    @State private var glowPulsing = false

    private var hasPartner: Bool {
        let name = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.lowercased() != "partner"
    }

    private let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // MARK: - Section Title & Streak Header
            HStack(alignment: .center) {
                Text("Daily Question")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                streak(StreakCount: viewModel.currentStreak)
            }
            .padding(.horizontal, 20)
            
            // MARK: - Challenge Card
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.96),
                                Color(red: 1.0, green: 0.90, blue: 0.94).opacity(0.93),
                                Color(red: 1.0, green: 0.94, blue: 0.90).opacity(0.90)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.25, blue: 0.42).opacity(glowPulsing ? 0.6 : 0.3),
                                        Color(red: 0.65, green: 0.22, blue: 0.88).opacity(glowPulsing ? 0.35 : 0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.4
                            )
                    }
                
                Image("Love-heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(heartFloating ? 16 : 8))
                    .scaleEffect(heartFloating ? 1.05 : 0.96)
                    .offset(x: -12, y: heartFloating ? 12 : 20)
                    .shadow(
                        color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(heartFloating ? 0.45 : 0.25),
                        radius: heartFloating ? 18 : 12,
                        x: 4,
                        y: 6
                    )
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        
                        Text(statusText)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.black2.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black2.opacity(0.08), in: Capsule())
                    
                    Text(viewModel.todaysQuestion.question)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(red: 0.12, green: 0.08, blue: 0.14))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 220, alignment: .leading)
                    
                    Spacer(minLength: 16)
                    
                    HStack(alignment: .center) {
                        CoupleImage_Home(avatarSize: 46)
                        
                        Spacer()
                        
                        // Play / View Button Guarded by Partner Check
                        Button {
                            if hasPartner {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    navigate = true
                                }
                            } else {
                                showPartnerAlert = true
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: buttonIcon)
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text(buttonTitle)
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(primaryGradient))
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 10, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 190)
            .padding(.horizontal, 20)
            .shadow(color: Color.purple1.opacity(0.35), radius: 16, y: 8)
        }
        .partnerRequiredAlert(
            isPresented: $showPartnerAlert,
            featureName: "Daily Questions",
            showInviteSheet: $showInviteSheet
        )
        .navigationDestination(isPresented: $navigate) {
            DailyQuestionView()
                .onDisappear {
                    Task {
                        await viewModel.loadDailyData()
                    }
                }
        }
        .task {
            if hasPartner {
                await viewModel.loadDailyData()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                isAppeared = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                heartFloating = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulsing = true
            }
        }
    }

    private var statusIcon: String {
        guard hasPartner else { return "person.crop.circle.badge.plus" }
        if viewModel.bothAnswered {
            return "checkmark.circle.fill"
        } else if viewModel.myAnswer != nil {
            return "hourglass"
        } else {
            return "sparkles"
        }
    }

    private var statusText: String {
        guard hasPartner else { return "Connect partner to play" }
        let partner = storage.partnerName.isEmpty ? "Partner" : storage.partnerName
        if viewModel.bothAnswered {
            return "Both answered! Answers revealed"
        } else if viewModel.myAnswer != nil {
            return "Waiting for \(partner)"
        } else {
            return "Today's question is ready"
        }
    }

    private var buttonTitle: String {
        guard hasPartner else { return "Connect" }
        if viewModel.bothAnswered {
            return "View"
        } else if viewModel.myAnswer != nil {
            return "Waiting"
        } else {
            return "Play"
        }
    }

    private var buttonIcon: String {
        guard hasPartner else { return "link" }
        if viewModel.bothAnswered {
            return "eye.fill"
        } else if viewModel.myAnswer != nil {
            return "lock.fill"
        } else {
            return "play.fill"
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        Challange_Home()
            .environmentObject(AppStorageManager())
    }
}
