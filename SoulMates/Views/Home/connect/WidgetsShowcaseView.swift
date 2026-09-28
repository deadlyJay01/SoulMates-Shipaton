//

//  WidgetsShowcaseView.swift

//  SoulMates

//



import SwiftUI



struct WidgetsShowcaseView: View {

    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var storage: AppStorageManager



    private let primaryGradient = LinearGradient(

        colors: [Color(red: 0.95, green: 0.25, blue: 0.42), Color(red: 0.65, green: 0.22, blue: 0.88)],

        startPoint: .topLeading,

        endPoint: .bottomTrailing

    )



    var body: some View {

        ZStack {

            Color.black.ignoresSafeArea()

            onBoarding_Background()

                .ignoresSafeArea()



            ScrollView(showsIndicators: false) {

                VStack(spacing: 24) {

                    // Header

                    VStack(spacing: 6) {

                        Text("Couple Widgets")

                            .font(.system(size: 28, weight: .heavy, design: .rounded))

                            .foregroundStyle(.white)



                        Text("Keep your connection, milestones, and partner's selfies right on your Home Screen.")

                            .font(.system(size: 13, weight: .medium))

                            .foregroundStyle(.white.opacity(0.65))

                            .multilineTextAlignment(.center)

                            .padding(.horizontal, 20)

                    }

                    .padding(.top, 12)



                    // Widget 1: Couple Connection & Distance

                    WidgetSectionCard(

                        badge: "MEDIUM & SMALL",

                        title: "Couple Connection",

                        description: "Connected profile photos, live days count, and real-time distance apart."

                    ) {

                        mockCoupleConnectionCard

                    }



                    // Widget 2: Partner's Daily Glimpse

                    WidgetSectionCard(

                        badge: "SMALL & LARGE",

                        title: "Partner's Daily Glimpse",

                        description: "Your partner's latest Soul Glimpse photo delivered directly to your Home Screen."

                    ) {

                        mockPartnerSelfieCard

                    }



                    // Widget 3: Minimal Days Counter

                    WidgetSectionCard(

                        badge: "MINIMAL",

                        title: "Days Together",

                        description: "A clean, elegant milestone counter celebrating your shared journey."

                    ) {

                        mockMinimalDaysCard

                    }



                    // Tutorial Section

                    howToAddTutorialSection



                    Spacer(minLength: 30)

                }

                .padding(.horizontal, 20)

            }

        }

        .navigationBarBackButtonHidden(true)

        .toolbar {

            ToolbarItem(placement: .topBarLeading) {

                Button {

                    dismiss()

                } label: {

                    HStack(spacing: 4) {

                        Image(systemName: "chevron.left")

                            .font(.system(size: 14, weight: .bold))

                        Text("Back")

                            .font(.system(size: 15, weight: .semibold, design: .rounded))

                    }

                    .foregroundStyle(.white)

                }

            }

        }

        .preferredColorScheme(.dark)

    }



    // MARK: - Mock 1: Couple Connection

    private var mockCoupleConnectionCard: some View {

        VStack(spacing: 8) {

            HStack(spacing: 0) {

                VStack(spacing: 4) {

                    Circle()

                        .fill(Color.white.opacity(0.12))

                        .frame(width: 44, height: 44)

                        .overlay(Image(systemName: "person.fill").foregroundStyle(.white))

                        .overlay(Circle().stroke(primaryGradient, lineWidth: 1.5))

                    Text(storage.userCity.isEmpty ? "You" : storage.userCity)

                        .font(.system(size: 10, weight: .bold, design: .rounded))

                        .foregroundStyle(.white.opacity(0.7))

                }



                ZStack {

                    Rectangle()

                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                        .foregroundStyle(Color.white.opacity(0.3))

                        .frame(height: 1)



                    Circle()

                        .fill(primaryGradient)

                        .frame(width: 26, height: 26)



                    Image(systemName: "heart.fill")

                        .font(.system(size: 12, weight: .bold))

                        .foregroundStyle(.white)

                }

                .frame(maxWidth: .infinity)

                .padding(.horizontal, 10)



                VStack(spacing: 4) {

                    Circle()

                        .fill(Color.white.opacity(0.12))

                        .frame(width: 44, height: 44)

                        .overlay(Image(systemName: "heart.fill").foregroundStyle(.white))

                        .overlay(Circle().stroke(primaryGradient, lineWidth: 1.5))

                    Text(storage.partnerCity.isEmpty ? (storage.partnerName.isEmpty ? "Partner" : storage.partnerName) : storage.partnerCity)

                        .font(.system(size: 10, weight: .bold, design: .rounded))

                        .foregroundStyle(.white.opacity(0.7))

                }

            }

            .padding(.horizontal, 16)



            VStack(spacing: 2) {

                Text("\(max(1, storage.totalDaysTogether)) Days")

                    .font(.system(size: 18, weight: .heavy, design: .rounded))

                    .foregroundStyle(.white)



                if storage.relationshipType == 2 && storage.calculatedDistanceKm > 0 {

                    Text("\(storage.calculatedDistanceKm) KM APART")

                        .font(.system(size: 9, weight: .black, design: .rounded))

                        .tracking(1.4)

                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                } else {

                    Text("TOGETHER")

                        .font(.system(size: 9, weight: .black, design: .rounded))

                        .tracking(2.0)

                        .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                }

            }

        }

        .padding(.vertical, 14)

        .frame(maxWidth: .infinity)

        .background(

            RoundedRectangle(cornerRadius: 18, style: .continuous)

                .fill(Color(red: 0.09, green: 0.08, blue: 0.13))

        )

    }



    // MARK: - Mock 2: Partner Selfie

    private var mockPartnerSelfieCard: some View {

        HStack(spacing: 12) {

            ZStack {

                RoundedRectangle(cornerRadius: 18, style: .continuous)

                    .fill(Color(red: 0.12, green: 0.10, blue: 0.16))

                    .frame(width: 100, height: 100)



                VStack(spacing: 6) {

                    Image(systemName: "camera.fill")

                        .font(.system(size: 24))

                        .foregroundStyle(primaryGradient)

                    Text("Live Photo")

                        .font(.system(size: 11, weight: .bold, design: .rounded))

                        .foregroundStyle(.white.opacity(0.8))

                }

            }



            VStack(alignment: .leading, spacing: 6) {

                Text("Instant Sync")

                    .font(.system(size: 14, weight: .bold, design: .rounded))

                    .foregroundStyle(.white)



                Text("Whenever \(storage.partnerName.isEmpty ? "your partner" : storage.partnerName) snaps their daily glimpse, your Home Screen updates automatically.")

                    .font(.system(size: 12))

                    .foregroundStyle(.white.opacity(0.6))

                    .fixedSize(horizontal: false, vertical: true)

            }

            Spacer()

        }

        .padding(10)

        .background(

            RoundedRectangle(cornerRadius: 18, style: .continuous)

                .fill(Color(red: 0.08, green: 0.07, blue: 0.12))

        )

    }



    // MARK: - Mock 3: Minimal Days

    private var mockMinimalDaysCard: some View {

        HStack {

            Spacer()

            VStack(spacing: 4) {

                ZStack {

                    Circle()

                        .fill(primaryGradient.opacity(0.2))

                        .frame(width: 32, height: 32)

                    Image(systemName: "heart.fill")

                        .font(.system(size: 15))

                        .foregroundStyle(primaryGradient)

                }

                Text("\(max(1, storage.totalDaysTogether))")

                    .font(.system(size: 30, weight: .black, design: .rounded))

                    .foregroundStyle(.white)

                Text("DAYS TOGETHER")

                    .font(.system(size: 9, weight: .black, design: .rounded))

                    .tracking(1.4)

                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

            }

            .padding(.vertical, 12)

            .padding(.horizontal, 28)

            .background(

                RoundedRectangle(cornerRadius: 18, style: .continuous)

                    .fill(Color(red: 0.08, green: 0.07, blue: 0.12))

            )

            Spacer()

        }

    }



    // MARK: - Tutorial Steps

    private var howToAddTutorialSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            HStack(spacing: 8) {

                Image(systemName: "plus.app.fill")

                    .font(.system(size: 16))

                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))



                Text("How to Add to Home Screen")

                    .font(.system(size: 15, weight: .bold, design: .rounded))

                    .foregroundStyle(.white)

            }



            VStack(spacing: 12) {

                tutorialStepRow(

                    step: "1",

                    instruction: "Go to your iPhone Home Screen and touch & hold any empty area until the apps jiggle."

                )

                tutorialStepRow(

                    step: "2",

                    instruction: "Tap the \"+\" or \"Edit\" button in the top corner of the screen."

                )

                tutorialStepRow(

                    step: "3",

                    instruction: "Search for \"SoulMates\" in your widget gallery."

                )

                tutorialStepRow(

                    step: "4",

                    instruction: "Choose your preferred widget style and tap \"Add Widget\"."

                )

            }

        }

        .padding(18)

        .background(

            RoundedRectangle(cornerRadius: 22, style: .continuous)

                .fill(Color.white.opacity(0.05))

                .overlay(

                    RoundedRectangle(cornerRadius: 22, style: .continuous)

                        .stroke(Color.white.opacity(0.1), lineWidth: 1)

                )

        )

    }



    private func tutorialStepRow(step: String, instruction: String) -> some View {

        HStack(alignment: .top, spacing: 12) {

            ZStack {

                Circle()

                    .fill(Color.white.opacity(0.12))

                    .frame(width: 24, height: 24)



                Text(step)

                    .font(.system(size: 12, weight: .black, design: .rounded))

                    .foregroundStyle(.white)

            }



            Text(instruction)

                .font(.system(size: 12, weight: .medium))

                .foregroundStyle(.white.opacity(0.75))

                .fixedSize(horizontal: false, vertical: true)

        }

    }

}



// MARK: - Reusable Section Card Component

private struct WidgetSectionCard<Content: View>: View {

    let badge: String

    let title: String

    let description: String

    @ViewBuilder let content: () -> Content



    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 8) {

                Text(badge)

                    .font(.system(size: 9, weight: .black, design: .rounded))

                    .tracking(1.2)

                    .foregroundStyle(Color(red: 0.95, green: 0.25, blue: 0.42))

                    .padding(.horizontal, 8)

                    .padding(.vertical, 3)

                    .background(Color.white.opacity(0.08), in: Capsule())



                Text(title)

                    .font(.system(size: 16, weight: .bold, design: .rounded))

                    .foregroundStyle(.white)

            }



            Text(description)

                .font(.system(size: 12, weight: .medium))

                .foregroundStyle(.white.opacity(0.6))



            content()

                .padding(.top, 4)

        }

        .padding(16)

        .frame(maxWidth: .infinity, alignment: .leading)

        .background(

            RoundedRectangle(cornerRadius: 22, style: .continuous)

                .fill(Color.white.opacity(0.05))

                .overlay(

                    RoundedRectangle(cornerRadius: 22, style: .continuous)

                        .stroke(Color.white.opacity(0.1), lineWidth: 1)

                )

        )

    }

}
