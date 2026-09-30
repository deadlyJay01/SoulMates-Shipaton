//
//  ManageProSubscriptionView.swift
//  SoulMates
//

import SwiftUI
// Pro Management Sheet
struct ManageProSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager
    @State private var showAlert = false
    @State private var alertMessage = ""

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.07, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(primaryGradient.opacity(0.18))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(primaryGradient)
                        }

                        Text("SoulMates Pro Member")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(storage.isProPurchaser
                             ? "Your membership unlocks unlimited access for you and your partner."
                             : "Unlocked through \(storage.partnerName)'s active Pro membership.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)

                    // Details Card
                    VStack(spacing: 14) {
                        detailRow(title: "Membership Status", value: "Active", valueColor: .green)
                        Divider().overlay(Color.white.opacity(0.1))
                        detailRow(
                            title: "Plan Type",
                            value: storage.isProPurchaser ? "Couple Annual Pass" : "Shared Partner Pass"
                        )
                        Divider().overlay(Color.white.opacity(0.1))
                        detailRow(
                            title: "Access Source",
                            value: storage.isProPurchaser ? "Primary Subscriber" : "Shared by \(storage.partnerName)",
                            valueColor: Color(red: 0.95, green: 0.25, blue: 0.42)
                        )
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)

                    // Action Buttons
                    VStack(spacing: 12) {
                        if storage.isProPurchaser {
                            Button {
                                alertMessage = "In the official App Store release, this opens Apple's native subscription management sheet."
                                showAlert = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Change Plan")
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Button {
                                alertMessage = "To cancel your plan, go to iPhone Settings > Apple ID > Subscriptions > SoulMates."
                                showAlert = true
                            } label: {
                                Text("Cancel Subscription")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.red.opacity(0.85))
                                    .frame(height: 38)
                            }
                        } else {
                            Text("This membership is billed to \(storage.partnerName). If your couple connection is broken, Pro access will revert.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Manage Membership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .alert("Subscription Management", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func detailRow(title: String, value: String, valueColor: Color = .white) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(valueColor)
        }
    }
}
