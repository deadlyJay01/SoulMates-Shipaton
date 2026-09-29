//
//  OnboardingFlowContainerView.swift
//  SoulMates
//

import SwiftUI

struct OnboardingFlowContainerView: View {
    @EnvironmentObject private var storage: AppStorageManager
    
    @State private var currentStep: Int = 1
    @State private var navigateToSignUp: Bool = false
    
    // Total steps before auth screen
    private let totalSteps: Int = 7

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                onBoarding_Background()
                
                VStack(spacing: 0) {
                    // Active Step View
                    ZStack {
                        switch currentStep {
                        case 1:
                            Name_P1()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 2:
                            Gender_P5()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 3:
                            relationType_P2()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 4:
                            datePicker_P3()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 5:
                            selectProfileImage_P4()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 6:
                            Quiz_Freture_P6()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        case 7:
                            Memories_Freature_P7()
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .leading)
                                ))
                            
                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Bottom Navigation Bar
                    bottomBar
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
            .navigationDestination(isPresented: $navigateToSignUp) {
                AuthGateway(startInLogin: false)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Controls
    private var bottomBar: some View {
        HStack(spacing: 14) {
            if currentStep > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        currentStep -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            OnboardingActionButton(
                title: currentStep == totalSteps ? "Get Started" : "Continue",
                isEnabled: canProceed()
            ) {
                advanceStep()
            }
        }
    }

    // MARK: - Step Validation Guard
    private func canProceed() -> Bool {
        switch currentStep {
        case 1:
            return !storage.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2:
            return storage.userGender != 0
        case 3:
            return storage.relationshipType != 0
        case 4:
            return storage.anniversaryDateTimestamp > 0
        case 5, 6, 7:
            return true
        default:
            return true
        }
    }

    private func advanceStep() {
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.28)) {
                currentStep += 1
            }
        } else {
            navigateToSignUp = true
        }
    }
}
