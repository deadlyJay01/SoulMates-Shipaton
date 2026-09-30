//
//  ListenTogetherView.swift
//  SoulMates
//

import SwiftUI

struct ListenTogetherView: View {
    @EnvironmentObject private var viewModel: ListenTogetherViewModel
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var actorName: String {
        storage.userName.isEmpty ? "Partner" : storage.userName
    }

    private var partnerName: String {
        storage.partnerName.isEmpty ? "your SoulMate" : storage.partnerName
    }

    private var displayedTracks: [SongTrack] {
        if selectedTab == 1 {
            return SongTrack.catalogue.filter { viewModel.likedTrackIds.contains($0.id) }
        }
        return SongTrack.catalogue
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            onBoarding_Background()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header Bar with Pair / Unpair Button
                HStack(alignment: .center) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Listen Together")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        HStack(spacing: 5) {
                            Circle()
                                .fill(viewModel.isPaired ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)

                            Text(viewModel.isPaired ? "Paired with \(partnerName)" : "Sync music with \(partnerName)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    // Top-Right Pair / Unpair Button
                    Button {
                        Task {
                            await viewModel.handlePairUnpairButton(actorName: actorName)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.isPaired ? "link.badge.plus" : "link")
                                .font(.system(size: 11, weight: .bold))

                            Text(viewModel.isPaired ? "Unpair" : "Pair")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            viewModel.isPaired
                            ? AnyShapeStyle(Color.red.opacity(0.35))
                            : AnyShapeStyle(primaryGradient)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(viewModel.isPaired ? Color.red.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)

                // Segment Picker (All vs Liked)
                HStack(spacing: 12) {
                    TabPill(title: "All Songs (\(SongTrack.catalogue.count))", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }

                    TabPill(title: "Shared Liked (\(viewModel.likedTrackIds.count))", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Song List Feed
                if displayedTracks.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 38))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("No liked songs yet.")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Heart any song to build your shared couple playlist.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(displayedTracks) { track in
                                let isCurrent = viewModel.currentTrack.id == track.id
                                // Requirement 5: Pause button when currently playing
                                let isPlayingThis = isCurrent && viewModel.isPlaying && viewModel.isPaired

                                SongRowItem(
                                    track: track,
                                    isCurrentTrack: isCurrent,
                                    isPlayingThis: isPlayingThis,
                                    isLiked: viewModel.likedTrackIds.contains(track.id),
                                    onRowTap: {
                                        // Requirement 5: Tapping card opens details without changing song
                                        if viewModel.isPaired {
                                            viewModel.isPlayerPresented = true
                                        }
                                    },
                                    onPlayTap: {
                                        Task {
                                            await viewModel.handleRowPlayTap(track: track, actorName: actorName)
                                        }
                                    },
                                    onLikeToggle: {
                                        Task {
                                            await viewModel.toggleLike(trackId: track.id, userName: actorName)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                        .padding(.bottom, (viewModel.isPaired || viewModel.isPlaying) ? 80 : 20)
                    }
                }
            }

            // Persistent Mini-Player Bar
            if viewModel.isPaired || viewModel.isPlaying {
                Button {
                    viewModel.isPlayerPresented = true
                } label: {
                    HStack(spacing: 12) {
                        Group {
                            if let uiImage = UIImage(named: viewModel.currentTrack.coverImageName) ?? UIImage(named: "Songs-Cover/\(viewModel.currentTrack.coverImageName)") {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(viewModel.currentTrack.coverImageName)
                                    .resizable()
                                    .scaledToFill()
                            }
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.currentTrack.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(viewModel.isPlaying ? "Playing in sync..." : "Paused")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }

                        Spacer()

                        Button {
                            Task { await viewModel.togglePlayPause(actorName: actorName) }
                        } label: {
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.15), in: Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 10, y: 5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// Song Row Component
private struct SongRowItem: View {
    let track: SongTrack
    let isCurrentTrack: Bool
    let isPlayingThis: Bool
    let isLiked: Bool
    let onRowTap: () -> Void
    let onPlayTap: () -> Void
    let onLikeToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let uiImage = UIImage(named: track.coverImageName) ?? UIImage(named: "Songs-Cover/\(track.coverImageName)") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(track.coverImageName)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isCurrentTrack ? Color(red: 0.95, green: 0.25, blue: 0.42) : Color.white.opacity(0.1), lineWidth: isCurrentTrack ? 1.5 : 1)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrentTrack ? Color(red: 0.95, green: 0.25, blue: 0.42) : .white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(track.artist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))
                    Text(track.formattedDuration)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onRowTap)

            Spacer()

            Button(action: onLikeToggle) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundStyle(isLiked ? Color(red: 0.95, green: 0.25, blue: 0.42) : .white.opacity(0.3))
                    .frame(width: 34, height: 34)
            }

            Button(action: onPlayTap) {
                Image(systemName: isPlayingThis ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        isCurrentTrack
                        ? AnyShapeStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        : AnyShapeStyle(Color.white.opacity(0.12)),
                        in: Circle()
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    isCurrentTrack
                    ? Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.12)
                    : Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isCurrentTrack
                            ? Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.5)
                            : Color.white.opacity(0.08),
                            lineWidth: isCurrentTrack ? 1.5 : 1
                        )
                )
        )
    }
}

private struct TabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected
                    ? Color(red: 0.95, green: 0.25, blue: 0.42)
                    : Color.white.opacity(0.08)
                )
                .clipShape(Capsule())
        }
    }
}
