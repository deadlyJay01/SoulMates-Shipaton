//
//  WidgetSharedData.swift
//  SoulMates
//

import SwiftUI
import WidgetKit

public struct WidgetSharedData {
    public static let appGroupId = "group.jay.SoulMates"
    public static let deepLinkSelfieURL = URL(string: "soulmates://couple-selfie")!

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    private static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    // Session & Partner State
    public static func saveSessionState(isLoggedIn: Bool, hasPartner: Bool) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(isLoggedIn, forKey: "widget_is_logged_in")
        defaults.set(hasPartner, forKey: "widget_has_partner")
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func readSessionState() -> (isLoggedIn: Bool, hasPartner: Bool) {
        let loggedIn = sharedDefaults?.bool(forKey: "widget_is_logged_in") ?? false
        let partnered = sharedDefaults?.bool(forKey: "widget_has_partner") ?? false
        return (loggedIn, partnered)
    }

    // Days & Relationship Data
    public static func saveTotalDays(_ days: Int) {
            sharedDefaults?.set(days, forKey: "widget_total_days")
            WidgetCenter.shared.reloadAllTimelines()
        }
    
    public static func saveRelationshipData(days: Int, timestamp: Double) {
        sharedDefaults?.set(days, forKey: "widget_total_days")
        sharedDefaults?.set(timestamp, forKey: "widget_anniversary_timestamp")
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func saveDistanceData(
        relationshipType: Int,
        distanceKm: Int,
        userCity: String,
        partnerCity: String
    ) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(relationshipType, forKey: "widget_relationship_type")
        defaults.set(distanceKm, forKey: "widget_distance_km")
        defaults.set(userCity, forKey: "widget_user_city")
        defaults.set(partnerCity, forKey: "widget_partner_city")
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func readTotalDays() -> Int {
        let ts = sharedDefaults?.double(forKey: "widget_anniversary_timestamp") ?? 0
        if ts > 0 {
            let startDate = Date(timeIntervalSince1970: ts)
            let calendar = Calendar.current
            let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: Date()))
            return max(0, diff.day ?? 0)
        }
        return sharedDefaults?.integer(forKey: "widget_total_days") ?? 0
    }

    public static func readDistanceInfo() -> (relationshipType: Int, distanceKm: Int, userCity: String, partnerCity: String) {
        let rType = sharedDefaults?.integer(forKey: "widget_relationship_type") ?? 0
        let dist = sharedDefaults?.integer(forKey: "widget_distance_km") ?? 0
        let uCity = sharedDefaults?.string(forKey: "widget_user_city") ?? ""
        let pCity = sharedDefaults?.string(forKey: "widget_partner_city") ?? ""
        return (rType, dist, uCity, pCity)
    }

    // Disk Container)
    public static let partnerSelfieFile = "partner_latest_selfie.jpg"
    public static let myAvatarFile = "user_avatar.jpg"
    public static let partnerAvatarFile = "partner_avatar.jpg"

    public static func saveImage(_ image: UIImage, fileName: String) {
        guard let container = sharedContainerURL else { return }
        let fileURL = container.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: fileURL, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func readImage(fileName: String) -> UIImage? {
        guard let container = sharedContainerURL else { return nil }
        let fileURL = container.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    // Complete Wipe on Logout / Switch Accounts
    public static func clearAllWidgetData() {
        // 1. Wipe all keys from shared UserDefaults
        if let defaults = sharedDefaults {
            defaults.removePersistentDomain(forName: appGroupId)
            defaults.synchronize()
        }

        // 2. Delete all cached image files from App Group disk folder
        if let container = sharedContainerURL {
            let fileManager = FileManager.default
            let files = [partnerSelfieFile, myAvatarFile, partnerAvatarFile]
            for file in files {
                let fileURL = container.appendingPathComponent(file)
                if fileManager.fileExists(atPath: fileURL.path) {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }

        // 3. Mark as logged out and refresh widgets immediately
        saveSessionState(isLoggedIn: false, hasPartner: false)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
