//
//  datePicker_P3.swift
//  SoulMates
//
//  Created by Jay on 05/09/26.
//

import SwiftUI

struct datePicker_P3: View {
    @EnvironmentObject private var storage: AppStorageManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showPickerSheet: Bool = false
    @State private var animateContent: Bool = false

    var body: some View {
        ZStack {
            onBoarding_Background()

            VStack(spacing: 24) {
                // Header Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Which Date You Two Met First?")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("It helps us track how many days you've been together.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 10)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.06), value: animateContent)

                // Live Days Counter
                VStack(spacing: 4) {
                    Text("\(storage.totalDaysTogether)")
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.25, blue: 0.42),
                                    Color(red: 0.65, green: 0.22, blue: 0.88)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color(red: 0.95, green: 0.25, blue: 0.42).opacity(0.35), radius: 14, y: 4)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: storage.totalDaysTogether)

                    Text("Days Together")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.55))
                        .textCase(.uppercase)
                        .tracking(1.5)
                }
                .padding(.vertical, 6)
                .offset(y: animateContent ? 0 : 25)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.18), value: animateContent)

                // Expandable Date Picker Card
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showPickerSheet.toggle()
                        }
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.95, green: 0.25, blue: 0.42),
                                                Color(red: 0.65, green: 0.22, blue: 0.88)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)

                                Image(systemName: "calendar")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Special Date")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.white.opacity(0.5))

                                Text(selectedDate.formatted(date: .long, time: .omitted))
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }

                            Spacer()

                            Image(systemName: showPickerSheet ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.45))
                                .rotationEffect(.degrees(showPickerSheet ? 180 : 0))
                                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: showPickerSheet)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    if showPickerSheet {
                        VStack {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .frame(height: 180)
                            .clipped()
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white.opacity(0.04))
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .offset(y: -8)),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        ))
                    }
                }
                .offset(y: animateContent ? 0 : 25)
                .opacity(animateContent ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.28), value: animateContent)

                Spacer()
            }
        }
        .onAppear {
            if storage.anniversaryDateTimestamp > 0 {
                selectedDate = Date(timeIntervalSince1970: storage.anniversaryDateTimestamp)
            } else {
                selectedDate = Calendar.current.startOfDay(for: Date())
            }
            syncDays()
            animateContent = true
        }
        .onChange(of: selectedDate) { _, _ in
            syncDays()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncDays()
            }
        }
    }

    private func syncDays() {
        let calendar = Calendar.current
        let startOfSelected = calendar.startOfDay(for: selectedDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let diff = calendar.dateComponents([.day], from: startOfSelected, to: startOfToday)
        let calculatedDays = max(0, diff.day ?? 0)
        
        storage.totalDaysTogether = calculatedDays
        storage.anniversaryDateTimestamp = selectedDate.timeIntervalSince1970
    }
}

#Preview {
    datePicker_P3()
        .environmentObject(AppStorageManager())
}
