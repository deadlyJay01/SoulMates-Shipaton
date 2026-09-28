//
//  selectProfileImage_P4.swift
//  SoulMates
//
//  Created by Jay on 05/09/26.
//

import SwiftUI
import PhotosUI

struct CropImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct selectProfileImage_P4: View {
    @EnvironmentObject private var storage: AppStorageManager

    @State private var selectedImage: PhotosPickerItem?
    @State private var imageToCrop: CropImageWrapper?

    @State private var animateContent: Bool = false
    @State private var animateAura: Bool = false

    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.25, blue: 0.42),
            Color(red: 0.65, green: 0.22, blue: 0.88)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            onBoarding_Background()

            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select a profile picture")
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(.white)

                        Text("This will be shown to your better half 🫶🏻")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 10)

                    Spacer()
                }
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)

                Spacer()

                // Avatar Display & Picker Actions
                VStack(spacing: 34) {
                    ZStack {
                        if storage.hasProfileImage, let uiImage = UIImage(data: storage.profileImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 210, height: 210)
                                .clipShape(Circle())
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.35, green: 0.08, blue: 0.30).opacity(0.65),
                                                Color(red: 0.16, green: 0.06, blue: 0.22).opacity(0.85)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.28),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 20,
                                            endRadius: 90
                                        )
                                    )

                                Text("\(storage.userName.first.map(String.init) ?? "")")
                                    .font(.system(size: 88, weight: .black, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.85)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.4), radius: 10)
                            }
                            .frame(width: 210, height: 210)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .overlay {
                        Circle()
                            .stroke(accentGradient, lineWidth: 3)
                    }
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.55), .clear, .white.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(
                        color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(animateAura ? 0.45 : 0.25),
                        radius: animateAura ? 30 : 20,
                        x: 0,
                        y: 10
                    )
                    .shadow(
                        color: Color(red: 0.65, green: 0.22, blue: 0.88).opacity(animateAura ? 0.35 : 0.18),
                        radius: animateAura ? 38 : 26,
                        x: 0,
                        y: 16
                    )
                    .scaleEffect(animateContent ? 1.0 : 0.85)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.20), value: animateContent)
                    .id(storage.profileImageData)

                    // Photo Picker Buttons
                    VStack(spacing: 14) {
                        PhotosPicker(
                            selection: $selectedImage,
                            matching: .images
                        ) {
                            HStack(spacing: 10) {
                                Image(systemName: storage.hasProfileImage ? "arrow.triangle.2.circlepath.camera.fill" : "photo.badge.plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                                Text(storage.hasProfileImage ? "Change photo" : "Choose from photos")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 230, height: 48)
                            .background {
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                                    .background(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.25), .white.opacity(0.04)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            }
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        }
                        .buttonStyle(.plain)

                        if storage.hasProfileImage {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    storage.profileImageData = Data()
                                    storage.hasProfileImage = false
                                    selectedImage = nil
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 12))
                                    Text("Remove photo")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                }
                                .foregroundStyle(.red.opacity(0.85))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 14)
                                .background(Color.red.opacity(0.08), in: Capsule())
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .offset(y: animateContent ? 0 : 25)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.32), value: animateContent)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .onChange(of: selectedImage) { newPhotoItem in
            guard let newPhotoItem else { return }
            Task {
                if let data = try? await newPhotoItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        imageToCrop = CropImageWrapper(image: uiImage)
                    }
                }
            }
        }
        .sheet(item: $imageToCrop) { (wrapper: CropImageWrapper) in
            SquareImageCropper(
                image: wrapper.image,
                onCancel: {
                    imageToCrop = nil
                    selectedImage = nil
                },
                onCrop: { croppedImage in
                    if let jpegData = croppedImage.jpegData(compressionQuality: 0.85) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            storage.profileImageData = jpegData
                            storage.hasProfileImage = true
                        }
                    }
                    imageToCrop = nil
                }
            )
        }
        .onAppear {
            animateContent = true
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                animateAura = true
            }
        }
    }
}

#Preview {
    selectProfileImage_P4()
        .environmentObject(AppStorageManager())
}
