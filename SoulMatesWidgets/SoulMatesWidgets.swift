//
//  SoulMatesWidgets.swift
//  SoulMatesWidgets
//
//  Created by CPC on 23/09/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct SoulMatesTimelineEntry: TimelineEntry {
    let date: Date
    let isLoggedIn: Bool
    let hasPartner: Bool
    let totalDays: Int
    let partnerSelfie: UIImage?
    let myAvatar: UIImage?
    let partnerAvatar: UIImage?
    
    let relationshipType: Int
    let distanceKm: Int
    let userCity: String
    let partnerCity: String

    var isLongDistance: Bool {
        relationshipType == 2 && distanceKm > 0
    }

    var formattedDistance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let dist = formatter.string(from: NSNumber(value: distanceKm)) ?? "\(distanceKm)"
        return "\(dist) km"
    }
}

// MARK: - Timeline Provider
struct SoulMatesWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SoulMatesTimelineEntry {
        SoulMatesTimelineEntry(
            date: Date(),
            isLoggedIn: true,
            hasPartner: true,
            totalDays: 792,
            partnerSelfie: nil,
            myAvatar: nil,
            partnerAvatar: nil,
            relationshipType: 2,
            distanceKm: 1240,
            userCity: "London",
            partnerCity: "Paris"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SoulMatesTimelineEntry) -> Void) {
        let session = WidgetSharedData.readSessionState()
        let distInfo = WidgetSharedData.readDistanceInfo()
        let entry = SoulMatesTimelineEntry(
            date: Date(),
            isLoggedIn: session.isLoggedIn,
            hasPartner: session.hasPartner,
            totalDays: WidgetSharedData.readTotalDays(),
            partnerSelfie: WidgetSharedData.readImage(fileName: WidgetSharedData.partnerSelfieFile),
            myAvatar: WidgetSharedData.readImage(fileName: WidgetSharedData.myAvatarFile),
            partnerAvatar: WidgetSharedData.readImage(fileName: WidgetSharedData.partnerAvatarFile),
            relationshipType: distInfo.relationshipType,
            distanceKm: distInfo.distanceKm,
            userCity: distInfo.userCity,
            partnerCity: distInfo.partnerCity
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (WidgetKit.Timeline<SoulMatesTimelineEntry>) -> Void) {
        let session = WidgetSharedData.readSessionState()
        let distInfo = WidgetSharedData.readDistanceInfo()
        let entry = SoulMatesTimelineEntry(
            date: Date(),
            isLoggedIn: session.isLoggedIn,
            hasPartner: session.hasPartner,
            totalDays: WidgetSharedData.readTotalDays(),
            partnerSelfie: WidgetSharedData.readImage(fileName: WidgetSharedData.partnerSelfieFile),
            myAvatar: WidgetSharedData.readImage(fileName: WidgetSharedData.myAvatarFile),
            partnerAvatar: WidgetSharedData.readImage(fileName: WidgetSharedData.partnerAvatarFile),
            relationshipType: distInfo.relationshipType,
            distanceKm: distInfo.distanceKm,
            userCity: distInfo.userCity,
            partnerCity: distInfo.partnerCity
        )

        let midnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let timeline = WidgetKit.Timeline<SoulMatesTimelineEntry>(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }
}

// MARK: - Reusable Placeholder View for Logged Out / No Partner States
struct WidgetSessionStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(primaryGradient.opacity(0.18))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
            }

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.07, blue: 0.12))
    }
}

// MARK: - Dotted Line
struct DottedLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

// ========================================================
// MARK: - 1. PARTNER SELFIE WIDGET (.small, .large)
// ========================================================
struct PartnerSelfieWidgetView: View {
    let entry: SoulMatesTimelineEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0.08, green: 0.07, blue: 0.12)

                if !entry.isLoggedIn {
                    WidgetSessionStateView(
                        icon: "lock.fill",
                        title: "Log In Required",
                        subtitle: "Open SoulMates to sign in"
                    )
                } else if !entry.hasPartner {
                    WidgetSessionStateView(
                        icon: "person.crop.circle.badge.plus",
                        title: "Pair Partner",
                        subtitle: "Connect your soulmate"
                    )
                } else if let selfie = entry.partnerSelfie {
                    Image(uiImage: selfie)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()

                    LinearGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack {
                        Spacer()
                        HStack(spacing: 5) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Partner's Glimpse")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, family == .systemLarge ? 14 : 9)
                    }
                } else {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 44, height: 44)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }

                        Text("No Selfie Yet")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text("Waiting for partner")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .ignoresSafeArea()
        .widgetURL(WidgetSharedData.deepLinkSelfieURL)
    }
}

struct PartnerSelfieWidget: Widget {
    let kind: String = "PartnerSelfieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SoulMatesWidgetProvider()) { entry in
            PartnerSelfieWidgetView(entry: entry)
                .containerBackground(Color(red: 0.08, green: 0.07, blue: 0.12), for: .widget)
        }
        .configurationDisplayName("Partner's Selfie")
        .description("Displays your partner's latest shared photo.")
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}

// ========================================================
// MARK: - 2. COUPLE CONNECTION & DISTANCE WIDGET (.small, .medium)
// ========================================================
struct CoupleCounterWidgetView: View {
    let entry: SoulMatesTimelineEntry
    @Environment(\.widgetFamily) var family

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color(red: 0.09, green: 0.08, blue: 0.13)

            if !entry.isLoggedIn {
                WidgetSessionStateView(
                    icon: "lock.fill",
                    title: "Log In",
                    subtitle: "Sign in to view your love timeline"
                )
            } else if !entry.hasPartner {
                WidgetSessionStateView(
                    icon: "heart.slash.fill",
                    title: "No Partner Linked",
                    subtitle: "Invite partner in the app"
                )
            } else if family == .systemMedium {
                // Medium Layout
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            avatarCircle(image: entry.myAvatar, defaultIcon: "person.fill", size: 50)
                            if entry.isLongDistance && !entry.userCity.isEmpty {
                                Text(entry.userCity)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }

                        ZStack {
                            DottedLineShape()
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .foregroundStyle(Color.white.opacity(0.35))
                                .frame(height: 1)

                            Circle()
                                .fill(primaryGradient)
                                .frame(width: 28, height: 28)
                                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.5), radius: 6)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)

                        VStack(spacing: 4) {
                            avatarCircle(image: entry.partnerAvatar, defaultIcon: "heart.fill", size: 50)
                            if entry.isLongDistance && !entry.partnerCity.isEmpty {
                                Text(entry.partnerCity)
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 22)

                    VStack(spacing: 2) {
                        Text("\(entry.totalDays) Days")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)

                        if entry.isLongDistance {
                            HStack(spacing: 5) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 8))
                                Text("\(entry.formattedDistance) APART")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .tracking(1.8)
                            }
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        } else {
                            Text("TOGETHER")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(2.5)
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }
                    }
                }
            } else {
                // Small Layout
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        avatarCircle(image: entry.myAvatar, defaultIcon: "person.fill", size: 36)

                        ZStack {
                            DottedLineShape()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2.5, 2.5]))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .frame(height: 1)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)

                        avatarCircle(image: entry.partnerAvatar, defaultIcon: "heart.fill", size: 36)
                    }
                    .padding(.horizontal, 8)

                    VStack(spacing: 2) {
                        Text("\(entry.totalDays)")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        if entry.isLongDistance {
                            Text("\(entry.formattedDistance) APART")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(1.1)
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text("DAYS TOGETHER")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
    }

    private func avatarCircle(image: UIImage?, defaultIcon: String, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: size, height: size)

            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: defaultIcon)
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .overlay(
            Circle()
                .stroke(primaryGradient, lineWidth: 1.5)
        )
    }
}

struct CoupleCounterWidget: Widget {
    let kind: String = "CoupleCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SoulMatesWidgetProvider()) { entry in
            CoupleCounterWidgetView(entry: entry)
                .containerBackground(Color(red: 0.09, green: 0.08, blue: 0.13), for: .widget)
        }
        .configurationDisplayName("Couple Connection")
        .description("View profile photos connected by love with your days counter and distance.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

// ========================================================
// MARK: - 3. MINIMAL DAYS & DISTANCE COUNTER (.small)
// ========================================================
struct MinimalDaysCounterWidgetView: View {
    let entry: SoulMatesTimelineEntry

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.07, blue: 0.12)

            if !entry.isLoggedIn {
                WidgetSessionStateView(
                    icon: "lock.fill",
                    title: "Log In",
                    subtitle: "Open app to sign in"
                )
            } else if !entry.hasPartner {
                WidgetSessionStateView(
                    icon: "heart.slash.fill",
                    title: "Pair Partner",
                    subtitle: "Connect your soulmate"
                )
            } else {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(primaryGradient.opacity(0.18))
                            .frame(width: 36, height: 36)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(primaryGradient)
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.5), radius: 6)
                    }

                    Text("\(entry.totalDays)")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if entry.isLongDistance {
                        HStack(spacing: 4) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 8))
                            Text("\(entry.formattedDistance) APART")
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(1.2)
                        }
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    } else {
                        Text("DAYS TOGETHER")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.8)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                .padding(12)
            }
        }
    }
}

struct MinimalDaysCounterWidget: Widget {
    let kind: String = "MinimalDaysCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SoulMatesWidgetProvider()) { entry in
            MinimalDaysCounterWidgetView(entry: entry)
                .containerBackground(Color(red: 0.08, green: 0.07, blue: 0.12), for: .widget)
        }
        .configurationDisplayName("Days Together")
        .description("Clean and minimal counter celebrating your shared journey.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// ========================================================
// MARK: - WIDGET BUNDLE ROOT
// ========================================================
@main
struct SoulMatesWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PartnerSelfieWidget()
        CoupleCounterWidget()
        MinimalDaysCounterWidget()
    }
}
