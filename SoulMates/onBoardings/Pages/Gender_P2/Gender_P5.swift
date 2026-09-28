//
//  Gender_P5.swift
//  SoulMates
//
//  Created by Jay on 08/09/26.
//

import SwiftUI

struct Gender_P5: View {
    @EnvironmentObject private var storage: AppStorageManager
    @State private var animateContent: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()
            
            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("What is your gender?")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Text("Select an option to personalize your profile and experience.")
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
                
                // Gender Selection Cards
                VStack(spacing: 16) {
                    GenderSelectionCard(
                        icon: "figure.stand",
                        title: "Male",
                        subtitle: "Identifies as male",
                        isSelected: storage.userGender == 1
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            storage.userGender = (storage.userGender == 1) ? 0 : 1
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18), value: animateContent)
                    
                    GenderSelectionCard(
                        icon: "figure.stand.dress",
                        title: "Female",
                        subtitle: "Identifies as female",
                        isSelected: storage.userGender == 2
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            storage.userGender = (storage.userGender == 2) ? 0 : 2
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.28), value: animateContent)
                    
                    GenderSelectionCard(
                        icon: "person.fill.questionmark",
                        title: "Prefer Not to Say",
                        subtitle: "Keep gender private",
                        isSelected: storage.userGender == 3
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            storage.userGender = (storage.userGender == 3) ? 0 : 3
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.38), value: animateContent)
                }
                .padding(.horizontal, 28)
                
                Spacer()
            }
        }
        .onAppear {
            animateContent = true
        }
    }
}

#Preview {
    Gender_P5()
        .environmentObject(AppStorageManager())
}
