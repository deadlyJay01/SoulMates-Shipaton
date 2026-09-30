//
//  notes_Profile-Home.swift
//  SoulMates
//
//  Created by Jay on 03/09/26.
//

import SwiftUI
import Supabase

struct notes_Profile_Home: View {
    @EnvironmentObject private var storage: AppStorageManager
    var HasPartner: Bool
    var onAddPartnerTap: (() -> Void)? = nil

    // Notes State
    @State private var myNoteText: String? = nil
    @State private var partnerNoteText: String? = nil
    @State private var coupleId: UUID? = nil

    // Realtime State
    @State private var notesChannel: RealtimeChannelV2?
    @State private var isSubscribed: Bool = false

    // Alert Input State
    @State private var showAddNoteAlert: Bool = false
    @State private var inputNote: String = ""
    @State private var isSaving: Bool = false

    // Partner Required Alert State
    @State private var showPartnerAlert: Bool = false
    @State private var showInviteSheet: Bool = false

    // MARK: - Dynamic Prompts
    private var randomCrazyPrompt: String {
        let name = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your partner" : storage.partnerName
        let prompts = [
            "Whisper a secret to \(name)... 🤫",
            "Drop a crazy dare for \(name) 😈",
            "Surprise \(name) with a sweet craving 🍦",
            "Leave a little hint for \(name) 👀",
            "Tell \(name) what you're plotting... 💌",
            "Send \(name) a 24-hour love spark ✨"
        ]
        return prompts.randomElement() ?? "Tell \(name) something crazy..."
    }

    var body: some View {
        VStack(spacing: 8) {
            // Notes row
            HStack(alignment: .bottom, spacing: 14) {
                // MARK: - Left Column (User Note / Add Note)
                Button {
                    if HasPartner {
                        inputNote = myNoteText ?? ""
                        showAddNoteAlert = true
                    } else {
                        showPartnerAlert = true
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(displayMyNote)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white)
                                    .shadow(color: .white.opacity(0.15), radius: 6, y: 2)
                            )

                        VStack(spacing: 3) {
                            Circle().fill(Color.white).frame(width: 7, height: 7)
                            Circle().fill(Color.white.opacity(0.85)).frame(width: 4, height: 4).offset(x: 5)
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                // MARK: - Right Column (Partner Note)
                VStack(spacing: 4) {
                    Text(displayPartnerNote)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .white.opacity(0.15), radius: 6, y: 2)
                        )

                    VStack(spacing: 3) {
                        Circle().fill(Color.white).frame(width: 7, height: 7)
                        Circle().fill(Color.white.opacity(0.85)).frame(width: 4, height: 4).offset(x: -5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)

            // Center Avatars with onAddPartnerTap hook
            CoupleImage_Home(avatarSize: 100, onAddPartnerTap: onAddPartnerTap)
                .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .partnerRequiredAlert(
            isPresented: $showPartnerAlert,
            featureName: "Love Notes",
            showInviteSheet: $showInviteSheet
        )
        .alert(myNoteText == nil ? "Drop a Spark 💭" : "Edit Note ✏️", isPresented: $showAddNoteAlert) {
            let partner = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your partner" : storage.partnerName
            TextField("Tell \(partner) something crazy... 💌", text: $inputNote)
                .submitLabel(.done)
            Button("Post Spark ✨") {
                saveNote()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            let partner = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "your partner" : storage.partnerName
            Text("Vanishes in 24 hours. Surprise \(partner) with something sweet or wild!")
        }
        .task {
            if HasPartner {
                await loadNotes()
                if let cid = coupleId {
                    await subscribeToNotes(cid: cid)
                }
            }
        }
        .onDisappear {
            isSubscribed = false
            if let ch = notesChannel {
                Task {
                    await SupabaseService.shared.client.realtimeV2.removeChannel(ch)
                }
            }
        }
    }

    // MARK: - Computed Display Labels
    private var displayMyNote: String {
        if let note = myNoteText, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return note
        }
        return "Add note 📝"
    }

    private var displayPartnerNote: String {
        guard HasPartner else { return "No partner yet" }
        if let note = partnerNoteText, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return note
        }
        let partnerTitle = storage.partnerName.isEmpty ? "Partner" : storage.partnerName
        return "\(partnerTitle)'s note 📝"
    }

    // MARK: - Data Logic
    private func loadNotes() async {
        guard let cid = await SupabaseService.shared.fetchCoupleId() else { return }
        self.coupleId = cid

        let currentUID = SupabaseService.shared.client.auth.currentUser?.id
        let notes = await SupabaseService.shared.fetchCoupleNotes(coupleId: cid)

        await MainActor.run {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                let mine = notes.first(where: { $0.userId == currentUID })
                let partner = notes.first(where: { $0.userId != currentUID })
                self.myNoteText = mine?.content
                self.partnerNoteText = partner?.content
            }
        }
    }

    private func saveNote() {
        let trimmed = inputNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let cid = coupleId else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            myNoteText = trimmed
        }

        Task {
            do {
                try await SupabaseService.shared.saveNote(content: trimmed, coupleId: cid)
            } catch {
                print("Failed to save note:", error)
            }
        }
    }

    // MARK: - Realtime WebSocket Subscription
    private func subscribeToNotes(cid: UUID) async {
        guard !isSubscribed else { return }
        isSubscribed = true

        let client = SupabaseService.shared.client
        if let existing = notesChannel {
            await client.realtimeV2.removeChannel(existing)
        }

        let channel = client.realtimeV2.channel("public:notes:\(cid.uuidString.lowercased())")
        self.notesChannel = channel

        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "couple_notes"
        )

        Task {
            for await _ in changes {
                await self.loadNotes()
            }
        }
        await channel.subscribe()
    }
}
