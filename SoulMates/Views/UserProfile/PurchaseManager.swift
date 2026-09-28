//
//  PurchaseManager.swift
//  SoulMates
//

import Foundation
import RevenueCat
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    @Published var monthlyPackage: Package?
    @Published var yearlyPackage: Package?
    @Published var isProUnlocked: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // The exact entitlement identifier in your RevenueCat dashboard
    private let entitlementID = "soulmates_pro"

    init() {
        Task {
            await fetchOfferings()
            await refreshSubscriptionStatus()
        }
    }

    func fetchOfferings() async {
        isLoading = true
        do {
            let offerings = try await Purchases.shared.offerings()
            monthlyPackage = offerings.current?.monthly
            yearlyPackage = offerings.current?.annual
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func purchase(package: Package) async -> Bool {
        isLoading = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            let unlocked = result.customerInfo.entitlements[entitlementID]?.isActive == true
            self.isProUnlocked = unlocked

            var expiry: Double = 0.0
            if let expDate = result.customerInfo.entitlements[entitlementID]?.expirationDate {
                expiry = expDate.timeIntervalSince1970
            }

            let plan = package.packageType == .annual ? "Yearly" : "Monthly"
            await AppStorageManager.shared.updateProStatus(isPro: unlocked, expiryTimestamp: expiry, planType: plan)

            isLoading = false
            return unlocked
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func restorePurchases() async -> Bool {
        isLoading = true
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let unlocked = customerInfo.entitlements[entitlementID]?.isActive == true
            self.isProUnlocked = unlocked

            var expiry: Double = 0.0
            if let expDate = customerInfo.entitlements[entitlementID]?.expirationDate {
                expiry = expDate.timeIntervalSince1970
            }

            await AppStorageManager.shared.updateProStatus(isPro: unlocked, expiryTimestamp: expiry)

            isLoading = false
            return unlocked
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func refreshSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let unlocked = customerInfo.entitlements[entitlementID]?.isActive == true
            self.isProUnlocked = unlocked

            var expiry: Double = 0.0
            if let expDate = customerInfo.entitlements[entitlementID]?.expirationDate {
                expiry = expDate.timeIntervalSince1970
            }

            if unlocked != AppStorageManager.shared.isProPurchaser {
                await AppStorageManager.shared.updateProStatus(isPro: unlocked, expiryTimestamp: expiry)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
