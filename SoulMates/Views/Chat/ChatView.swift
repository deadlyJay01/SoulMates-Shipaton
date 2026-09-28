//
//  ChatView.swift
//  SoulMates
//

import SwiftUI
import AVFoundation

struct ChatView: View {
    @EnvironmentObject private var storage: AppStorageManager
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var hasPartner: Bool {
        let name = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.lowercased() != "partner"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            if !hasPartner {
                UnpairedPlaceholderView(
                    title: "Waiting for Your SoulMate",
                    subtitle: "Pair with your partner to start sending disappearing text and voice messages."
                )
            } else {
                VStack(spacing: 0) {
                    // Header Bar
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(storage.partnerName.isEmpty ? "Your SoulMate" : storage.partnerName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 10, weight: .bold))
                            Text("Messages & voice vanish after 24h")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.white.opacity(0.55))
                        }

                        Spacer()

                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial.opacity(0.85))

                    // Chat Messages Feed
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if viewModel.messages.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.25))

                            Text("No active messages")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.7))

                            Text("Send a quick text or voice note. It will quietly vanish in 24 hours.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.messages.reversed()) { message in
                                    let isMe = message.senderId == viewModel.currentUserId
                                    MessageBubble(
                                        message: message,
                                        isMe: isMe,
                                        gradient: gradient,
                                        audioManager: viewModel.audioManager
                                    )
                                    .id(message.id)
                                    .scaleEffect(x: 1, y: -1)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                        }
                        .scaleEffect(x: 1, y: -1)
                    }

                    // Dedicated Input Bar
                    ChatBottomInputBar(
                        viewModel: viewModel,
                        audioManager: viewModel.audioManager,
                        isInputFocused: $isInputFocused,
                        gradient: gradient
                    )
                }
            }
        }
        .task {
            if hasPartner {
                await viewModel.initializeChat()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - Dedicated Input Bar Component
struct ChatBottomInputBar: View {
    @ObservedObject var viewModel: ChatViewModel
    @ObservedObject var audioManager: AudioRecorderManager
    @FocusState.Binding var isInputFocused: Bool
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: 10) {
            if audioManager.isRecording {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)

                    Text(formatDuration(audioManager.recordingDuration))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)

                    Text("Recording...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            audioManager.cancelRecording()
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            audioManager.stopRecordingForReview()
                        }
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())

            } else if audioManager.isReviewing {
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            audioManager.cancelRecording()
                        }
                    } label: {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }

                    Button {
                        audioManager.togglePreviewPlayback()
                    } label: {
                        Image(systemName: audioManager.isPreviewPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }

                    GeometryReader { geo in
                        let progress: CGFloat = {
                            let val = audioManager.previewProgress
                            guard !val.isNaN, !val.isInfinite else { return 0 }
                            return CGFloat(min(1.0, max(0.0, val)))
                        }()

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)

                            Capsule()
                                .fill(gradient)
                                .frame(width: max(0, geo.size.width * progress), height: 4)
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 16)

                    Text(formatDuration(audioManager.recordingDuration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))

                    Button {
                        if let fileURL = audioManager.finalizeRecordingForSend() {
                            Task {
                                await viewModel.sendVoiceNote(fileURL: fileURL)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(gradient)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())

            } else {
                TextField("Send a disappearing message...", text: $viewModel.messageText)
                    .submitLabel(.done)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
                    .focused($isInputFocused)

                if viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        handleInstantRecordTap()
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.sendMessage()
                        }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(gradient)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.95))
    }

    private func handleInstantRecordTap() {
        isInputFocused = false

        let permission = AVAudioSession.sharedInstance().recordPermission
        switch permission {
        case .granted:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                audioManager.startRecording()
            }
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                if granted {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            audioManager.startRecording()
                        }
                    }
                }
            }
        case .denied:
            print("Microphone access is denied in Settings.")
        @unknown default:
            break
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: ChatMessage
    let isMe: Bool
    let gradient: LinearGradient
    @ObservedObject var audioManager: AudioRecorderManager

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 50) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if message.isVoiceNote, let audioURL = message.voiceAudioURL {
                    HStack(spacing: 12) {
                        Button {
                            audioManager.playAudio(from: audioURL, messageId: message.id)
                        } label: {
                            Image(systemName: (audioManager.playingMessageId == message.id && audioManager.isPlaying) ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.black.opacity(0.25))
                                .clipShape(Circle())
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            GeometryReader { geo in
                                let progress: CGFloat = {
                                    let val = audioManager.playbackProgress
                                    guard !val.isNaN, !val.isInfinite else { return 0 }
                                    return CGFloat(min(1.0, max(0.0, val)))
                                }()

                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(height: 4)

                                    if audioManager.playingMessageId == message.id {
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: max(0, geo.size.width * progress), height: 4)
                                    }
                                }
                            }
                            .frame(height: 4)

                            HStack {
                                Image(systemName: "waveform")
                                    .font(.system(size: 10))
                                Text("Voice Note")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                Spacer()
                            }
                            .foregroundStyle(.white.opacity(0.75))
                        }
                        .frame(width: 130)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isMe
                        ? AnyShapeStyle(gradient)
                        : AnyShapeStyle(Color.white.opacity(0.12))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    Text(message.content)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            isMe
                            ? AnyShapeStyle(gradient)
                            : AnyShapeStyle(Color.white.opacity(0.12))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Text(message.timeFormatted)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.horizontal, 4)
            }

            if !isMe { Spacer(minLength: 50) }
        }
    }
}
