//
//  CoupleSelfieView.swift
//  SoulMates
//

import SwiftUI
import PhotosUI
import Supabase
import Combine
import AVFoundation

struct CoupleSelfieView: View {
    @StateObject private var viewModel = SelfieViewModel()
    @EnvironmentObject private var storage: AppStorageManager

    @State private var selectedItem: PhotosPickerItem? = nil
    
    // Captured & Flow Image States
    @State private var imageToProcess: UIImage? = nil
    @State private var pendingCaption: String = ""

    // Modals
    
    @State private var showSourceDialog: Bool = false
    @State private var showPhotoLibrary: Bool = false
    @State private var showCropAndConfirm: Bool = false
    @State private var pulseAura = false
    @State private var showCameraDeniedAlert: Bool = false

    // Memories State
    @State private var isSavingToMemories: Bool = false
    @State private var showMemorySavedAlert: Bool = false
    @State private var memoryAlertMessage: String = ""

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var hasPartner: Bool {
        !storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var actionButtonTitle: String {
        viewModel.mySelfie != nil ? "Change Photo" : "Add Snapshot"
    }

    private var currentPartnerSelfieUrl: String {
        viewModel.partnerSelfie?.imageUrl ?? ""
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let cardWidth = max(0, geo.size.width - 40)

                ZStack {
                    Color.black.ignoresSafeArea()
                    onBoarding_Background()
                        .ignoresSafeArea()

                    if !hasPartner {
                        unpairedView
                    } else {
                        VStack(spacing: 14) {
                            headerBar

                            if viewModel.showNudgeReceivedBanner {
                                nudgeAlertBanner
                            }

                            heroStage(cardWidth: cardWidth)

                            controlsRow

                            bottomActions

                            Spacer()
                        }
                    }
                }
            }
            .confirmationDialog("Upload Today's Glimpse", isPresented: $showSourceDialog, titleVisibility: .visible) {
                Button("Live Camera", systemImage: "camera") {
                    handleCameraTap()
                }
                Button("Photo Library", systemImage: "photo.on.rectangle") {
                    showPhotoLibrary = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Camera Access Needed", isPresented: $showCameraDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("SoulMates requires camera access so you can take and share daily snapshots with your partner. Please allow access in Settings.")
            }
            .photosPicker(isPresented: $showPhotoLibrary, selection: $selectedItem, matching: .images)
            // Photo Library flow only (crop + confirm)
           
            .fullScreenCover(isPresented: $showCropAndConfirm) {
                if let rawImage = imageToProcess {
                    SelfieCropAndConfirmFlowView(
                        originalImage: rawImage,
                        caption: $pendingCaption,
                        isUpdating: viewModel.mySelfie != nil,
                        partnerName: storage.partnerName,
                        isUploading: viewModel.isUploading,
                        onCancel: {
                            showCropAndConfirm = false
                            imageToProcess = nil
                        },
                        onConfirm: { finalCroppedImage in
                            Task {
                                let success = await viewModel.uploadSelfie(image: finalCroppedImage, caption: pendingCaption)
                                if success {
                                    showCropAndConfirm = false
                                    imageToProcess = nil
                                }
                            }
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            .alert(memoryAlertMessage, isPresented: $showMemorySavedAlert) {
                Button("Awesome!", role: .cancel) { }
            }
            .onChange(of: selectedItem) { newItem in
                handlePhotoSelection(newItem)
            }
            .onChange(of: currentPartnerSelfieUrl) { newUrl in
                if !newUrl.isEmpty {
                    syncPartnerSelfieToWidget()
                }
            }
            .task {
                await viewModel.start()
                syncPartnerSelfieToWidget()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulseAura = true
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
        }
    }

    // Safe Flow Triggers

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.imageToProcess = uiImage.fixedOrientation()
                    self.pendingCaption = viewModel.mySelfie?.caption ?? ""
                    self.selectedItem = nil
                    self.showCropAndConfirm = true
                }
            }
        }
    }

    // Widget Synchronization
    private func syncPartnerSelfieToWidget() {
        guard let urlString = viewModel.partnerSelfie?.imageUrl,
              let url = URL(string: urlString) else { return }

        Task(priority: .background) {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    WidgetSharedData.saveImage(image, fileName: WidgetSharedData.partnerSelfieFile)
                }
            } catch {
                print("Failed to sync partner selfie to widget:", error)
            }
        }
    }

    // Camera Permission Handler
    private func handleCameraTap() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            presentLiveCameraFlow()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.presentLiveCameraFlow()
                    }
                }
            }

        case .denied, .restricted:
            showCameraDeniedAlert = true

        @unknown default:
            break
        }
    }
    
    private func presentLiveCameraFlow() {
        guard let presentingController = UIApplication.shared.topMostViewController() else { return }

        let flow = LiveCameraFlowController()
        flow.modalPresentationStyle = .fullScreen
        flow.partnerName = storage.partnerName
        flow.isUpdating = viewModel.mySelfie != nil
        flow.onUpload = { image, caption in
            await viewModel.uploadSelfie(image: image, caption: caption)
        }

        presentingController.present(flow, animated: true)
    }

    // Subviews

    private var unpairedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.2),
                                Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Image(systemName: "heart.and.sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(primaryGradient)
            }

            VStack(spacing: 6) {
                Text("Waiting for Your SoulMate")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Pair with your partner to share unscripted daily snapshots and build your memory vault together.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            NavigationLink {
                InvitePartnerView()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 13, weight: .bold))
                    Text("Connect Partner")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 46)
                .background(Capsule().fill(primaryGradient))
                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 10, y: 3)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Soul Glimpse")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("Your unscripted daily connection")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                Text(viewModel.timeRemainingString)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.12)))
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private var nudgeAlertBanner: some View {
        HStack(spacing: 8) {
            Text("💌")
            Text("\(storage.partnerName) is asking for your selfie!")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation { viewModel.showNudgeReceivedBanner = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }

    private func heroStage(cardWidth: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))

            if viewModel.bothUploaded, let partner = viewModel.partnerSelfie, let url = URL(string: partner.imageUrl) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        ProgressView().tint(.white)
                    }
                }
            } else if viewModel.partnerSelfie != nil && !viewModel.bothUploaded {
                lockedPartnerStage
            } else {
                emptyPartnerStage
            }

            partnerStageBadge
        }
        .frame(width: cardWidth, height: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
        )
        .padding(.horizontal, 20)
    }

    private var lockedPartnerStage: some View {
        ZStack {
            Color.purple.opacity(0.25).blur(radius: 20)
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 56, height: 56)
                    .overlay(Image(systemName: "lock.shield.fill").font(.system(size: 26)).foregroundStyle(.yellow))

                Text("\(storage.partnerName) posted!")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("Drop yours below to uncover both.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var emptyPartnerStage: some View {
        VStack(spacing: 12) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(red: 0.95, green: 0.25, blue: 0.42).opacity(pulseAura ? 0.6 : 0.2), lineWidth: 2)
                    .frame(width: 76, height: 76)
                    .scaleEffect(pulseAura ? 1.1 : 0.95)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 62, height: 62)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
            }

            VStack(spacing: 4) {
                Text("Waiting on \(storage.partnerName)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Their snapshot will light up this frame.")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

            if !viewModel.nudgeSentToday {
                Button {
                    Task { await viewModel.sendPhotoNudge() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 11))
                        Text("Send a Nudge")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
            } else {
                Text("Nudge sent ✨")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var partnerStageBadge: some View {
        HStack {
            Text(storage.partnerName)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Spacer()

            if let caption = viewModel.partnerSelfie?.caption, !caption.isEmpty, viewModel.bothUploaded {
                Text("“\(caption)”")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showSourceDialog = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.shutter.button.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(actionButtonTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if let mine = viewModel.mySelfie, let caption = mine.caption, !caption.isEmpty {
                    Text("“\(caption)”")
                        .font(.system(size: 12, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                } else {
                    Text("Tap to capture or update today's shared glimpse.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 4)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 122)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))

                if let mine = viewModel.mySelfie, let url = URL(string: mine.imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            ProgressView().tint(.white)
                        }
                    }
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.35))
                        Text("Your Frame")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("You")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(8)
            }
            .frame(width: 122, height: 122)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        viewModel.mySelfie != nil ? Color(red: 0.95, green: 0.25, blue: 0.42) : Color.white.opacity(0.12),
                        lineWidth: 1.5
                    )
            )
        }
        .padding(.horizontal, 20)
    }

    private var bottomActions: some View {
        Group {
            if let mySelfie = viewModel.mySelfie {
                let openTimesText = mySelfie.viewCount == 1 ? "1 time" : "\(mySelfie.viewCount) times"

                VStack(spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                            Text("Opened \(openTimesText) by \(storage.partnerName)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        Spacer()

                        if viewModel.bothUploaded {
                            Text("✨ Both Revealed")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())

                    if viewModel.bothUploaded {
                        Button {
                            saveBothToMemories()
                        } label: {
                            HStack(spacing: 8) {
                                if isSavingToMemories {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "photo.stack.fill")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("Add to Memories")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Capsule().fill(primaryGradient))
                            .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 8, y: 3)
                        }
                        .disabled(isSavingToMemories)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // Save to Memories
    private func saveBothToMemories() {
        guard let myUrl = viewModel.mySelfie?.imageUrl,
              let partnerUrl = viewModel.partnerSelfie?.imageUrl else { return }

        isSavingToMemories = true

        Task {
            do {
                if let cid = try await SupabaseService.shared.fetchCurrentCoupleId() {
                    let uploader = storage.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Partner" : storage.userName
                    let desc = viewModel.mySelfie?.caption?.isEmpty == false
                        ? (viewModel.mySelfie?.caption ?? "Daily Soul Glimpse moment.")
                        : "Daily Soul Glimpse moment."

                    try await SupabaseService.shared.createMemory(
                        coupleId: cid,
                        uploaderName: uploader,
                        date: Date(),
                        description: desc,
                        photoUrls: [myUrl, partnerUrl]
                    )

                    await MainActor.run {
                        self.memoryAlertMessage = "Added to memories! 💖"
                        self.showMemorySavedAlert = true
                        self.isSavingToMemories = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.memoryAlertMessage = "Failed to save: \(error.localizedDescription)"
                    self.showMemorySavedAlert = true
                    self.isSavingToMemories = false
                }
            }
        }
    }
}


// UNIFIED CROP & CONFIRM FLOW CONTAINER

struct SelfieCropAndConfirmFlowView: View {
    let originalImage: UIImage
    @Binding var caption: String
    let isUpdating: Bool
    let partnerName: String
    let isUploading: Bool
    let onCancel: () -> Void
    let onConfirm: (UIImage) -> Void

    @State private var croppedImage: UIImage? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let cropped = croppedImage {
                // Step 2: Confirmation & Caption Sheet
                PhotoConfirmationView(
                    image: cropped,
                    caption: $caption,
                    isUpdating: isUpdating,
                    partnerName: partnerName,
                    isUploading: isUploading,
                    onBackToCrop: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            croppedImage = nil
                        }
                    },
                    onCancel: onCancel,
                    onConfirm: {
                        onConfirm(cropped)
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                // Step 1: Cropper
                SquareImageCropper(
                    image: originalImage,
                    onCancel: onCancel,
                    onCrop: { result in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            croppedImage = result
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
    }
}

// Confirmation View (Step 2 inside container)
private struct PhotoConfirmationView: View {
    let image: UIImage
    @Binding var caption: String
    let isUpdating: Bool
    let partnerName: String
    let isUploading: Bool
    let onBackToCrop: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @FocusState private var isCaptionFocused: Bool

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    isCaptionFocused = false
                }

            VStack(spacing: 16) {
                // Top Navigation Bar
                HStack {
                    Button(action: onBackToCrop) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Recrop")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                    }

                    Spacer()

                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)

                VStack(spacing: 6) {
                    Text(isUpdating ? "Update Daily Glimpse" : "Post Today's Glimpse")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Visible to \(partnerName) for 24 hours")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 270, height: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)

                // Caption TextField
                TextField("Whisper a tiny thought (optional)...", text: $caption)
                    
                    .focused($isCaptionFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isCaptionFocused = false
                    }
                    .font(.system(size: 14, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    

                Spacer()
                
                HStack(spacing: 14) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .disabled(isUploading)

                    Button(action: onConfirm) {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: isUpdating ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.up.heart.fill")
                                    .font(.system(size: 15))
                                Text(isUpdating ? "Update Photo" : "Share Now")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(primaryGradient))
                        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 8, y: 3)
                    }
                    .disabled(isUploading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}


// Live Camera Flow (fully UIKit, no SwiftUI modal involved)

final class LiveCameraFlowController: UIViewController {
    var partnerName: String = ""
    var isUpdating: Bool = false
    /// Runs the actual Supabase upload. Return true on success.
    var onUpload: (UIImage, String) async -> Bool = { _, _ in false }

    private var hasPresentedCamera = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPresentedCamera else { return }
        hasPresentedCamera = true
        presentCamera()
    }

    private func presentCamera() {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                picker.cameraDevice = .front
            }
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }

    private func showConfirmation(with rawImage: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let fixedImage = rawImage.fixedOrientation()
            DispatchQueue.main.async {
                guard let self else { return }
                let confirmView = LiveCaptureConfirmView(
                    image: fixedImage,
                    isUpdating: self.isUpdating,
                    partnerName: self.partnerName,
                    onCancel: { [weak self] in
                        self?.finish()
                    },
                    onConfirm: { [weak self] caption, setUploading in
                        guard let self else { return }
                        Task {
                            let success = await self.onUpload(fixedImage, caption)
                            await MainActor.run {
                                if success {
                                    self.finish()
                                } else {
                                    setUploading(false)
                                }
                            }
                        }
                    }
                )
                let hosting = UIHostingController(rootView: confirmView)
                hosting.modalPresentationStyle = .fullScreen
                hosting.view.backgroundColor = .black
                self.present(hosting, animated: true)
            }
        }
    }

    private func finish() {
        presentingViewController?.dismiss(animated: true)
    }
}

extension LiveCameraFlowController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        let image = info[.originalImage] as? UIImage
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            if let image = image {
                self.showConfirmation(with: image)
            } else {
                self.finish()
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.finish()
        }
    }
}


private struct LiveCaptureConfirmView: View {
    let image: UIImage
    let isUpdating: Bool
    let partnerName: String
    let onCancel: () -> Void
    let onConfirm: (String, @escaping (Bool) -> Void) -> Void

    @State private var caption: String = ""
    @State private var isUploading = false
    @FocusState private var isCaptionFocused: Bool

    private let primaryGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    isCaptionFocused = false
                }

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .disabled(isUploading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 50)

                VStack(spacing: 6) {
                    Text(isUpdating ? "Update Daily Glimpse" : "Post Today's Glimpse")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Visible to \(partnerName) for 24 hours")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300, maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.4), radius: 12, y: 6)
                    .padding(.top, 8)

                TextField("Whisper a tiny thought (optional)...", text: $caption)
                    
                    .focused($isCaptionFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isCaptionFocused = false
                    }
                    .font(.system(size: 14, design: .rounded))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)

                Spacer()

                HStack(spacing: 14) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .disabled(isUploading)

                    Button {
                        isUploading = true
                        onConfirm(caption) { stillUploading in
                            isUploading = stillUploading
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isUploading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: isUpdating ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.up.heart.fill")
                                    .font(.system(size: 15))
                                Text(isUpdating ? "Update Photo" : "Share Now")
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(primaryGradient))
                        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 8, y: 3)
                    }
                    .disabled(isUploading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
    }
}

// Finding the top-most view controller (needed to present LiveCameraFlowController)
private extension UIApplication {
    func topMostViewController() -> UIViewController? {
        let root = connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        return root?.topMostPresented()
    }
}

private extension UIViewController {
    func topMostPresented() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostPresented()
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostPresented()
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostPresented()
        }
        return self
    }
}

// UIImage Orientation Normalizer
private extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
