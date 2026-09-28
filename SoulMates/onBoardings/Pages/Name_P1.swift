//
//  Name_P1.swift
//  SoulMates
//

import SwiftUI

struct Name_P1: View {
    @EnvironmentObject private var storage: AppStorageManager
    
    @FocusState private var isFocused: Bool
    @State private var animateContent: Bool = false

    private let gradientColors = [
        Color(red: 0.95, green: 0.25, blue: 0.42),
        Color(red: 0.65, green: 0.22, blue: 0.88)
    ]

    var body: some View {
        ZStack {
            onBoarding_Background()
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What's Your Name?")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(.white)
                        
                        Text("This is how you'll appear in your shared space.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, 24)
                    .offset(y: animateContent ? 0 : 20)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)
                    
                    HStack(spacing: 12) {
                        TextField(
                            "",
                            text: $storage.userName,
                            prompt: Text("Your Name").foregroundStyle(.white.opacity(0.28))
                        )
                        .submitLabel(.done)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        
                        if !storage.userName.isEmpty {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    storage.userName = ""
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.18), value: animateContent)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: isFocused ? gradientColors : [Color.white.opacity(0.18), Color.white.opacity(0.18)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: isFocused ? 2.5 : 1.5)
                        .scaleEffect(x: animateContent ? 1.0 : 0.05, anchor: .leading)
                        .shadow(
                            color: isFocused ? gradientColors[0].opacity(0.55) : Color.clear,
                            radius: 8,
                            x: 0,
                            y: 3
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.28), value: animateContent)
                        .animation(.easeInOut(duration: 0.25), value: isFocused)
                }
                .padding(.horizontal, 28)
                .padding(.top, 24)
                
                Spacer()
            }
        }
        .onAppear {
            animateContent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isFocused = true
            }
        }
    }
}

#Preview {
    Name_P1()
        .environmentObject(AppStorageManager())
}
