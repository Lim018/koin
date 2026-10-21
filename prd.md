# Product Requirements Document (PRD) & Architecture Spec
**Project Name:** Cozy Tracker (Gamified Frictionless Money Manager)
**Target Platform:** Android (Priority for Native Integrations) & iOS
**Design Theme:** Cozy Nostalgia (Pixel-art Mascot, Soft Glassmorphism, Warm Palette)
**Current Phase:** MVP (100% Offline-First)

## 1. Project Overview
A frictionless personal finance tracker designed to eliminate user friction in logging daily transactions. The app utilizes OS-level features (Widgets, Transparent Activities, Notification Listeners) to ensure data entry takes < 3 seconds. It incorporates a gamified behavioral design featuring a pixel-art mascot ("Koko") whose mood changes based on budget adherence.

## 2. Tech Stack & Architecture (MVP Phase - 100% Offline)
- **Frontend / Core Logic:** Flutter & Dart.
- **State Management:** BLoC or Riverpod (Ensure clean separation of UI and Business Logic).
- **Native Android Bridge:** Kotlin via `MethodChannel`. Required for:
  - `AppWidgetProvider` (4x4 Home Screen Widget).
  - `NotificationListenerService` (Auto-read background service).
  - `Theme.Translucent.NoTitleBar` Activity (For quick-add pop-up).
- **Database:** Isar Database ONLY. (Strictly offline-first. Extremely high-performance synchronous read/write operations suitable for instant widget/pop-up interactions).
- **Backend / Sync API:** DEFERRED to V2. (No HTTP packages, no network requests, no REST API for this phase. Future implementation will use Go with Clean Architecture).
- **AI Integration:** DEFERRED to V2. We will use Regex/String matching for early notification parsing tests.

## 3. UI/UX Design System
- **Core Aesthetic:** "Cozy Nostalgia" mixed with modern flat cards and subtle glassmorphism.
- **Typography:** Strictly modern, crisp Sans-serif (e.g., Inter, SF Pro, or Poppins). No cursive/handwritten fonts.
- **Color Palette:**
  - Backgrounds: Soft warm beige/cream.
  - Success/Under Budget: Warm Sage Green.
  - Warning/Over Budget: Soft Sunset Orange (Do not use harsh neon red).
  - UI Elements: Clean white cards with very soft, subtle drop shadows and 1px borders.
- **Gamification (The Mascot):** "Koko", a pixel-art style character (reminiscent of a 90s digital pet). Its expression changes (Happy, Neutral, Angry/Grumpy) based on the daily/weekly budget threshold.

## 4. Core Features & Technical Requirements

### 4.1. 4x4 Mascot Dashboard Widget (Home Screen)
- **Constraint:** Must only take up exactly 40-50% of the screen height (True 4x4 Android grid layout), leaving the bottom half of the screen for regular app icons.
- **Components:** 
  - Dynamic Mascot mood icon (Happy if under budget, Grumpy if over budget).
  - Large text displaying today's total spending.
  - A prominent "+ TAMBAH" button.
- **Action:** Clicking "+ TAMBAH" fires a `PendingIntent` that wakes the `QuickAddActivity` (Transparent Pop-up) via MethodChannel, without launching the full Flutter app.

### 4.2. Frictionless Quick-Add Pop-up (Transparent Activity)
- **Constraint:** A native Android Activity styled as a transparent modal over the OS Home Screen. The bottom half of the screen MUST remain empty to allow the native OS keyboard to pop up.
- **Components:** 
  - Glassmorphism background container floating in the center.
  - Large numeric input field (triggers native device keyboard immediately upon opening).
  - 3-4 predefined Category Chips (e.g., Makan, Trans, Belanja).
  - Save Button.
- **Action:** On save, write directly to the Isar database and call `finish()` on the Activity. Update the Widget state automatically. No custom numpad UI needed.

### 4.3. Auto-Read Notification Service
- **Constraint:** Runs seamlessly in the background.
- **Logic:** 
  - Listen for notifications from target packages (e.g., GoPay, BCA, OVO).
  - Use simple Regex matching to parse the string: `Extract {amount}`.
  - Trigger a local actionable notification: "Catat Rp25.000 sebagai Makanan?" with Action Buttons [YA, CATAT] [UBAH] [ABAIKAN].

### 4.4. Full App Ecosystem (Main UI)
- **Mascot's Room (Dashboard):** Displays the pixel-art mascot in a cozy digital room. Includes a daily timeline of transactions below it.
- **Monthly Diary (Calendar):** A pocket-planner style calendar grid. Days have visual indicator dots (Sage Green for under budget, Sunset Orange for over budget).
- **Automation Settings:** Clean toggle switches to manage Notification Listener permissions and widget appearance.

## 5. Database Schema (Isar)

```dart
@collection
class Transaction {
  Id id = Isar.autoIncrement;
  late DateTime timestamp;
  late double amount;
  late String category;
  late String walletSource; // e.g., 'Cash', 'GoPay'
  bool isAutoLogged = false;
  String? note;
}

@collection
class UserState {
  Id id = Isar.autoIncrement;
  late double dailyBudgetTarget;
  late int savedCoins; // Currency for gamification/mascot room
  late DateTime lastUpdated;
}