//
//  canvasDetail.swift
//  SoulMates
//
//  Created by Jay on 18/09/26.
//

import SwiftUI

struct canvasDetail: View {
    @Environment(\.dismiss) private var dismiss

    private let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }

                    Spacer()

                    Text("Couple Canvas")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 20)

                Spacer()

                // Unavailable Feature Card
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 15,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "paintbrush.pointed.fill")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(primaryGradient)
                    }

                    VStack(spacing: 8) {
                        Text("Canvas Coming Soon 🎨")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Draw & Doodle Together in Real Time")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    }

                    // Apology & Explanatory Note
                    VStack(spacing: 12) {
                        Text("This feature is currently under active development and is not available right now.")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)

                        Text("We're fine-tuning the real-time drawing sync engine so you and your partner can sketch seamlessly together. We are truly sorry for the inconvenience and the wait!")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)

                        Text("Please check back in an upcoming update after launch. Thank you for your patience! 💖")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)

                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Home ✨")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Capsule().fill(primaryGradient))
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 10, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    canvasDetail()
}
