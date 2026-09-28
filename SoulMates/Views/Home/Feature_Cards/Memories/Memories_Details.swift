//
//  Memories_Details.swift
//  SoulMates
//
//  Created by Jay on 19/09/26.
//

import SwiftUI
import Supabase

struct Memories_Details: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager

    @State private var memories: [CoupleMemory] = []
    @State private var coupleId: UUID? = nil
    @State private var isLoading: Bool = true
    @State private var hasNoCouple: Bool = false
    
    @State private var activeDetailMemory: CoupleMemory? = nil
    @State private var showAddSheet: Bool = false

    // Partner Alert & Sheet state
    @State private var showPartnerAlert: Bool = false
    @State private var showInviteSheet: Bool = false

    private var hasPartner: Bool {
        let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.lowercased() != "partner"
    }

    private func displayName(for memory: CoupleMemory) -> String {
        let currentUID = SupabaseService.shared.client.auth.currentUser?.id
        if let currentUID = currentUID, memory.uploadedBy == currentUID {
            let trimmed = storage.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "You" : trimmed
        } else {
            let trimmed = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Partner" : trimmed
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            if let selectedMemory = activeDetailMemory {
                DetailOdMemory(
                    memory: selectedMemory,
                    authorDisplayName: displayName(for: selectedMemory),
                    totalMemoriesCount: memories.count,
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeDetailMemory = nil
                        }
                    },
                    onDeleteSuccess: { deletedId in
                        withAnimation(.easeInOut(duration: 0.25)) {
                            memories.removeAll { $0.id == deletedId }
                            activeDetailMemory = nil
                        }
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                VStack(spacing: 0) {
                    // Header Bar
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.12), in: Circle())
                        }

                        Text("Memories")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white)

                        Spacer()

                        // Pink Capsule "+ Add" Button
                        Button {
                            if hasPartner && !hasNoCouple {
                                showAddSheet = true
                            } else {
                                showPartnerAlert = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Add")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.98, green: 0.32, blue: 0.52),
                                        Color(red: 0.88, green: 0.22, blue: 0.58)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .shadow(color: Color(red: 0.98, green: 0.32, blue: 0.52).opacity(0.4), radius: 6, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.white)
                        Spacer()
                    } else if hasNoCouple || !hasPartner {
                        UnpairedPlaceholderView(
                            title: "Save Memories Together",
                            subtitle: "Pair with your partner to start saving photos, dates, and milestone moments in your shared memory vault."
                        )
                    } else if memories.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 42))
                                .foregroundStyle(.white.opacity(0.35))
                            Text("No memories added yet.")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Capture your first moment together using the + Add button.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.25, blue: 0.42),
                                                Color(red: 0.55, green: 0.20, blue: 0.90)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 3)
                                    .padding(.leading, 31)
                                    .padding(.vertical, 20)

                                LazyVStack(spacing: 34) {
                                    ForEach(memories) { memory in
                                        memoryTimelineCard(memory)
                                    }

                                    Button {
                                        if hasPartner && !hasNoCouple {
                                            showAddSheet = true
                                        } else {
                                            showPartnerAlert = true
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus")
                                                .font(.system(size: 14, weight: .bold))
                                            Text("Add New Memory")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                        .foregroundStyle(.white.opacity(0.85))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.white.opacity(0.06))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                    .padding(.leading, 52)
                                    .padding(.trailing, 20)
                                    .padding(.top, 10)
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .partnerRequiredAlert(isPresented: $showPartnerAlert, featureName: "Memories", showInviteSheet: $showInviteSheet)
        .sheet(isPresented: $showAddSheet) {
            AddMemorySheet(coupleId: coupleId) { newMemory in
                withAnimation(.spring()) {
                    memories.append(newMemory)
                    memories.sort { $0.parsedDate > $1.parsedDate }
                }
            }
        }
        .task {
            await loadMemories()
        }
    }

    @ViewBuilder
    private func memoryTimelineCard(_ memory: CoupleMemory) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color(red: 0.95, green: 0.25, blue: 0.42))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42), radius: 4)
                .padding(.leading, 26)
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(displayName(for: memory))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(memory.displayDateFormatted)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                let previewPhotos = Array(memory.photoUrls.prefix(6))

                GeometryReader { geo in
                    let spacing: CGFloat = 8
                    let itemSize = max(0, (geo.size.width - (spacing * 2)) / 3)
                    let gridColumns = [
                        GridItem(.fixed(itemSize), spacing: spacing, alignment: .leading),
                        GridItem(.fixed(itemSize), spacing: spacing, alignment: .leading),
                        GridItem(.fixed(itemSize), spacing: spacing, alignment: .leading)
                    ]

                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: spacing) {
                        ForEach(previewPhotos, id: \.self) { imageRef in
                            MemoryThumbnail(source: imageRef, size: itemSize)
                        }
                    }
                }
                .frame(
                    height: {
                        let screenWidth = UIScreen.main.bounds.width
                        let availableWidth = screenWidth - 92
                        let calculatedItemSize = (availableWidth - 16) / 3
                        let rowCount: CGFloat = previewPhotos.count > 3 ? 2 : 1
                        return (calculatedItemSize * rowCount) + (rowCount > 1 ? 8 : 0)
                    }()
                )

                HStack(alignment: .bottom, spacing: 12) {
                    if let desc = memory.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(desc)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Spacer()
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            activeDetailMemory = memory
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("More")
                                .font(.system(size: 12, weight: .bold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Color(red: 0.98, green: 0.35, blue: 0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.1), in: Capsule())
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.45))
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.45), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
            .padding(.trailing, 16)
        }
    }

    private func loadMemories() async {
        guard hasPartner else {
            self.hasNoCouple = true
            self.isLoading = false
            return
        }

        isLoading = true
        do {
            if let cid = try await SupabaseService.shared.fetchCurrentCoupleId() {
                self.coupleId = cid
                self.hasNoCouple = false
                self.memories = try await SupabaseService.shared.fetchMemories(for: cid)
            } else {
                self.hasNoCouple = true
            }
        } catch {
            print("Error loading memories:", error)
            self.hasNoCouple = true
        }
        isLoading = false
    }
}

// MARK: - Reusable Image Handler
struct MemoryThumbnail: View {
    let source: String
    var size: CGFloat? = nil

    private var isRemoteURL: Bool {
        source.hasPrefix("http://") || source.hasPrefix("https://")
    }

    var body: some View {
        if !isRemoteURL, let uiImage = UIImage(named: source) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else if let url = URL(string: source) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                case .empty:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: size, height: size)
                default:
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(.white.opacity(0.35))
                        )
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: size, height: size)
        }
    }
}
