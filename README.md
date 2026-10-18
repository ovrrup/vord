# VORD

<p align="center">
  <strong>An ultra-minimal, distraction-free study session timer built with Flutter.</strong>
</p>

<p align="center">
  <a href="https://github.com/ovrrup/vord/actions/workflows/build.yml">
    <img src="https://github.com/ovrrup/vord/actions/workflows/build.yml/badge.svg" alt="Build Status" />
  </a>
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android-green" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
</p>

---

## ✦ Philosophy

Most productivity apps overwhelm you with complex menus, push notifications, and visual clutter that break focus before your session even starts.

**VORD** strips away everything unnecessary. It treats your attention as the rarest resource:
- **Zero Cognitive Load**: Open the app, tap once to focus.
- **OLED Pure Black**: Designed with true pure black (`#000000`) to preserve battery life on OLED screens and eliminate all visual distraction.
- **Understated Typography**: Tabular, jitter-free figures and subtle accents that inform without distracting.

---

## ✦ Features

- **Minimal Circular Timer Ring**:
  - Distraction-free, anti-aliased circular progress sweep that gracefully depletes clockwise as the session progresses.
  - Large tabular digital countdown with jitter-free typography and intuitive session status subtitle.
  - Interactive gesture controls: tap to start/pause, long-press to reset.
- **Minimalist Onboarding Flow (First Launch Only)**:
  - Interactive 3-step walkthrough introducing philosophy, gestures, and cadence.
  - Automatically persisted via `shared_preferences` so it only displays on the first launch.
  - Replayable on-demand via the history drawer (`GESTURE GUIDE`).
- **Gesture-First Timer**:
  - `Single Tap`: Start / Pause / Resume session.
  - `Long Press`: Instant session reset.
- **Session Modes**:
  - `Focus` (25m standard study block)
  - `Short Break` (5m refresh)
  - `Long Break` (15m recovery)
- **Automatic Cycle Routing**: Automatically suggests appropriate breaks, guiding you through a classic 4-cycle focus flow.
- **Session History & Metrics**:
  - Real-time today's study minutes tracker in the header.
  - Pull-up timeline sheet displaying completed study blocks and daily focus totals.
  - 100% offline and private.

---

## ✦ Architecture & Project Structure

```
vord/
├── .github/
│   └── workflows/
│       └── build.yml             # Cloud APK compilation & analysis workflow
├── lib/
│   ├── main.dart                 # Application entrypoint
│   └── src/
│       ├── models/
│       │   ├── session_mode.dart # Focus / Break interval definitions
│       │   ├── study_session.dart# Session record model
│       │   └── timer_status.dart # Timer lifecycle states
│       ├── screens/
│       │   ├── onboarding_screen.dart # Interactive 3-step intro & gestures
│       │   └── timer_screen.dart # Interactive study canvas & gestures
│       ├── services/
│       │   └── session_service.dart # Local state & daily statistics engine
│       ├── theme/
│       │   └── app_theme.dart    # Monochromatic palette & typography
│       └── widgets/
│           ├── mode_selector.dart # Understated pill mode switcher
│           ├── session_history_sheet.dart # Daily metrics timeline drawer
│           └── timer_ring.dart   # Anti-aliased circular progress ring
├── test/
│   └── widget_test.dart          # Automated UI & navigation test suite
└── pubspec.yaml
```

---

## ✦ Getting the APK

You can download the compiled Android APK directly from GitHub without needing a local development environment:

1. Navigate to the **[Actions Tab](https://github.com/ovrrup/vord/actions)**.
2. Select the latest successful **Build & Compile Flutter App** workflow run.
3. Scroll down to the **Artifacts** section.
4. Download **`vord-release-apk`** and install `app-release.apk` on your Android device.

---

## ✦ Local Development

If you wish to run or contribute locally:

```bash
# Clone the repository
git clone https://github.com/ovrrup/vord.git
cd vord

# Install dependencies
flutter pub get

# Run tests & lint analysis
flutter analyze
flutter test

# Run on connected device
flutter run
```

---

## ✦ License

This project is licensed under the [MIT License](LICENSE).
