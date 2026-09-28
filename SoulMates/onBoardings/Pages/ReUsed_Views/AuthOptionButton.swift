//
//  AuthOptionButton.swift
//  SoulMates
//

import SwiftUI

struct AuthOptionButton: View {
    let title: String
    var systemIcon: String? = nil
    var customImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AuthButtonContent(title: title, systemIcon: systemIcon, customImage: customImage)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct AuthButtonContent: View {
    let title: String
    var systemIcon: String? = nil
    var customImage: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            if let customImage = customImage {
                Image(customImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            } else if let systemIcon = systemIcon {
                Image(systemName: systemIcon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}
