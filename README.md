# 💕 SoulMates

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

**A private space, made for two.**

SoulMates is an iOS app built for couples — a single shared world where two partners can chat, share a daily selfie, listen to music in sync, save their memories, and stay close no matter the distance. Built entirely solo, from the SwiftUI interface to the Supabase backend.

---

## ✨ Features

- 💬 **Private Chat** — Text and voice notes that disappear after 24 hours, so conversations stay light and in the moment.
- 📸 **Soul Glimpse** — A daily selfie exchange. Your partner's photo stays locked until you post yours, then both are revealed together.
- 🎶 **Listen Together** — Pair up and play the same song at the same time, with play, pause, and skip synced live between both devices.
- 🖼️ **Memories** — A shared photo timeline for your special days, with dates and notes attached to each one.
- ❓ **Daily Questions & Quizzes** — Fun, research-based prompts to help couples know each other better, with a daily streak.
- 🎮 **Play Together** — Quizzes and games across categories like *Know Each Other*, *Love & Romance*, and *Fun & Random*.
- 📅 **Date Planner & Notes** — Plan time together and leave notes for your partner.
- 📱 **Home Screen Widgets** — See your days together and your partner's latest selfie without opening the app.
- 💎 **Couple Pro** — One purchase unlocks Pro for both partners. If a couple disconnects, Pro stays with the original purchaser and carries over automatically if they re-pair with someone new — no repurchase needed.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| UI | **SwiftUI** (MVVM architecture with `ObservableObject` view models) |
| Backend | **Supabase** — Auth, Postgres database, Realtime, Storage |
| Audio | **AVFoundation** — voice note recording & synced music playback |
| Media | **PhotosUI** & native camera — selfies and memory photo uploads |
| Widgets | **WidgetKit** — home screen widgets with shared App Group data |
| Subscriptions | **RevenueCat** — couple-based Pro subscription handling |

---

## 🏗️ How It Works

- **Realtime sync** — Supabase Realtime channels power instant chat delivery and the Listen Together feature, keeping both partners' playback state (track, position, playing/paused) in sync live.
- **Security** — Row Level Security (RLS) is enforced on every table so a couple's data (chats, selfies, memories) is only ever visible to the two people paired together. Storage buckets have their own separate RLS policies for photo and voice note uploads.
- **Couple-based Pro** — Pro status is tracked against the *purchasing user*, not the couple itself. When checking access, the app looks up whether either partner in the current couple holds an active Pro subscription — which is what lets Pro carry over automatically if someone re-pairs after a breakup.

---

## 🚀 Getting Started

### Requirements
- Xcode 16+
- iOS 17+ target
- A free [Supabase](https://supabase.com) project
- A [RevenueCat](https://www.revenuecat.com) account (for subscription testing)

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/deadlyJay01/SoulMates-Shipaton
   cd SoulMates-Shipaton
   ```
2. Open `SoulMates.xcodeproj` in Xcode
3. In `SupabaseService.swift`, set your own Supabase project URL and public (anon) key
4. In your Supabase project, enable **Row Level Security** on all tables and run the policies included in `/sql` *(or set up matching policies for `messages`, `memories`, `couple_selfies`, `couples`, etc.)*
5. Create the required Storage buckets (`memory-images`, `chat-voice-notes`, `profile-images`) and add matching Storage policies
6. Configure your RevenueCat API key for subscription handling
7. Build and run on a simulator or device

---

## 📂 Project Structure

```
SoulMates/
├── onBoardings/                  # User onboarding, authentication, & partner pairing flow
│   ├── Pages/                    # Multi-step questionnaire views (P1–P8)
│   ├── Invite partner/           # Code generation & pairing gatekeeper
│   ├── LogIn/ & signUp P8/       # Phone OTP & credential authentication
│   ├── AppStorage/               # AppStorageManager (session, tokens & local persistence)
│   └── ReUsed_Views/             # Custom onboarding fields, buttons, & backgrounds
│
├── Views/                        # Main UI layer (Feature-based MVVM)
│   ├── Home/
│   │   ├── connect/              # Date trackers, shared canvas, & widget showcases
│   │   ├── dailyQuestion/        # Daily Q&A prompts, streak tracking, & sync logic
│   │   ├── Feature_Cards/
│   │   │   ├── Memories/         # Couple timeline, roadmap, & memory creation sheets
│   │   │   └── Songs_Together/   # Synchronized music player & local track catalogue
│   │   └── selfie-camera/        # Soul Glimpse dual/couple photo capture
│   │
│   ├── Chat/                     # Real-time messaging & audio voice notes
│   ├── Challange/                # Interactive quizzes, scoring engine, & Supabase game sync
│   └── UserProfile/              # Profile settings, distance/geo calculation, & Pro subscriptions
│
├── Services & Architecture/
│   ├── SupabaseService.swift     # Core database client, authentication, & storage service
│   ├── PurchaseManager.swift     # RevenueCat subscription management & paywall state
│   ├── PartnerGuard.swift        # Route gating requiring an active paired partner
│   └── MainTabView.swift         # Root navigation & tab coordination
│
└── SoulMatesWidgets/             # iOS WidgetKit extension for home screen couple updates
```

---

## 🎓 What I Learned

This project was built solo while learning iOS development, so it doubled as a crash course in:

- Structuring a real SwiftUI app with MVVM and shared state across view models
- Realtime databases, authentication, storage, and Row Level Security in Supabase
- Debugging systematically — one small typo or a missing generic type (`Set`, `Binding`, `Timeline`) can cascade into a dozen confusing compiler errors, and the fix is almost always at the root, not each symptom
- Designing small emotional details (a locked photo, a disappearing message, a synced play button) that make an app feel personal rather than generic

---

## 🎥 Demo

A complete walkthrough of Soulmates is available on YouTube:

**[▶️ Watch the Soulmates Demo](https://youtu.be/iwDU_B2KT-Y)**

---

## 🗺️ What's Next

- 🤖 Android version
- 🔔 Smarter daily nudges and reminders
- 🎵 A bigger shared music library and collaborative playlists
- 🌍 Multi-language support

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

Built solo by **Jay Satani**
