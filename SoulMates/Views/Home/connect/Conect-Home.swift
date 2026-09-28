//
//  Conect-Home.swift
//  SoulMates
//
//  Created by Jay on 03/09/26.
//

import SwiftUI

struct Conect_Home: View {
    @EnvironmentObject private var storage: AppStorageManager

    @State private var showPartnerAlert: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var pendingFeatureName: String = ""

    private var hasPartner: Bool {
        let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "partner"
    }

    var body: some View {
        VStack(spacing: 16) {
            // MARK: - Section Title
            HStack {
                Text("More Ways to Connect")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()
            }
            .padding(.horizontal, 4)

            // MARK: - Dual Action Cards
            HStack(spacing: 16) {
                // Card 1: DATES (Untouched)
                Group {
                    if hasPartner {
                        NavigationLink(destination: DatesDetail()) {
                            datesCardContent
                        }
                    } else {
                        Button {
                            pendingFeatureName = "Couple Calendar"
                            showPartnerAlert = true
                        } label: {
                            datesCardContent
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())

                // Card 2: WIDGETS
                NavigationLink(destination: WidgetsShowcaseView()) {
                    widgetsCardContent
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .partnerRequiredAlert(
            isPresented: $showPartnerAlert,
            featureName: pendingFeatureName,
            showInviteSheet: $showInviteSheet
        )
    }

    // MARK: - Dates Visual Content (Untouched)
    private var datesCardContent: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.20, blue: 0.90).opacity(0.35),
                            Color(red: 0.18, green: 0.08, blue: 0.35).opacity(0.85),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.55, green: 0.20, blue: 0.90).opacity(0.6),
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }

            VStack(alignment: .leading) {
                Image("Date")
                    .resizable()
                    .frame(width: 160, height: 110)
                    .padding(-45)
                    .padding(.leading, 10)
                    .shadow(radius: 5)
                    .padding(.top, 20)

                Spacer()

                Text("DATES")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.9))
                    .tracking(1.2)
                    .padding(.horizontal)

                Text("put it on\nour calendar")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 175)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 12, y: 6)
    }

    // MARK: - Widgets Visual Content
    private var widgetsCardContent: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35),
                            Color(red: 0.35, green: 0.08, blue: 0.18).opacity(0.85),
                            Color.black.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.6),
                                    Color.white.opacity(0.12),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }

            VStack(alignment: .leading) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 36
                            )
                        )
                        .frame(width: 60, height: 60)

                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 10)
                .padding(.leading, 12)

                Spacer()

                Text("WIDGETS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.9))
                    .tracking(1.2)
                    .padding(.horizontal)

                Text("Decorate your\nHome Screen")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 175)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 12, y: 6)
    }
}
