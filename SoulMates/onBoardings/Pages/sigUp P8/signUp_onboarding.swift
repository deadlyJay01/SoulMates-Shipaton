//
//  signUp_onboarding.swift
//  SoulMates
//

import SwiftUI

struct signUp_onboarding: View {
    @EnvironmentObject private var storage: AppStorageManager

    @State private var animateContent: Bool = false
    @State private var animateBackground: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { proxy in
                Image("back1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .scaleEffect(animateBackground ? 1.08 : 1.0)
                    .offset(y: animateBackground ? -12 : 12)
                    .animation(
                        .easeInOut(duration: 8.0)
                        .repeatForever(autoreverses: true),
                        value: animateBackground
                    )
            }
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.15), location: 0.35),
                    .init(color: .black.opacity(0.65), location: 0.60),
                    .init(color: .black.opacity(0.92), location: 0.88),
                    .init(color: .black, location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    Text("Your Space Is\nAlmost Ready")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10, y: 4)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)

                    Text("Sign up to save your progress and keep your memories safe.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(3)
                        .padding(.horizontal, 36)
                        .fixedSize(horizontal: false, vertical: true)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12), value: animateContent)
                }
                .padding(.bottom, 32)

                VStack(spacing: 14) {
                    AuthOptionButton(
                        title: "Sign up with Apple",
                        systemIcon: "apple.logo"
                    ) {
                        // Handled in Phase 1 Auth polish
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.22), value: animateContent)

                    AuthOptionButton(
                        title: "Sign up with Google",
                        customImage: "Google_Logo"
                    ) {
                        // Handled in Phase 1 Auth polish
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.32), value: animateContent)

                    NavigationLink {
                        Number_SignUp()
                    } label: {
                        AuthButtonContent(
                            title: "Sign up with Phone",
                            systemIcon: "phone.fill"
                        )
                    }
                    .buttonStyle(.plain)
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.42), value: animateContent)
                }
                .padding(.horizontal, 28)

                NavigationLink {
                    LogIn_onboarding()
                } label: {
                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .foregroundStyle(.white.opacity(0.65))

                        Text("Log in")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                            .underline()
                    }
                    .font(.footnote)
                    .padding(.top, 26)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
                .offset(y: animateContent ? 0 : 15)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.52), value: animateContent)
            }
        }
        .onAppear {
            animateContent = true
            animateBackground = true
        }
    }
}

#Preview {
    signUp_onboarding()
        .environmentObject(AppStorageManager())
}
