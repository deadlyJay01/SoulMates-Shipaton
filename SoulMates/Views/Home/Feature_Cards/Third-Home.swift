//
//  Third-Home.swift
//  SoulMates
//

import SwiftUI

struct Third_Home: View {
    @EnvironmentObject private var storage: AppStorageManager
    @EnvironmentObject private var musicViewModel: ListenTogetherViewModel

    @State private var isFloating: Bool = false
    @State private var showPartnerAlert: Bool = false
    @State private var showInviteSheet: Bool = false
    @State private var pendingFeatureName: String = ""

    private var hasPartner: Bool {
        let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "partner"
    }

    private var partnerDisplayName: String {
        hasPartner ? storage.partnerName : "Partner"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Couple Corner")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {

                    // MARK: 1. Save Memories
                    NavigationLink {
                        Memories_Details()
                    } label: {
                        ZStack {
                            Image("bg22")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 200)
                                .opacity(0.7)

                            LinearGradient(
                                colors: [.black.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            VStack {
                                Text("MEMORIES")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .tracking(1.2)

                                Image("cam2")
                                    .resizable()
                                    .frame(width: 130, height: 170)
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                                    .padding(.vertical, -25)
                                    .offset(y: isFloating ? -4 : 4)
                                    .rotationEffect(.degrees(isFloating ? -2 : 2))

                                Text("Have Your Moments Here")
                                    .font(.system(size: 12, weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 140, height: 200)
                        .cornerRadius(10)
                    }

                    // Listen Songs
                    Group {
                        if hasPartner {
                            NavigationLink {
                                ListenTogetherView()
                                    .environmentObject(musicViewModel)
                                    .environmentObject(storage)
                            } label: {
                                musicCardContent
                            }
                        } else {
                            Button {
                                pendingFeatureName = "Listen Together"
                                showPartnerAlert = true
                            } label: {
                                musicCardContent
                            }
                        }
                    }

                    // Together
                    ZStack {
                        Image("tg3")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 200)
                            .clipped()

                        LinearGradient(
                            colors: [Color.black.opacity(0.65), Color.clear, Color.black.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(spacing: 0) {
                            Text("TOGETHER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.85))
                                .tracking(1.2)
                                .padding(.top, 14)

                            Spacer()

                            Text("Together for\n\(storage.totalDaysTogether) Days")
                                .font(.system(size: 12, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 14)
                        }
                        .frame(width: 140, height: 200)
                    }
                    .frame(width: 140, height: 200)
                    .cornerRadius(10)

                }
            }
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .partnerRequiredAlert(isPresented: $showPartnerAlert, featureName: pendingFeatureName, showInviteSheet: $showInviteSheet)
        .onAppear {
            isFloating = false
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
    }

    private var musicCardContent: some View {
        ZStack {
            Image("bg2")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 140, height: 200)
                .opacity(0.7)

            LinearGradient(
                colors: [.black.opacity(0.5), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                Text("SPOTIFY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1.2)

                // Continuous Hardware-Synced Rotation (Never freezes on login or navigation)
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (time.truncatingRemainder(dividingBy: 8.0) / 8.0) * 360.0

                    Image("musicDisk2")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .rotationEffect(.degrees(angle))
                        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)
                }

                Text("Listen Songs\nwith \(partnerDisplayName)")
                    .font(.system(size: 12, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
            }
        }
        .frame(width: 140, height: 200)
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ZStack {
            Color.black.ignoresSafeArea()
            Third_Home()
        }
    }
    .environmentObject(AppStorageManager())
    .environmentObject(ListenTogetherViewModel())
    .preferredColorScheme(.dark)
}
