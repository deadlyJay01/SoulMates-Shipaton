//
//  Quiz_Freture_P6.swift
//  SoulMates
//
//  Created by Jay on 09/09/26.
//

import SwiftUI

struct Quiz_Freture_P6: View {
    @State private var cards: [QuizItem] = [
        QuizItem(
            id: 1,
            icon: "arrow.left.arrow.right",
            title: "This or That",
            badge: "Instant Picks",
            gameplayDescription: "Choose between two rapid scenarios and check if your partner made the exact same choice in real time.",
            tip: "Great for spontaneous debate & laughs",
            gradientColors: [Color(red: 0.68, green: 0.28, blue: 0.92).opacity(0.7), Color(red: 0.55, green: 0.12, blue: 0.40)]
        ),
        QuizItem(
            id: 2,
            icon: "hand.thumbsup.fill",
            title: "Yes / No",
            badge: "Fast Reactions",
            gameplayDescription: "Swipe without overthinking. Discover surprises about your partner's unspoken views and habits.",
            tip: "No middle ground, purely honest answers",
            gradientColors: [Color(red: 0.95, green: 0.25, blue: 0.45).opacity(0.7), Color(red: 0.10, green: 0.20, blue: 0.62)]
        ),
        QuizItem(
            id: 3,
            icon: "person.2.wave.2.fill",
            title: "Most Likely To",
            badge: "Playful Accusations",
            gameplayDescription: "Vote on who is more likely to wake up late, plan spontaneous road trips, or start laughing in serious moments.",
            tip: "See who blames whom the most",
            gradientColors: [Color(red: 0.18, green: 0.52, blue: 0.95).opacity(0.7), Color(red: 0.72, green: 0.25, blue: 0.12)]
        ),
        QuizItem(
            id: 4,
            icon: "sparkles",
            title: "Couple Trivia",
            badge: "Memory & Milestones",
            gameplayDescription: "Answer questions about your relationship timeline, favorite memories, and the little details only you two know.",
            tip: "Test how well you remember your history",
            gradientColors: [Color(red: 0.96, green: 0.52, blue: 0.18).opacity(0.7), Color(red: 0.38, green: 0.14, blue: 0.65)]
        )
    ]
    
    @State private var topCardOffset: CGSize = .zero
    @State private var swipeDirectionIsLeft: Bool = true
    @State private var timer: Timer?
    @State private var animateEntry: Bool = false
    
    var body: some View {
        ZStack {
            onBoarding_Background()
            
            VStack(alignment: .leading, spacing: 14) {
                // Header Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Play Quiz With Your Partner.")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                    
                    Text("Discover new things about each other and strengthen your bond.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(.top, 10)
                .offset(y: animateEntry ? 0 : 20)
                .opacity(animateEntry ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: animateEntry)
                
                Spacer()
                
                // Stacked Interactive Card Deck
                ZStack {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, item in
                        let isTopCard = (index == 0)
                        let depth = CGFloat(index)
                        
                        LargeQuizCard(item: item)
                            .offset(
                                x: isTopCard ? topCardOffset.width : 0,
                                y: isTopCard ? topCardOffset.height : (depth * 14)
                            )
                            .rotationEffect(.degrees(isTopCard ? Double(topCardOffset.width / 18) : 0))
                            .scaleEffect(isTopCard ? 1.0 : max(0.85, 1.0 - (depth * 0.045)))
                            .opacity(depth >= 3 ? 0.4 : 1.0 - (Double(depth) * 0.14))
                            .zIndex(Double(cards.count - index))
                            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: cards)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .offset(y: animateEntry ? 0 : 30)
                .opacity(animateEntry ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.18), value: animateEntry)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
        }
        .onAppear {
            animateEntry = true
            startLoop()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startLoop() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 2.7, repeats: true) { _ in
            dismissTopCard()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func dismissTopCard() {
        guard cards.count > 1 else { return }
        
        let screenWidth = UIScreen.main.bounds.width
        let throwDistance = swipeDirectionIsLeft ? -screenWidth * 1.3 : screenWidth * 1.3
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            topCardOffset = CGSize(width: throwDistance, height: 20)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            let removedCard = cards.removeFirst()
            cards.append(removedCard)
            
            topCardOffset = .zero
            swipeDirectionIsLeft.toggle()
        }
    }
}

#Preview {
    Quiz_Freture_P6()
}
