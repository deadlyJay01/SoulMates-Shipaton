//
//  detailProView.swift
//  SoulMates
//

import SwiftUI
import RevenueCat

enum ProPlanType: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthly: return "₹499"
        case .yearly: return "₹2,999"
        }
    }

    var periodSubtitle: String {
        switch self {
        case .monthly: return "per month"
        case .yearly: return "15d free, then ₹249/mo"
        }
    }

    var badgeText: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "RECOMMENDED"
        }
    }

    // How long this plan's subscription lasts, used to calculate the expiry date we save to Supabase
    var durationInDays: Int {
        switch self {
        case .monthly: return 30
        case .yearly: return 365
        }
    }

    // The friendly name shown on the Manage Membership screen
    var displayPlanName: String {
        switch self {
        case .monthly: return "Monthly Pass"
        case .yearly: return "Annual Couple Pass"
        }
    }
}

struct detailProView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var purchaseManager = PurchaseManager()
    @State private var selectedPlan: ProPlanType = .yearly
    @State private var isPulsing: Bool = false
    @State private var showErrorAlert: Bool = false

    // Modal Sheets
    @State private var showRestoreSheet: Bool = false
    @State private var showTermsSheet: Bool = false
    @State private var showPrivacySheet: Bool = false

    private let primaryGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Picks the matching RevenueCat Package for whichever plan card is selected
    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly: return purchaseManager.monthlyPackage
        case .yearly: return purchaseManager.yearlyPackage
        }
    }

    // Falls back to your old hardcoded price only if RevenueCat hasn't loaded yet
    private func displayPrice(for plan: ProPlanType) -> String {
        let package = plan == .monthly ? purchaseManager.monthlyPackage : purchaseManager.yearlyPackage
        return package?.storeProduct.localizedPriceString ?? plan.price
    }

    // Decides what the trust pill says. Reads from `storage` (Supabase) so this
    // always agrees with what UserProfile's card shows.
    private var trialPillText: String {
        if storage.isProUser {
            return "\(storage.proDaysRemaining) Day\(storage.proDaysRemaining == 1 ? "" : "s") Left"
        } else if storage.isFreeTrialActive {
            return "\(storage.freeTrialDaysRemaining) Day\(storage.freeTrialDaysRemaining == 1 ? "" : "s") Free Trial Left"
        } else {
            return "15 Days Free Trial"
        }
    }

    // Saves the successful purchase to Supabase via AppStorageManager
    private func syncPurchaseToSupabase(plan: ProPlanType) async {
        let expiry = Date().addingTimeInterval(Double(plan.durationInDays) * 86400).timeIntervalSince1970
        await storage.updateProStatus(isPro: true, expiryTimestamp: expiry, planType: plan.displayPlanName)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()
                .ignoresSafeArea()

            // Single-Screen Container (No ScrollView)
            VStack(spacing: 0) {
                Spacer(minLength: 4)

                // 1. Hero Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), Color.clear],
                                    center: .center,
                                    startRadius: 8,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 86, height: 86)
                            .scaleEffect(isPulsing ? 1.15 : 0.95)

                        Circle()
                            .fill(primaryGradient)
                            .frame(width: 54, height: 54)
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.5), radius: 14, y: 5)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                    }

                    Text("SoulMates Pro")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Unlimited sync, shared memory vaults & exclusive couple features.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                Spacer(minLength: 10)

                // 2. Feature Highlights (Couple Quiz Games & Date Tracker)
                VStack(spacing: 11) {
                    featureRow(icon: "music.note.list", title: "Realtime Music Sync", subtitle: "Listen together with no session limits")
                    featureRow(icon: "photo.stack.fill", title: "Unlimited 4K Memories", subtitle: "High-res couple albums & notes")
                    featureRow(icon: "heart.text.square.fill", title: "Couple Quiz Games", subtitle: "Unlock all intimacy questions & couple quizzes")
                    featureRow(icon: "calendar.badge.clock", title: "Couple Date Tracker", subtitle: "Never miss anniversaries & special dates")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )

                Spacer(minLength: 12)

                // 3. Plan Selection Cards (Monthly vs Yearly with RECOMMENDED badge)
                HStack(spacing: 12) {
                    ForEach(ProPlanType.allCases) { plan in
                        planCardButton(for: plan)
                    }
                }

                Spacer(minLength: 10)

                // 4. Trial & Cancellation Trust Pill
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                    Text(trialPillText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("•")
                        .foregroundStyle(.white.opacity(0.4))

                    Text("Cancel anytime")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.vertical, 6)

                // 5. Continue with Price CTA
                Button {
                    guard let package = selectedPackage else { return }
                    Task {
                        let unlocked = await purchaseManager.purchase(package: package)
                        if unlocked {
                            await syncPurchaseToSupabase(plan: selectedPlan)
                            dismiss()
                        } else if purchaseManager.errorMessage != nil {
                            showErrorAlert = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if purchaseManager.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Continue with \(displayPrice(for: selectedPlan))")
                                .font(.system(size: 16, weight: .heavy, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 10, y: 4)
                }
                .disabled(purchaseManager.isLoading || selectedPackage == nil)

                // 6. "Not now" Dismiss Button
                Button {
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.vertical, 8)
                }

                // 7. Restore Purchase • Terms & Conditions • Privacy Policy
                HStack(spacing: 8) {
                    Button {
                        Task {
                            let restored = await purchaseManager.restorePurchases()
                            if restored {
                                // Test Store restores don't tell us exactly which plan was
                                // active, so we default to a 1-year expiry as a safe fallback.
                                await syncPurchaseToSupabase(plan: .yearly)
                                dismiss()
                            } else {
                                showRestoreSheet = true
                            }
                        }
                    } label: {
                        Text("Restore Purchase")
                            .underline()
                    }

                    Text("•")

                    Button {
                        showTermsSheet = true
                    } label: {
                        Text("Terms & Conditions")
                            .underline()
                    }

                    Text("•")

                    Button {
                        showPrivacySheet = true
                    } label: {
                        Text("Privacy Policy")
                            .underline()
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 6)
            }
            .padding(.horizontal, 20)
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        // Informational Sheets
        .sheet(isPresented: $showRestoreSheet) {
            LegalDocView(
                title: "Restore Purchases",
                content: "In-App Purchases and subscription restoration are currently unavailable in this build.\n\nAll subscriptions and purchase restorations will be automatically enabled in our upcoming official App Store release. Thank you for your patience and support!"
            )
        }
        .sheet(isPresented: $showTermsSheet) {
            LegalDocView(
                title: "Terms & Conditions",
                content: "Your 15-day free trial will begin upon subscription confirmation. You may cancel at any time in your Apple Account settings before the trial ends without being charged. If not canceled, subscription will automatically renew according to the chosen plan."
            )
        }
        .sheet(isPresented: $showPrivacySheet) {
            LegalDocView(
                title: "Privacy Policy",
                content: "SoulMates respects your intimacy and couple privacy. All shared media, photos, audio sessions, and notes are end-to-end encrypted and never sold to third parties. We do not track personal identifying information across external platforms."
            )
        }
        .alert("Something went wrong", isPresented: $showErrorAlert, presenting: purchaseManager.errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    // Compact Feature Row
    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(primaryGradient.opacity(0.18))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.green)
        }
    }

    // Plan Card (split out of body so Swift can type-check it quickly)
    @ViewBuilder
    private func planCardButton(for plan: ProPlanType) -> some View {
        let isSelected = selectedPlan == plan

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedPlan = plan
            }
        } label: {
            planCardLabel(for: plan, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func planCardLabel(for plan: ProPlanType, isSelected: Bool) -> some View {
        VStack(spacing: 5) {
            if let badge = plan.badgeText {
                Text(badge)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(primaryGradient, in: Capsule())
                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 4)
            } else {
                Text("MONTHLY")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.vertical, 3)
            }

            Text(plan.title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(displayPrice(for: plan))
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(isSelected ? Color(red: 0.95, green: 0.25, blue: 0.42) : .white)

            Text(plan.periodSubtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(planCardBackground(isSelected: isSelected))
        .overlay(planCardBorder(isSelected: isSelected))
    }

    private func planCardBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(isSelected ? Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.14) : Color.white.opacity(0.04))
    }

    private func planCardBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(
                isSelected ? AnyShapeStyle(primaryGradient) : AnyShapeStyle(Color.white.opacity(0.12)),
                lineWidth: isSelected ? 2 : 1
            )
    }
}

// Simple Legal / Info Sheet
private struct LegalDocView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    Text(content)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(6)
                        .padding(24)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }
}
