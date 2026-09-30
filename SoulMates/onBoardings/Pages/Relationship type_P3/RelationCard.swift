//
//  RelationCard.swift
//  SoulMates
//
//  Created by Jay on 10/09/26.
//

import SwiftUI
// Card
struct RelationCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    private let gradientColors = [
        Color(red: 0.95, green: 0.25, blue: 0.42),
        Color(red: 0.65, green: 0.22, blue: 0.88)
    ]

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 18) {
                // Top Row: Icon & Checkmark
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isSelected ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                            .frame(width: 54, height: 54)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Checkmark Indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: 2)
                            .frame(width: 26, height: 26)

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(gradientColors[0])
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 26, height: 26)
                                )
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }

                // Bottom Content: Title & Subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .lineLimit(2)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(isSelected ? 0.85 : 0.55))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? gradientColors[0].opacity(0.35) : Color.clear,
                radius: 18,
                x: 0,
                y: 10
            )
        }
        .buttonStyle(.plain)
    }
}



