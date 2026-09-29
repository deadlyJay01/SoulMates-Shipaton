//
//  Number_LogIn.swift
//  SoulMates
//

import SwiftUI

struct Number_LogIn: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager
    let initialPhone: String
    var onSwitchToSignUp: () -> Void = {}

    @State private var phone: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?

    @State private var animateContent: Bool = false
    @State private var animateBackground: Bool = false

    @State private var showLoginError = false
    @State private var isSubmitting = false
    @State private var loginErrorMessage = "Incorrect phone number or password."

    enum Field {
        case phone, password
    }

    init(initialPhone: String = "", onSwitchToSignUp: @escaping () -> Void = {}) {
        self.initialPhone = initialPhone
        self.onSwitchToSignUp = onSwitchToSignUp
    }

    private var isFormInvalid: Bool {
        phone.count != 10 ||
        password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                    .init(color: .black.opacity(0.4), location: 0.38),
                    .init(color: .black.opacity(0.85), location: 0.68),
                    .init(color: .black, location: 0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Custom Back Button — pops back to whatever screen (Greeting or Onboarding) pushed AuthGateway
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                VStack(spacing: 8) {
                    Text("Log In with Phone")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 4)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)

                    Text("Welcome back! Enter your phone to access your space.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.6), radius: 6, y: 2)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.12), value: animateContent)
                }
                .padding(.bottom, 26)

                VStack(spacing: 14) {
                    CustomInputField(
                        icon: "phone.fill",
                        placeholder: "10-digit Mobile Number",
                        text: $phone,
                        keyboardType: .phonePad,
                        isFocused: focusedField == .phone
                    )
                    .focused($focusedField, equals: .phone)
                    .onChange(of: phone) { _, newValue in
                        phone = String(newValue.filter(\.isNumber).prefix(10))
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.20), value: animateContent)

                    CustomInputField(
                        icon: "lock.fill",
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        isFocused: focusedField == .password
                    )
                    .focused($focusedField, equals: .password)
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.28), value: animateContent)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                ButtonRP(Textt: isSubmitting ? "Logging In..." : "Log In", action: logIn)
                    .disabled(isFormInvalid || isSubmitting)
                    .opacity(isFormInvalid || isSubmitting ? 0.4 : 1.0)
                    .scaleEffect(isFormInvalid || isSubmitting ? 0.96 : 1.0)
                    .shadow(
                        color: isFormInvalid ? .clear : Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.6),
                        radius: isFormInvalid ? 0 : 18,
                        x: 0,
                        y: 8
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFormInvalid)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? (isFormInvalid ? 0.4 : 1.0) : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.36), value: animateContent)
                    .alert("Login Failed", isPresented: $showLoginError) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text(loginErrorMessage)
                    }

                // Switch to Sign Up — now swaps content in place instead of dismissing
                Button {
                    onSwitchToSignUp()
                } label: {
                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .foregroundStyle(.white.opacity(0.7))

                        Text("Sign in with phone number")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                            .underline()
                    }
                    .font(.footnote)
                    .padding(.top, 22)
                    .padding(.bottom, 24)
                }
                .buttonStyle(.plain)
                .offset(y: animateContent ? 0 : 15)
                .opacity(animateContent ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.44), value: animateContent)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            animateContent = true
            animateBackground = true
            if phone.isEmpty {
                phone = initialPhone
            }
            storage.profileImageData = Data()
            storage.hasProfileImage = false
        }
    }

    private func logIn() {
        isSubmitting = true
        Task {
            do {
                try await SupabaseService.shared.signInAndLoadProfile(phone: phone, password: password, storage: storage)
                await MainActor.run {
                    storage.authProvider = 3
                    storage.localPassword = ""
                    storage.isLoggedIn = true
                }
                await storage.syncCoupleRelationshipData()
                await storage.fetchSubscriptionAndTrialStatus()
                storage.syncAllWidgetData()
            } catch {
                await MainActor.run {
                    loginErrorMessage = error.localizedDescription
                    showLoginError = true
                }
            }
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
} 
