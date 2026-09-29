//
//  Greeting.swift
//  SoulMates
//
//  Created by Jay on 03/09/26.
//

import SwiftUI

struct Greeting: View {
    @EnvironmentObject private var storage: AppStorageManager

    var body: some View {
        if storage.isLoggedIn {
            MainTabView()
        } else {
            NavigationStack {
                ZStack {
                    // Full-screen background image
                    Image("gr3")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()

                    // Gradient overlay
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.2), location: 0.0),
                            .init(color: .clear, location: 0.35),
                            .init(color: .black.opacity(0.65), location: 0.65),
                            .init(color: .black.opacity(0.95), location: 0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    // Main content
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 20) {
                            // Header pill
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                                Text("A Shared Space For Two")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .tracking(0.6)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.75))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                            )

                            // Title
                            Text("Stay Close With\nYour SoulMate.")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)

                            // Subtitle
                            Text("SoulMate gives you one little reason to talk, laugh, plan, or feel closer every day, wherever you are.")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineSpacing(4)
                                .padding(.horizontal, 24)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.bottom, 60)

                        // Actions
                        VStack(spacing: 14) {
                            // Start onboarding flow
                            NavigationLink {
                                OnboardingFlowContainerView()
                                    .navigationBarBackButtonHidden()
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Create Our Space")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.65, green: 0.22, blue: 0.88),
                                            Color(red: 0.95, green: 0.25, blue: 0.42)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                }
                                .clipShape(Capsule())
                                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 10, y: 8)
                            }
                            .padding(.horizontal, 24)

                            // Direct login link
                            NavigationLink {
                                AuthGateway(startInLogin: true)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("Already have an account?")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.65))

                                    Text("Log in")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.white)
                                        .underline()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

#Preview {
    Greeting()
        .environmentObject(AppStorageManager())
}
