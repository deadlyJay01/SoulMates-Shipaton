//
//  DatesDetail.swift
//  SoulMates
//
//  Created by Jay on 18/09/26.
//

import SwiftUI
import Supabase

// MARK: - Date Model
struct CoupleDateItem: Identifiable, Codable {
    let id: UUID
    let couple_id: UUID
    var location_name: String
    var date_timestamp: Date
    var planned_by: String
    var is_completed: Bool

    var isMissed: Bool {
        !is_completed && date_timestamp < Date()
    }

    var isUpcoming: Bool {
        !is_completed && date_timestamp >= Date()
    }

    var isWithin24Hours: Bool {
        let diff = date_timestamp.timeIntervalSince(Date())
        return diff > 0 && diff <= 86400
    }
}

// MARK: - Main Screen
struct DatesDetail: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.dismiss) private var dismiss

    @State private var dates: [CoupleDateItem] = []
    @State private var isLoading = false
    @State private var showUpcoming = true
    @State private var showCompleted = true
    @State private var showMissed = true
    
    @State private var showAddSheet = false
    @State private var selectedDateForEdit: CoupleDateItem? = nil
    @State private var showPartnerAlert = false
    @State private var showInviteSheet = false
    @State private var currentCoupleId: UUID? = nil

    private var hasPartner: Bool {
        let name = storage.partnerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && name.lowercased() != "partner"
    }

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            onBoarding_Background()

            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Spacer()

                    Text("Dates & Plans")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        if hasPartner && currentCoupleId != nil {
                            showAddSheet = true
                        } else {
                            showPartnerAlert = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("Add")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // Date List or Unpaired Placeholder
                if !hasPartner {
                    UnpairedPlaceholderView(
                        title: "Dates Require a Partner",
                        subtitle: "Pair with your partner to plan upcoming dates, track countdowns, and schedule shared memories."
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // 1. Upcoming Dates
                            VStack(spacing: 12) {
                                sectionHeader(
                                    title: "Upcoming Dates",
                                    count: dates.filter { $0.isUpcoming }.count,
                                    isExpanded: $showUpcoming
                                )

                                if showUpcoming {
                                    let upcoming = dates.filter { $0.isUpcoming }
                                    if upcoming.isEmpty {
                                        emptyStateText("No upcoming dates scheduled.")
                                    } else {
                                        ForEach(upcoming) { item in
                                            DateCardView(
                                                item: item,
                                                onToggleComplete: { toggleComplete(item) },
                                                onReschedule: { selectedDateForEdit = item },
                                                onDelete: { deleteDate(item) }
                                            )
                                        }
                                    }
                                }
                            }

                            // 2. Completed Dates
                            VStack(spacing: 12) {
                                sectionHeader(
                                    title: "Completed",
                                    count: dates.filter { $0.is_completed }.count,
                                    isExpanded: $showCompleted
                                )

                                if showCompleted {
                                    let completed = dates.filter { $0.is_completed }
                                    if completed.isEmpty {
                                        emptyStateText("No completed dates yet.")
                                    } else {
                                        ForEach(completed) { item in
                                            DateCardView(
                                                item: item,
                                                onToggleComplete: { toggleComplete(item) },
                                                onReschedule: { selectedDateForEdit = item },
                                                onDelete: { deleteDate(item) }
                                            )
                                        }
                                    }
                                }
                            }

                            // 3. Missed Dates
                            VStack(spacing: 12) {
                                sectionHeader(
                                    title: "Missed",
                                    count: dates.filter { $0.isMissed }.count,
                                    isExpanded: $showMissed
                                )

                                if showMissed {
                                    let missed = dates.filter { $0.isMissed }
                                    if missed.isEmpty {
                                        emptyStateText("No missed dates!")
                                    } else {
                                        ForEach(missed) { item in
                                            DateCardView(
                                                item: item,
                                                onToggleComplete: { toggleComplete(item) },
                                                onReschedule: { selectedDateForEdit = item },
                                                onDelete: { deleteDate(item) }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .refreshable {
                        await fetchDates()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .partnerRequiredAlert(
            isPresented: $showPartnerAlert,
            featureName: "Dates & Plans",
            showInviteSheet: $showInviteSheet
        )
        .sheet(isPresented: $showAddSheet) {
            if let coupleId = currentCoupleId {
                AddDateSheet(coupleId: coupleId) { newDate in
                    withAnimation {
                        dates.insert(newDate, at: 0)
                    }
                }
            }
        }
        .sheet(item: $selectedDateForEdit) { item in
            RescheduleDateSheet(item: item) { updatedDate in
                if let index = dates.firstIndex(where: { $0.id == updatedDate.id }) {
                    withAnimation {
                        dates[index] = updatedDate
                    }
                }
            }
        }
        .task {
            if hasPartner {
                await fetchDates()
            }
        }
    }

    private func sectionHeader(title: String, count: Int, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("(\(count))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()

                Image(systemName: isExpanded.wrappedValue ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }

    private func emptyStateText(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func fetchDates() async {
        guard let currentUID = client.auth.currentUser?.id else { return }

        do {
            struct CoupleRow: Codable {
                let id: UUID
                let user1_id: UUID
                let user2_id: UUID
            }

            var coupleList: [CoupleRow] = (try? await client
                .from("couples")
                .select("id, user1_id, user2_id")
                .eq("user1_id", value: currentUID.uuidString)
                .limit(1)
                .execute()
                .value) ?? []

            if coupleList.isEmpty {
                coupleList = (try? await client
                    .from("couples")
                    .select("id, user1_id, user2_id")
                    .eq("user2_id", value: currentUID.uuidString)
                    .limit(1)
                    .execute()
                    .value) ?? []
            }

            guard let matchedCouple = coupleList.first else {
                await MainActor.run { currentCoupleId = nil }
                return
            }

            await MainActor.run { currentCoupleId = matchedCouple.id }

            let fetched: [CoupleDateItem] = try await client
                .from("couple_dates")
                .select()
                .eq("couple_id", value: matchedCouple.id.uuidString)
                .order("date_timestamp", ascending: true)
                .execute()
                .value

            await MainActor.run {
                self.dates = fetched
            }
        } catch {
            print("Error fetching dates:", error)
        }
    }

    private func toggleComplete(_ item: CoupleDateItem) {
        guard let index = dates.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation {
            dates[index].is_completed.toggle()
        }
        let updatedStatus = dates[index].is_completed

        Task {
            struct UpdatePayload: Encodable {
                let is_completed: Bool
            }
            try? await client
                .from("couple_dates")
                .update(UpdatePayload(is_completed: updatedStatus))
                .eq("id", value: item.id.uuidString)
                .execute()
        }
    }

    private func deleteDate(_ item: CoupleDateItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dates.removeAll(where: { $0.id == item.id })
        }

        Task {
            try? await client
                .from("couple_dates")
                .delete()
                .eq("id", value: item.id.uuidString)
                .execute()
        }
    }
}

// MARK: - Reusable Date Card View
struct DateCardView: View {
    let item: CoupleDateItem
    let onToggleComplete: () -> Void
    let onReschedule: () -> Void
    let onDelete: () -> Void

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: item.date_timestamp)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: item.date_timestamp)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if item.isWithin24Hours {
                HStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(.yellow)
                    Text("Happening within 24 hours!")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("📍 \(item.location_name)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 16) {
                        Label(formattedDate, systemImage: "calendar")
                        Label(formattedTime, systemImage: "clock")
                    }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))

                    Text("Planned by: \(item.planned_by)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                        .padding(.top, 2)
                }

                Spacer()

                Button(action: onToggleComplete) {
                    Image(systemName: item.is_completed ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(item.is_completed ? Color.green : Color.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.1))

            HStack {
                Button(action: onReschedule) {
                    HStack(spacing: 5) {
                        Image(systemName: "calendar.badge.clock")
                        Text("Reschedule")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))
                }

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    HStack(spacing: 5) {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.red.opacity(0.8))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            item.isMissed
                            ? Color.red.opacity(0.35)
                            : (item.isWithin24Hours ? Color.yellow.opacity(0.4) : Color.white.opacity(0.12)),
                            lineWidth: 1.2
                        )
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Add Date Sheet
struct AddDateSheet: View {
    let coupleId: UUID
    let onDateAdded: (CoupleDateItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storage: AppStorageManager

    @State private var location: String = ""
    @State private var selectedDate: Date = Date().addingTimeInterval(3600)
    @State private var isSubmitting = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.04, blue: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location or Activity")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            CustomInputField(
                                icon: "mappin.circle.fill",
                                placeholder: "e.g. Dinner at Rooftop Cafe",
                                text: $location
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button {
                            submitDate()
                        } label: {
                            Text(isSubmitting ? "Planning..." : "Schedule Date")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(location.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                        .opacity(location.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Plan a Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func submitDate() {
        isSubmitting = true
        let planner = storage.userName.isEmpty ? "You" : storage.userName

        struct InsertPayload: Encodable {
            let couple_id: UUID
            let location_name: String
            let date_timestamp: Date
            let planned_by: String
            let is_completed: Bool
        }

        let newPayload = InsertPayload(
            couple_id: coupleId,
            location_name: location,
            date_timestamp: selectedDate,
            planned_by: planner,
            is_completed: false
        )

        Task {
            do {
                let created: CoupleDateItem = try await client
                    .from("couple_dates")
                    .insert(newPayload)
                    .select()
                    .single()
                    .execute()
                    .value

                await MainActor.run {
                    onDateAdded(created)
                    isSubmitting = false
                    dismiss()
                }
            } catch {
                print("Error creating date:", error)
                await MainActor.run { isSubmitting = false }
            }
        }
    }
}

// MARK: - Reschedule Date Sheet
struct RescheduleDateSheet: View {
    let item: CoupleDateItem
    let onUpdated: (CoupleDateItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var location: String = ""
    @State private var newDate: Date = Date()
    @State private var isUpdating = false

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.04, blue: 0.08).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location or Activity")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            CustomInputField(
                                icon: "mappin.circle.fill",
                                placeholder: "e.g. Dinner",
                                text: $location
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select New Date & Time")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            DatePicker(
                                "",
                                selection: $newDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .tint(Color(red: 0.95, green: 0.25, blue: 0.42))
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button {
                            updateDate()
                        } label: {
                            Text(isUpdating ? "Rescheduling..." : "Save Changes")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(location.trimmingCharacters(in: .whitespaces).isEmpty || isUpdating)
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reschedule Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                location = item.location_name
                newDate = max(Date(), item.date_timestamp)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func updateDate() {
        isUpdating = true

        struct UpdatePayload: Encodable {
            let location_name: String
            let date_timestamp: Date
            let is_completed: Bool
        }

        let payload = UpdatePayload(
            location_name: location,
            date_timestamp: newDate,
            is_completed: false
        )

        Task {
            do {
                let updated: CoupleDateItem = try await client
                    .from("couple_dates")
                    .update(payload)
                    .eq("id", value: item.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value

                await MainActor.run {
                    onUpdated(updated)
                    isUpdating = false
                    dismiss()
                }
            } catch {
                print("Error updating date:", error)
                await MainActor.run { isUpdating = false }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DatesDetail()
    }
    .environmentObject(AppStorageManager())
    .preferredColorScheme(.dark)
}
