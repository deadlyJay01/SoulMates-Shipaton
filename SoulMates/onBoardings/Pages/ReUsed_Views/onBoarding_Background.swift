//
//  onBoarding_Background.swift
//  SoulMates
//
//  Created by Jay on 03/09/26.
//

import SwiftUI

struct onBoarding_Background: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            LinearGradient(
                colors: [
                    .red1.opacity(0.20),
                    .orange.opacity(0.10),
                    .purple1.opacity(0.20),
                    .blue.opacity(0.05),
                    .red1.opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 60)
            .ignoresSafeArea()
        }
    }
}

#Preview {
    onBoarding_Background()
}
