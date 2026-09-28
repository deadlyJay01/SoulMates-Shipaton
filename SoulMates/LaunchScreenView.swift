//
//  LaunchScreenView.swift
//  SoulMates
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var logoHeartbeat: Bool = false
    @State private var ambientPulse: Bool = false

    private let brandGradient = LinearGradient(
        colors: [Color(red: 0.98, green: 0.28, blue: 0.45), Color(red: 0.68, green: 0.22, blue: 0.92)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            // MARK: - 1. Creative Romantic Aurora Background
            creativeAuroraBackground

            // MARK: - 2. Center Stage (Logo + Branding Text)
            VStack(spacing: 0) {
                Spacer()

                // Logo with Heartbeat Pulse & Soft Ambient Glow (No harsh ring)
                ZStack {
                    // Soft Ambient Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.28, blue: 0.45).opacity(ambientPulse ? 0.45 : 0.25),
                                    Color(red: 0.65, green: 0.20, blue: 0.90).opacity(ambientPulse ? 0.35 : 0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 160
                            )
                        )
                        .frame(width: 300, height: 300)
                        .blur(radius: 35)

                    // App Logo
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Color(red: 0.98, green: 0.28, blue: 0.45).opacity(0.50), radius: 24, y: 8)
                        .shadow(color: Color(red: 0.68, green: 0.22, blue: 0.92).opacity(0.35), radius: 32, y: 14)
                        .scaleEffect(logoHeartbeat ? 1.05 : 0.97)
                }
                .padding(.bottom, 24)

                // Static Branding Text
                VStack(spacing: 8) {
                    Text("SoulMates")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 1.0, green: 0.92, blue: 0.96)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 3)
                        .fixedSize()

                    Text("Two Souls • One Rhythm")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(2.6)
                        .foregroundStyle(brandGradient)
                        .fixedSize()
                }
                .frame(maxWidth: .infinity)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                logoHeartbeat = true
                ambientPulse = true
            }
        }
    }

    // MARK: - Creative Multi-Layered Aurora Mesh
    private var creativeAuroraBackground: some View {
        ZStack {
            // Base Deep Obsidian Midnight
            Color(red: 0.05, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            // Top-Right Magenta/Rose Glow Orb
            Circle()
                .fill(Color(red: 0.98, green: 0.28, blue: 0.45).opacity(0.26))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 120, y: -220)

            // Bottom-Left Violet/Indigo Cosmic Glow Orb
            Circle()
                .fill(Color(red: 0.55, green: 0.18, blue: 0.88).opacity(0.30))
                .frame(width: 340, height: 340)
                .blur(radius: 75)
                .offset(x: -120, y: 220)

            // Center Ambient Warmth
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.18),
                            Color(red: 0.70, green: 0.25, blue: 0.85).opacity(0.14),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 280, height: 400)
                .blur(radius: 50)

            // Delicate Floating Stardust
            GeometryReader { geo in
                sparkleStar(at: CGPoint(x: geo.size.width * 0.18, y: geo.size.height * 0.22), size: 12, opacity: 0.6)
                sparkleStar(at: CGPoint(x: geo.size.width * 0.82, y: geo.size.height * 0.28), size: 8, opacity: 0.4)
                sparkleStar(at: CGPoint(x: geo.size.width * 0.22, y: geo.size.height * 0.72), size: 10, opacity: 0.5)
                sparkleStar(at: CGPoint(x: geo.size.width * 0.78, y: geo.size.height * 0.76), size: 14, opacity: 0.65)
            }
            .ignoresSafeArea()
        }
    }

    private func sparkleStar(at point: CGPoint, size: CGFloat, opacity: Double) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundStyle(Color.white.opacity(opacity))
            .position(point)
    }
}

// MARK: - Previews
#Preview("Launch Screen") {
    LaunchScreenView()
        .preferredColorScheme(.dark)
}
