//
//  AddMemorySheet.swift
//  SoulMates
//
//  Created by Jay on 19/09/26.
//

import SwiftUI
import PhotosUI
import Supabase

struct AddMemorySheet: View {
    let coupleId: UUID?
    let onCreated: (CoupleMemory) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var memoryDate: Date = Date()
    @State private var description: String = ""
    @State private var isUploading: Bool = false
    @State private var errorMessage: String? = nil

    // Shared reusable theme stroke modifier
    private var themeStroke: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.55),
                        Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.25)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // 1. Photos Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PHOTOS (MIN 1, MAX 10)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(1.2)

                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 16, weight: .bold))
                                    Text(selectedImages.isEmpty ? "Select Photos" : "Change Photos (\(selectedImages.count) selected)")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(themeStroke)
                            }
                            .onChange(of: selectedItems) { newItems in
                                Task {
                                    selectedImages.removeAll()
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let img = UIImage(data: data) {
                                            selectedImages.append(img)
                                        }
                                    }
                                }
                            }

                            if !selectedImages.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(0..<selectedImages.count, id: \.self) { idx in
                                            Image(uiImage: selectedImages[idx])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 72, height: 72)
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }

                        // 2. Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MEMORY DATE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(1.2)

                            HStack {
                                DatePicker("", selection: $memoryDate, in: ...Date(), displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.6),
                                                        Color(red: 0.65, green: 0.22, blue: 0.88).opacity(0.3)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )

                                Spacer()
                            }
                        }
                        // 3. Description (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION (OPTIONAL)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(1.2)

                            TextField("Write a sweet note about this day...", text: $description, axis: .vertical)
                                .submitLabel(.done)
                                .lineLimit(3...6)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(themeStroke)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.red)
                        }

                        // 4. Save Button
                        Button {
                            uploadAndSave()
                        } label: {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Memory")
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.25, blue: 0.42),
                                        Color(red: 0.65, green: 0.22, blue: 0.88)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                        }
                        .disabled(selectedImages.isEmpty || isUploading)
                        .opacity(selectedImages.isEmpty ? 0.5 : 1.0)
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private func uploadAndSave() {
        guard let cid = coupleId, !selectedImages.isEmpty else { return }
        isUploading = true
        errorMessage = nil

        Task {
            do {
                let photoUrls = try await SupabaseService.shared.uploadMemoryPhotos(images: selectedImages, coupleId: cid)
                let uploader = storage.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Partner" : storage.userName
                
                try await SupabaseService.shared.createMemory(
                    coupleId: cid,
                    uploaderName: uploader,
                    date: memoryDate,
                    description: description,
                    photoUrls: photoUrls
                )
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let dateStr = formatter.string(from: memoryDate)

                let currentUID = SupabaseService.shared.client.auth.currentUser?.id ?? UUID()

                let localMemory = CoupleMemory(
                    id: UUID(),
                    coupleId: cid,
                    uploadedBy: currentUID,
                    uploaderName: uploader,
                    memoryDate: dateStr,
                    description: description,
                    photoUrls: photoUrls,
                    createdAt: ISO8601DateFormatter().string(from: Date())
                )

                await MainActor.run {
                    onCreated(localMemory)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to upload memory: \(error.localizedDescription)"
                    self.isUploading = false
                }
            }
        }
    }
}
