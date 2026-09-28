//
//  SyncedPlayerView.swift
//  SoulMates
//

import SwiftUI

struct SyncedPlayerView: View {
    @ObservedObject var viewModel: ListenTogetherViewModel
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var vinylRotation: Double = 0

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var actorName: String {
        storage.userName.isEmpty ? "Partner" : storage.userName
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Grab Bar
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                // Header without the Unpair button (Requirement 2)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LISTENING TOGETHER")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                        Text("Synced with \(storage.partnerName.isEmpty ? "Partner" : storage.partnerName)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Spinning Vinyl Graphic
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.1), Color(white: 0.02)],
                                center: .center,
                                startRadius: 40,
                                endRadius: 130
                            )
                        )
                        .frame(width: 250, height: 250)
                        .shadow(color: Color.black.opacity(0.6), radius: 20, y: 10)
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))

                    ForEach([70, 95, 115], id: \.self) { r in
                        Circle()
                            .stroke(Color.white.opacity(0.04), lineWidth: 1)
                            .frame(width: CGFloat(r * 2), height: CGFloat(r * 2))
                    }

                    Group {
                        if let uiImage = UIImage(named: viewModel.currentTrack.coverImageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Circle()
                                .fill(primaryGradient)
                                .overlay(Image(systemName: "music.note").font(.system(size: 32)).foregroundStyle(.white))
                        }
                    }
                    .frame(width: 95, height: 95)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 3))

                    Circle()
                        .fill(Color.black)
                        .frame(width: 14, height: 14)
                }
                .rotationEffect(.degrees(vinylRotation))
                .onChange(of: viewModel.isPlaying) { _, isPlaying in
                    if isPlaying {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            vinylRotation += 360
                        }
                    }
                }

                Spacer()

                // Song Title & Like Button
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.currentTrack.title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text(viewModel.currentTrack.artist)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button {
                        Task { await viewModel.toggleLike(trackId: viewModel.currentTrack.id, userName: actorName) }
                    } label: {
                        Image(systemName: viewModel.likedTrackIds.contains(viewModel.currentTrack.id) ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundStyle(viewModel.likedTrackIds.contains(viewModel.currentTrack.id) ? Color(red: 0.95, green: 0.25, blue: 0.42) : .white.opacity(0.5))
                            .scaleEffect(viewModel.likedTrackIds.contains(viewModel.currentTrack.id) ? 1.15 : 1.0)
                    }
                }
                .padding(.horizontal, 28)

                // Track Duration Progress Bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        let progress: CGFloat = {
                            guard viewModel.duration > 0,
                                  !viewModel.duration.isNaN,
                                  !viewModel.duration.isInfinite else { return 0 }
                            let ratio = viewModel.currentTime / viewModel.duration
                            guard !ratio.isNaN, !ratio.isInfinite else { return 0 }
                            return CGFloat(min(1.0, max(0.0, ratio)))
                        }()

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 5)

                            Capsule()
                                .fill(primaryGradient)
                                .frame(width: max(0, geo.size.width * progress), height: 5)
                        }
                    }
                    .frame(height: 5)

                    HStack {
                        Text(formatTime(viewModel.currentTime))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))

                        Spacer()

                        Text(formatTime(viewModel.duration))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 28)

                // Synced Controls
                HStack(spacing: 36) {
                    Button {
                        changeTrackRelative(step: -1)
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }

                    Button {
                        Task { await viewModel.togglePlayPause(actorName: actorName) }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(primaryGradient)
                                .frame(width: 66, height: 66)
                                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 10, y: 4)

                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }

                    Button {
                        changeTrackRelative(step: 1)
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.bottom, 36)
            }
        }
    }

    private func changeTrackRelative(step: Int) {
        let all = SongTrack.catalogue
        guard let currentIdx = all.firstIndex(where: { $0.id == viewModel.currentTrack.id }) else { return }
        var nextIdx = (currentIdx + step) % all.count
        if nextIdx < 0 { nextIdx = all.count - 1 }
        Task {
            await viewModel.changeTrack(to: all[nextIdx], actorName: actorName)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
