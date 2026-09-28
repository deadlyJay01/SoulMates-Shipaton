//
//  streak.swift
//  SoulMates
//
//  Created by Jay on 16/09/26.
//

import SwiftUI

struct streak: View {
    var StreakCount : Int?
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, Color(red: 0.95, green: 0.25, blue: 0.42)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Text("Streak \(StreakCount ?? 0)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    streak()
}
