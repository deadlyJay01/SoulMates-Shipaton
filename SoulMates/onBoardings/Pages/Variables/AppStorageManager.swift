//
//  AppStorageManager.swift
//  SoulMates
//

import SwiftUI
import Combine
import Supabase
import WidgetKit

final class AppStorageManager: ObservableObject {
    static let shared = AppStorageManager()

    // MARK: - User Profile
    @AppStorage("userName") var userName: String = "" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("userGender") var userGender: Int = 0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("userPhone") var userPhone: String = "" {
        didSet { objectWillChange.send() }
    }

    // MARK: - Partner Profile
    @AppStorage("partnerName") var partnerName: String = "" {
        didSet {
            objectWillChange.send()
            recalculateProAccess()
            syncAllWidgetData()
        }
    }
    @AppStorage("partnerHasProfileImage") var partnerHasProfileImage: Bool = false {
        didSet { objectWillChange.send() }
    }
    @AppStorage("partnerProfileImageData") var partnerProfileImageData: Data = Data() {
        didSet {
            objectWillChange.send()
            if let image = UIImage(data: partnerProfileImageData) {
                WidgetSharedData.saveImage(image, fileName: WidgetSharedData.partnerAvatarFile)
            }
        }
    }

    var hasConnectedPartner: Bool {
        let name = partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return isLoggedIn && !name.isEmpty && name.lowercased() != "partner"
    }

    // MARK: - Relationship Details
    // 0: None, 1: Close, 2: Long-Distance
    @AppStorage("relationshipType") var relationshipType: Int = 0 {
        didSet {
            objectWillChange.send()
            syncAllWidgetData()
        }
    }
    
    @AppStorage("anniversaryDateTimestamp") var anniversaryDateTimestamp: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("totalDaysTogether") var totalDaysTogether: Int = 0 {
        didSet {
            objectWillChange.send()
            syncAllWidgetData()
        }
    }

    // MARK: - Profile Media
    @AppStorage("profileImageData") var profileImageData: Data = Data() {
        didSet {
            objectWillChange.send()
            if let image = UIImage(data: profileImageData) {
                WidgetSharedData.saveImage(image, fileName: WidgetSharedData.myAvatarFile)
            }
        }
    }
    @AppStorage("hasProfileImage") var hasProfileImage: Bool = false {
        didSet { objectWillChange.send() }
    }

    // MARK: - Authentication & Session
    @AppStorage("authProvider") var authProvider: Int = 0 {
        didSet { objectWillChange.send() }
    }
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false {
        didSet {
            objectWillChange.send()
            syncAllWidgetData()
        }
    }
    @AppStorage("localPassword") var localPassword: String = ""
    
    // MARK: - Distance Tracking
    @AppStorage("isLiveDistanceEnabled") var isLiveDistanceEnabled: Bool = false {
        didSet {
            objectWillChange.send()
            syncAllWidgetData()
        }
    }
    @AppStorage("userState") var userState: String = ""
    @AppStorage("userCity") var userCity: String = "" {
        didSet { syncAllWidgetData() }
    }
    @AppStorage("partnerState") var partnerState: String = ""
    @AppStorage("partnerCity") var partnerCity: String = "" {
        didSet { syncAllWidgetData() }
    }
    @AppStorage("calculatedDistanceKm") var calculatedDistanceKm: Int = 0 {
        didSet {
            objectWillChange.send()
            syncAllWidgetData()
        }
    }

    private var coupleChannel: RealtimeChannelV2?
    private var isSubscribedToCouple: Bool = false
    
    // MARK: - Pro & Trial Subscription State
    // True if THIS user physically made the purchase via RevenueCat
    @AppStorage("isProPurchaser") var isProPurchaser: Bool = false {
        didSet {
            objectWillChange.send()
            recalculateProAccess()
        }
    }

    // True if the connected couple relationship has active Pro sharing
    @AppStorage("isCouplePro") var isCouplePro: Bool = false {
        didSet {
            objectWillChange.send()
            recalculateProAccess()
        }
    }

    // Overall Pro state: active if I bought it OR if my partner shared it
    @AppStorage("isProUser") var isProUser: Bool = false {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("proExpiryTimestamp") var proExpiryTimestamp: Double = 0.0 {
        didSet { objectWillChange.send() }
    }

    @AppStorage("trialStartTimestamp") var trialStartTimestamp: Double = 0.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("proPlanType") var proPlanType: String = "" {
        didSet { objectWillChange.send() }
    }

    func recalculateProAccess() {
        let active = isProPurchaser || (hasConnectedPartner && isCouplePro)
        if self.isProUser != active {
            self.isProUser = active
        }
    }

    var proDaysRemaining: Int {
        guard isProUser, proExpiryTimestamp > 0 else { return 0 }
        let expiryDate = Date(timeIntervalSince1970: proExpiryTimestamp)
        let diff = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: expiryDate))
        return max(0, diff.day ?? 0)
    }

    var freeTrialDaysRemaining: Int {
        guard trialStartTimestamp > 0 else { return 15 }
        let startDate = Date(timeIntervalSince1970: trialStartTimestamp)
        let elapsed = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: startDate), to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return max(0, 15 - elapsed)
    }

    var isFreeTrialActive: Bool {
        !isProUser && freeTrialDaysRemaining > 0
    }

    private struct ProUpdatePayload: Encodable {
        let is_pro_user: Bool
        let pro_expiry_timestamp: Double
        let plan_type: String
    }

    private struct TrialUpdatePayload: Encodable {
        let trial_start_timestamp: Double
    }

    // Syncs paid Pro status with Supabase profiles and couples tables
    @MainActor
    func updateProStatus(isPro: Bool, expiryTimestamp: Double, planType: String = "") async {
        self.isProPurchaser = isPro
        self.proExpiryTimestamp = expiryTimestamp
        if !planType.isEmpty {
            self.proPlanType = planType
        }
        recalculateProAccess()

        guard let myUID = SupabaseService.shared.client.auth.currentUser?.id else { return }

        do {
            let payload = ProUpdatePayload(is_pro_user: isPro, pro_expiry_timestamp: expiryTimestamp, plan_type: self.proPlanType)
            try await SupabaseService.shared.client
                .from("profiles")
                .update(payload)
                .eq("id", value: myUID.uuidString)
                .execute()

            // If user is currently in a couple, update the couple row too
            if let coupleId = await SupabaseService.shared.fetchCoupleId() {
                try? await SupabaseService.shared.client
                    .from("couples")
                    .update(["is_couple_pro": isPro])
                    .eq("id", value: coupleId.uuidString)
                    .execute()
                self.isCouplePro = isPro
            }
            print("✅ [Supabase] Pro status updated: is_pro_user = \(isPro)")
        } catch {
            print("🚨 Failed to update Pro status:", error)
        }
    }

    @MainActor
    func fetchSubscriptionAndTrialStatus() async {
        guard let myUID = SupabaseService.shared.client.auth.currentUser?.id else { return }

        struct ProfileSubscriptionPayload: Codable {
            let isProUser: Bool?
            let proExpiryTimestamp: Double?
            let trialStartTimestamp: Double?
            let planType: String?

            enum CodingKeys: String, CodingKey {
                case isProUser = "is_pro_user"
                case proExpiryTimestamp = "pro_expiry_timestamp"
                case trialStartTimestamp = "trial_start_timestamp"
                case planType = "plan_type"
            }
        }

        do {
            let client = SupabaseService.shared.client
            let profile: ProfileSubscriptionPayload = try await client
                .from("profiles")
                .select("is_pro_user, pro_expiry_timestamp, trial_start_timestamp, plan_type")
                .eq("id", value: myUID.uuidString)
                .single()
                .execute()
                .value

            self.isProPurchaser = profile.isProUser ?? false
            self.proExpiryTimestamp = profile.proExpiryTimestamp ?? 0.0
            self.proPlanType = profile.planType ?? ""

            if let savedTrial = profile.trialStartTimestamp, savedTrial > 0 {
                self.trialStartTimestamp = savedTrial
            } else {
                let now = Date().timeIntervalSince1970
                self.trialStartTimestamp = now
                let trialPayload = TrialUpdatePayload(trial_start_timestamp: now)
                try? await client
                    .from("profiles")
                    .update(trialPayload)
                    .eq("id", value: myUID.uuidString)
                    .execute()
            }
            recalculateProAccess()
        } catch {
            print("🚨 Failed to fetch subscription status:", error)
        }
    }

    // MARK: - Helper Methods
    func refreshTotalDaysTogether() {
        guard anniversaryDateTimestamp > 0 else {
            totalDaysTogether = 0
            syncAllWidgetData()
            return
        }
        let startDate = Date(timeIntervalSince1970: anniversaryDateTimestamp)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: Date()))
        totalDaysTogether = max(0, components.day ?? 0)
        syncAllWidgetData()
    }

    func anniversaryDate() -> Date {
        Date(timeIntervalSince1970: anniversaryDateTimestamp)
    }

    func syncAllWidgetData() {
        guard isLoggedIn else {
            WidgetSharedData.clearAllWidgetData()
            return
        }

        WidgetSharedData.saveSessionState(isLoggedIn: isLoggedIn, hasPartner: hasConnectedPartner)
        WidgetSharedData.saveRelationshipData(days: totalDaysTogether, timestamp: anniversaryDateTimestamp)
        WidgetSharedData.saveDistanceData(
            relationshipType: relationshipType,
            distanceKm: calculatedDistanceKm,
            userCity: userCity,
            partnerCity: partnerCity
        )

        if !profileImageData.isEmpty, let myImg = UIImage(data: profileImageData) {
            WidgetSharedData.saveImage(myImg, fileName: WidgetSharedData.myAvatarFile)
        }

        if hasConnectedPartner, !partnerProfileImageData.isEmpty, let partnerImg = UIImage(data: partnerProfileImageData) {
            WidgetSharedData.saveImage(partnerImg, fileName: WidgetSharedData.partnerAvatarFile)
        }
    }

    // MARK: - Supabase Synchronization
    struct CoupleSyncPayload: Codable {
        let anniversaryDateTimestamp: Double?
        let relationshipType: Int?
        let isCouplePro: Bool?

        enum CodingKeys: String, CodingKey {
            case anniversaryDateTimestamp = "anniversary_date_timestamp"
            case relationshipType = "relationship_type"
            case isCouplePro = "is_couple_pro"
        }
    }

    @MainActor
    func syncCoupleRelationshipData() async {
        guard let coupleId = await SupabaseService.shared.fetchCoupleId() else {
            self.isCouplePro = false
            recalculateProAccess()
            refreshTotalDaysTogether()
            syncAllWidgetData()
            return
        }

        let client = SupabaseService.shared.client

        do {
            let coupleData: CoupleSyncPayload = try await client
                .from("couples")
                .select("anniversary_date_timestamp, relationship_type, is_couple_pro")
                .eq("id", value: coupleId.uuidString)
                .single()
                .execute()
                .value

            if let ts = coupleData.anniversaryDateTimestamp, ts > 0 {
                self.anniversaryDateTimestamp = ts
            }

            if let rType = coupleData.relationshipType, rType > 0 {
                self.relationshipType = rType
            }

            self.isCouplePro = coupleData.isCouplePro ?? false

            // If current user is a Pro purchaser, ensure couple row reflects it
            if self.isProPurchaser && !self.isCouplePro {
                try? await client
                    .from("couples")
                    .update(["is_couple_pro": true])
                    .eq("id", value: coupleId.uuidString)
                    .execute()
                self.isCouplePro = true
            }

            recalculateProAccess()
            self.refreshTotalDaysTogether()
            await self.subscribeToCoupleChanges(coupleId: coupleId)
            self.syncAllWidgetData()
        } catch {
            print("Failed to sync couple relationship data:", error)
            self.refreshTotalDaysTogether()
            self.syncAllWidgetData()
        }
    }

    @MainActor
    func updateAnniversaryDate(_ date: Date) async {
        let timestamp = date.timeIntervalSince1970
        self.anniversaryDateTimestamp = timestamp
        self.refreshTotalDaysTogether()

        guard let coupleId = await SupabaseService.shared.fetchCoupleId() else { return }
        let client = SupabaseService.shared.client

        do {
            try await client
                .from("couples")
                .update(["anniversary_date_timestamp": timestamp])
                .eq("id", value: coupleId.uuidString)
                .execute()
        } catch {
            print("Failed to update anniversary date:", error)
        }
    }

    @MainActor
    func updateRelationshipType(_ type: Int) async {
        self.relationshipType = type
        self.syncAllWidgetData()

        guard let coupleId = await SupabaseService.shared.fetchCoupleId() else { return }
        let client = SupabaseService.shared.client

        do {
            try await client
                .from("couples")
                .update(["relationship_type": type])
                .eq("id", value: coupleId.uuidString)
                .execute()
        } catch {
            print("Failed to update relationship type:", error)
        }
    }

    private func subscribeToCoupleChanges(coupleId: UUID) async {
        guard !isSubscribedToCouple else { return }
        isSubscribedToCouple = true

        let client = SupabaseService.shared.client
        let channel = client.realtimeV2.channel("public:couples:\(coupleId.uuidString.lowercased())")
        self.coupleChannel = channel

        let changes = channel.postgresChange(
            UpdateAction.self,
            schema: "public",
            table: "couples"
        )

        Task { [weak self] in
            for await update in changes {
                guard let self = self else { return }
                
                var newTimestamp: Double? = nil
                var newType: Int? = nil
                var newCouplePro: Bool? = nil

                if let tsVal = update.record["anniversary_date_timestamp"]?.doubleValue {
                    newTimestamp = tsVal
                }
                if let typeVal = update.record["relationship_type"]?.intValue {
                    newType = typeVal
                }
                if let proVal = update.record["is_couple_pro"]?.boolValue {
                    newCouplePro = proVal
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if let newTimestamp = newTimestamp, newTimestamp > 0 {
                            self.anniversaryDateTimestamp = newTimestamp
                            self.refreshTotalDaysTogether()
                        }
                        if let newType = newType, newType > 0 {
                            self.relationshipType = newType
                        }
                        if let newCouplePro = newCouplePro {
                            self.isCouplePro = newCouplePro
                            self.recalculateProAccess()
                        }
                    }
                    self.syncAllWidgetData()
                }
            }
        }
        await channel.subscribe()
    }

    func clearAllSessionData() {
        isLoggedIn = false
        isSubscribedToCouple = false
        if let ch = coupleChannel { Task { await SupabaseService.shared.client.realtimeV2.removeChannel(ch) } }

        WidgetSharedData.clearAllWidgetData()

        DispatchQueue.main.async {
            self.userName = ""
            self.userGender = 0
            self.userPhone = ""
            self.partnerName = ""
            self.partnerHasProfileImage = false
            self.partnerProfileImageData = Data()
            self.relationshipType = 0
            self.anniversaryDateTimestamp = 0.0
            self.totalDaysTogether = 0
            self.profileImageData = Data()
            self.hasProfileImage = false
            self.authProvider = 0
            self.localPassword = ""
            self.isLiveDistanceEnabled = false
            self.userState = ""
            self.userCity = ""
            self.partnerState = ""
            self.partnerCity = ""
            self.calculatedDistanceKm = 0
            self.isProPurchaser = false
            self.isCouplePro = false
            self.isProUser = false
            self.proExpiryTimestamp = 0.0
            self.trialStartTimestamp = 0.0

            SupabaseQuizManager.shared.clearCache()
        }
    }

    func logOut() async {
        do {
            try await SupabaseService.shared.client.auth.signOut()
        } catch {
            print("Supabase sign out error:", error)
        }

        await MainActor.run {
            self.clearAllSessionData()
        }
    }
}
