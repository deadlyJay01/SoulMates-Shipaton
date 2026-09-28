//
//  relationType_P2.swift
//  SoulMates
//
//  Created by Jay on 05/09/26.
//

import SwiftUI

struct relationType_P2: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var animateContent: Bool = false

    var body: some View {
        ZStack {
            onBoarding_Background()

            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("\(storage.userName.isEmpty ? "What" : storage.userName + ", what")'s your relationship type?")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .lineLimit(3)

                    Text("Choose the one that best fits your story.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 10)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)

                // Cards Selection
                VStack(spacing: 20) {
                    // Card 1: Close-Distance
                    RelationCard(
                        icon: "house.fill",
                        title: "Close-Distance",
                        subtitle: "Living in the same city, spending days and nights close by.",
                        isSelected: storage.relationshipType == 1
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            storage.relationshipType = (storage.relationshipType == 1) ? 0 : 1
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18), value: animateContent)

                    // Card 2: Long-Distance
                    RelationCard(
                        icon: "globe.americas.fill",
                        title: "Long-Distance",
                        subtitle: "Different cities or countries, counting down days until the next flight.",
                        isSelected: storage.relationshipType == 2
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            storage.relationshipType = (storage.relationshipType == 2) ? 0 : 2
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.28), value: animateContent)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 10)

                Spacer()
            }
        }
        .onAppear {
            animateContent = true
        }
    }
}

#Preview {
    relationType_P2()
        .environmentObject(AppStorageManager())
}
