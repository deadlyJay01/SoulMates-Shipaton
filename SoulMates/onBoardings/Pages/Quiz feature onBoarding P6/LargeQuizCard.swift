//
//  LargeQuizCard.swift
//  SoulMates
//
//  Created by Jay on 10/09/26.
//

import SwiftUI

struct QuizItem: Identifiable, Equatable {
    let id: Int
    let icon: String
    let title: String
    let badge: String
    let gameplayDescription: String
    let tip: String
    let gradientColors: [Color]
}
// MARK: - Larger, Content-Rich Card Component
struct LargeQuizCard: View {
    let item: QuizItem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header Row: Icon + Badge
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text(item.badge)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                    )
            }
            
            // Title & Concept Rules
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                
                Text(item.gameplayDescription)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
            
            // Bottom Tip/Highlight Row
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                
                Text(item.tip)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.18))
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .frame(height: 360) // Locks standard height across all cards
        .background(
            ZStack{
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        Color.black
                    )
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: item.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )}
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: item.gradientColors[0].opacity(0.35), radius: 18, x: 0, y: 10)
    }
}
