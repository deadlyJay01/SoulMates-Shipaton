//
//  DetailOdMemory.swift
//  SoulMates
//
//  Created by Jay on 19/09/26.
//

import SwiftUI
import Supabase

struct DetailOdMemory: View {
    let memory: CoupleMemory
    let authorDisplayName: String
    let totalMemoriesCount: Int
    let onBack: () -> Void
    let onDeleteSuccess: (UUID) -> Void

    @State private var showDeleteConfirmation: Bool = false
    @State private var isDeleting: Bool = false
    
    // Full-screen viewer state
    @State private var selectedFullScreenIndex: Int? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            VStack(spacing: 0) {
                // Header: Back Button + Author & Date
                HStack(spacing: 12) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(authorDisplayName)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(.white)

                        Text("Total: \(totalMemoriesCount) memories")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    Text(memory.displayDateFormatted)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Image Gallery (2-column layout)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(memory.photoUrls.enumerated()), id: \.offset) { index, source in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedFullScreenIndex = index
                                    }
                                } label: {
                                    Group {
                                        if UIImage(named: source) != nil {
                                            Image(source)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 155)
                                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        } else {
                                            AsyncImage(url: URL(string: source)) { phase in
                                                switch phase {
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(height: 155)
                                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                                case .empty:
                                                    Color.white.opacity(0.05)
                                                        .frame(height: 155)
                                                default:
                                                    Color.white.opacity(0.05)
                                                        .frame(height: 155)
                                                        .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.3)))
                                                }
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Description Section
                        if let desc = memory.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(desc)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(4)
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }

                        // Bottom Action: Delete
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack(spacing: 8) {
                                if isDeleting {
                                    ProgressView()
                                        .tint(.red)
                                } else {
                                    Image(systemName: "trash.fill")
                                    Text("Remove Memory")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.12), in: Capsule())
                            .overlay(Capsule().stroke(Color.red.opacity(0.3), lineWidth: 1))
                        }
                        .disabled(isDeleting)
                        .padding(.top, 16)
                    }
                    .padding(20)
                }
            }

            // MARK: - Full-Screen Swipeable Gallery Overlay
            if let currentIndex = selectedFullScreenIndex {
                FullScreenImageGallery(
                    photos: memory.photoUrls,
                    initialIndex: currentIndex,
                    onDismiss: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedFullScreenIndex = nil
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .zIndex(10)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "Delete this memory?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await SupabaseService.shared.deleteMemory(id: memory.id)
                        onDeleteSuccess(memory.id)
                    } catch {
                        print("Failed to delete memory:", error)
                        isDeleting = false
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone. Once deleted, this memory and all its photos are gone forever.")
        }
    }
}

// MARK: - Full Screen Gallery View
struct FullScreenImageGallery: View {
    let photos: [String]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var activeIndex: Int = 0

    init(photos: [String], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _activeIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Page Swiper
            TabView(selection: $activeIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, source in
                    ZStack {
                        if UIImage(named: source) != nil {
                            Image(source)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            AsyncImage(url: URL(string: source)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                default:
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                        }
                    }
                    .tag(index)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Top Bar: Close Button & Page Indicator
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.18), in: Circle())
                    }

                    Spacer()

                    Text("\(activeIndex + 1) / \(photos.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.12), in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer()
            }
        }
    }
}
