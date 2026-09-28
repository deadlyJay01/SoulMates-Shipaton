//
//  HomePage.swift
//  SoulMates
//
//  Created by Jay on 02/09/26.
//

import SwiftUI
import Supabase

struct HomePageView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var showInviteSheet: Bool = false

    private var hasPartner: Bool {
        let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "partner"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                onBoarding_Background()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 36)

                        // Top Header Pill
                        HStack(spacing: 12) {
                            if !hasPartner {
                                Button {
                                    showInviteSheet = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 13, weight: .semibold))
                                        Text("Invite partner")
                                            .font(.system(size: 13, weight: .bold))
                                    }
                                    .frame(width: 145)
                                    .foregroundStyle(.white)
                                }
                                .buttonStyle(.glass)
                                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 10)
                            } else {
                                HStack(spacing: 8) {
                                    Button { } label: {
                                        HStack(spacing: 6) {
                                            Text("💕")
                                                .font(.system(size: 13))
                                            Text("\(storage.totalDaysTogether)d together")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .buttonStyle(.glass)
                                    .shadow(radius: 6)

                                    if storage.isLiveDistanceEnabled {
                                        Button { } label: {
                                            HStack(spacing: 6) {
                                                Text("📍")
                                                    .font(.system(size: 13))
                                                Text("\(storage.calculatedDistanceKm > 0 ? storage.calculatedDistanceKm : 520) km apart")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .buttonStyle(.glass)
                                        .shadow(radius: 6)
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: storage.isLiveDistanceEnabled)

                        // 1. Notes & Profile (Passes partner state)
                        notes_Profile_Home(HasPartner: hasPartner) {
                            showInviteSheet = true
                        }

                        // 2. Challenge card
                        Challange_Home()

                        // 3. Featured Carousel
                        Third_Home()
                        
                        // 4. More ways to connect
                        Conect_Home()

                        Spacer().frame(height: 100)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showInviteSheet) {
            NavigationStack {
                InvitePartnerView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}
