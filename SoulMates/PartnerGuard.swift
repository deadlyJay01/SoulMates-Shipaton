//
//  PartnerGuard.swift
//  SoulMates
//

import SwiftUI
import Combine
import Supabase

// Reusable Unpaired Placeholder View
struct UnpairedPlaceholderView: View {
    let title: String
    let subtitle: String
    @State private var showInviteSheet = false

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18),
                                Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 90, height: 90)

                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 38))
                    .foregroundStyle(primaryGradient)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
            }

            Button {
                showInviteSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add Partner")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 26)
                .frame(height: 46)
                .background(Capsule().fill(primaryGradient))
                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 10, y: 3)
            }
            .padding(.top, 6)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showInviteSheet) {
            NavigationStack {
                InvitePartnerView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// Reusable Alert ViewModifier
struct PartnerRequiredAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let featureName: String
    @Binding var showInviteSheet: Bool

    func body(content: Content) -> some View {
        content
            .alert("Partner Required", isPresented: $isPresented) {
                Button("Cancel", role: .cancel) { }
                Button("Add Partner") {
                    showInviteSheet = true
                }
            } message: {
                Text("Pair with your partner to use \(featureName) and start creating shared memories together.")
            }
            .sheet(isPresented: $showInviteSheet) {
                NavigationStack {
                    InvitePartnerView()
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
    }
}

extension View {
    func partnerRequiredAlert(
        isPresented: Binding<Bool>,
        featureName: String,
        showInviteSheet: Binding<Bool>
    ) -> some View {
        self.modifier(PartnerRequiredAlertModifier(
            isPresented: isPresented,
            featureName: featureName,
            showInviteSheet: showInviteSheet
        ))
    }
}
