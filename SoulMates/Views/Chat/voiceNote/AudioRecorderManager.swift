//
//  AudioRecorderManager.swift
//  SoulMates
//

import Foundation
import AVFoundation
import Combine

final class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    // Recording States
    @Published var isRecording: Bool = false
    @Published var isReviewing: Bool = false
    @Published var recordingDuration: TimeInterval = 0

    // Local Preview Playback States
    @Published var isPreviewPlaying: Bool = false
    @Published var previewProgress: Double = 0

    // Chat Message Remote Playback States
    @Published var isPlaying: Bool = false
    @Published var playingMessageId: UUID? = nil
    @Published var playbackProgress: Double = 0

    private var audioRecorder: AVAudioRecorder?
    private var previewPlayer: AVAudioPlayer?
    private var remoteAudioPlayer: AVAudioPlayer?

    private var recordTimer: AnyCancellable?
    private var previewTimer: AnyCancellable?
    private var remoteProgressTimer: AnyCancellable?

    private var recordStartTime: Date?
    private(set) var recordedFileURL: URL?

    override init() {
        super.init()
    }

    // MARK: - Instant 0ms Recording Start
    func startRecording() {
        // 1. Instantly update UI on main thread
        self.isRecording = true
        self.isReviewing = false
        self.recordingDuration = 0
        let startTime = Date()
        self.recordStartTime = startTime

        stopPlayback()
        stopPreview()

        // 2. Real-time clock timer (Never freezes, independent of frame rate)
        recordTimer?.cancel()
        recordTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self = self, self.isRecording else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            self.recordingDuration = elapsed
            if elapsed >= 120 { // Cap at 2 minutes
                self.stopRecordingForReview()
            }
        }

        // 3. Configure hardware audio session in the background (prevents UI freeze)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("voice_note_\(UUID().uuidString).m4a")
        self.recordedFileURL = fileURL

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
                try session.setActive(true, options: .notifyOthersOnDeactivation)

                let settings: [String: Any] = [
                    AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                    AVSampleRateKey: 44100.0,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
                recorder.prepareToRecord()
                let started = recorder.record()

                DispatchQueue.main.async {
                    if started && self.isRecording {
                        recorder.delegate = self
                        self.audioRecorder = recorder
                    } else if !self.isRecording {
                        // User tapped stop before background setup finished
                        recorder.stop()
                    } else {
                        print("Audio recorder failed to start.")
                        self.cancelRecording()
                    }
                }
            } catch {
                print("Failed to start audio recording session:", error)
                DispatchQueue.main.async {
                    self.cancelRecording()
                }
            }
        }
    }

    // MARK: - Instant Stop & Review
    func stopRecordingForReview() {
        guard isRecording else { return }

        // 1. Immediately toggle UI state
        recordTimer?.cancel()
        recordTimer = nil

        self.isRecording = false
        self.isReviewing = true
        self.isPreviewPlaying = false
        self.previewProgress = 0

        // 2. Flush file and prepare preview player in the background
        let recorder = self.audioRecorder
        self.audioRecorder = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            recorder?.stop()

            guard let self = self, let url = self.recordedFileURL else { return }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                DispatchQueue.main.async {
                    player.delegate = self
                    self.previewPlayer = player
                }
            } catch {
                print("Failed to initialize preview player:", error)
            }
        }
    }

    // MARK: - Preview Playback
    func togglePreviewPlayback() {
        guard let player = previewPlayer else { return }

        if player.isPlaying {
            player.pause()
            previewTimer?.cancel()
            self.isPreviewPlaying = false
        } else {
            player.play()
            self.isPreviewPlaying = true

            previewTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                guard let self = self, let p = self.previewPlayer else { return }
                if p.duration > 0 {
                    self.previewProgress = p.currentTime / p.duration
                }
            }
        }
    }

    func stopPreview() {
        previewTimer?.cancel()
        previewTimer = nil
        previewPlayer?.stop()
        previewPlayer?.currentTime = 0
        isPreviewPlaying = false
        previewProgress = 0
    }

    // Discards the current recording completely
    func cancelRecording() {
        recordTimer?.cancel()
        recordTimer = nil
        stopPreview()

        let recorder = self.audioRecorder
        self.audioRecorder = nil

        self.isRecording = false
        self.isReviewing = false
        self.recordingDuration = 0

        let fileToClean = recordedFileURL
        recordedFileURL = nil

        DispatchQueue.global(qos: .utility).async {
            recorder?.stop()
            if let url = fileToClean {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // Called on "Send" tap
    func finalizeRecordingForSend() -> URL? {
        stopPreview()
        isRecording = false
        isReviewing = false
        let url = recordedFileURL
        recordedFileURL = nil
        return url
    }

    // MARK: - Remote Message Audio Playback
    func playAudio(from urlString: String, messageId: UUID) {
        if playingMessageId == messageId && isPlaying {
            stopPlayback()
            return
        }

        stopPlayback()
        stopPreview()

        guard let url = URL(string: urlString) else { return }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playback, mode: .default)
                        try session.setActive(true)

                        self.remoteAudioPlayer = try AVAudioPlayer(data: data)
                        self.remoteAudioPlayer?.delegate = self
                        self.remoteAudioPlayer?.play()
                        self.isPlaying = true
                        self.playingMessageId = messageId

                        self.remoteProgressTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().sink { [weak self] _ in
                            guard let self = self, let player = self.remoteAudioPlayer else { return }
                            if player.duration > 0 {
                                self.playbackProgress = player.currentTime / player.duration
                            }
                        }
                    } catch {
                        print("Failed to initialize remote player:", error)
                    }
                }
            } catch {
                print("Failed to download audio:", error)
            }
        }
    }

    func stopPlayback() {
        remoteProgressTimer?.cancel()
        remoteProgressTimer = nil
        remoteAudioPlayer?.stop()
        remoteAudioPlayer = nil
        isPlaying = false
        playingMessageId = nil
        playbackProgress = 0
    }

    // MARK: - Delegates
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == previewPlayer {
            stopPreview()
        } else {
            stopPlayback()
        }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Audio recording ended with an error flag.")
        }
    }
}
