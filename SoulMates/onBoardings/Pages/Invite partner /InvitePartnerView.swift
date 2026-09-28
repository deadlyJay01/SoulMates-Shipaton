//
//  InvitePartnerView.swift
//  SoulMates
//

import SwiftUI
import Combine
import Supabase

struct InvitePartnerView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel = InvitePartnerViewModel()
    @Environment(\.dismiss) private var dismiss

    var onFinished: (() -> Void)? = nil

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
            Color.black
                .ignoresSafeArea()

            onBoarding_Background()

            VStack(spacing: 28) {
                // Header
                VStack(spacing: 8) {
                    Text("Connect with Partner")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Share your invite code or enter your partner's code to pair your accounts.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 40)

                // User's Generated Code
                VStack(spacing: 12) {
                    Text("YOUR INVITATION CODE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.5)

                    HStack {
                        if viewModel.isLoadingCode {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(viewModel.myInviteCode)
                                .font(.system(size: 32, weight: .black, design: .monospaced))
                                .foregroundStyle(.white)
                                .tracking(4)
                        }

                        Spacer()

                        Button {
                            viewModel.copyCodeToClipboard()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                                Text(viewModel.copied ? "Copied" : "Copy")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                        }
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(primaryGradient, lineWidth: 1.5)
                            )
                    }
                }
                .padding(.horizontal, 24)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                    Text("OR")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 8)
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                }
                .padding(.horizontal, 30)

                // Enter Partner's Code
                VStack(spacing: 16) {
                    Text("ENTER PARTNER'S CODE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .tracking(1.5)

                    TextField("6-DIGIT CODE", text: $viewModel.partnerCodeInput)
                        .font(.system(size: 22, weight: .heavy, design: .monospaced))
                        .submitLabel(.done)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.vertical, 16)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task {
                            await viewModel.linkPartner(storage: storage)
                        }
                    } label: {
                        HStack {
                            if viewModel.isConnecting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Link as SoulMates")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 14))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Capsule().fill(
                                viewModel.canSubmit
                                ? primaryGradient
                                : LinearGradient(colors: [Color.white.opacity(0.15)], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 10, y: 4)
                    }
                    .disabled(!viewModel.canSubmit)
                }
                .padding(.horizontal, 24)

                Spacer()

                // Skip Action
                Button {
                    onFinished?()
                    dismiss()
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 24)
            }
        }
        .onChange(of: viewModel.isConnected) { _, connected in
            if connected {
                onFinished?()
                dismiss()
            }
        }
        .task {
            await viewModel.loadOrCreateMyCode(storage: storage)
        }
        .onDisappear {
            viewModel.cleanupChannel()
        }
    }
}

#Preview {
    InvitePartnerView()
        .environmentObject(AppStorageManager())
}
