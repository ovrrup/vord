# VORD

<p align="center">
  <strong>A sharp, matte, and retro styled stopwatch designed for self-competition.</strong>
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

## ✦ Overview

**VORD** is an ultra-minimal stopwatch designed to motivate you to compete with yourself and focus longer and longer after each session.

When opening the app, you are greeted with a clean, distraction-free white screen containing **3 components only**:

1. **Motivational Greeting Area (Top)**:
   - Dynamic time-of-day greeting and motivating self-competition benchmarks based on your session history.
2. **Rotating Physical Matte Disk (Center)**:
   - A tactile matte disk that rotates when running and progressively paints itself from the center outward as time passes.
   - **Black Theme**: `#121212` (Off-Black) → `#1B2E24` (Deep Emerald) → `#28593D` (Muted Moss) → `#3FA36C` (Vibrant Leaf Green).
   - **White Mode**: `#FFFFFF` (Pure White) → `#F2F9F3` (Mint Tint) → `#A8D5BA` (Soft Sage) → `#2E8B57` (Pleasant Forest Green).
   - Upright tabular digital stopwatch readout in the center (`00:00`).
3. **Physical Matte Controls (Bottom)**:
   - Mechanical depression styling and physical button click sound and haptic feedback on touch.
   - **Large Play/Pause/Resume Button**: Very large tactile button on the left (pausing automatically saves the focus session).
   - **Mode Switch Button**: Located on the top-right at **1/3rd** the height of the play button to toggle between Focus and Rest modes.
   - **Settings Button**: Located on the bottom-right at **2/3rd** the height of the play button to switch theme settings (`White Mode`, `Black Theme`, `System Default`).

---

## ✦ Architecture & Project Structure

```
vord/
├── .github/
│   └── workflows/
│       └── build.yml             # Cloud APK compilation & analysis workflow
├── lib/
│   ├── main.dart                 # Application entrypoint & ThemeMode management
│   └── src/
│       ├── models/
│       │   ├── session_mode.dart # Focus / Rest interval definitions
│       │   ├── study_session.dart# Session record model
│       │   └── timer_status.dart # Lifecycle state machine
│       ├── screens/
│       │   └── timer_screen.dart # 3-component retro matte stopwatch screen
│       ├── services/
│       │   └── session_service.dart # Local state & self-competition engine
│       ├── theme/
│       │   └── app_theme.dart    # Sharp matte palettes & exact disk stages
│       └── widgets/
│           ├── motivation_banner.dart      # Component 1: Greeting & competition benchmark
│           ├── retro_matte_disk.dart       # Component 2: Rotating spreading-color matte disk
│           └── physical_matte_controls.dart# Component 3: Physical buttons & theme settings
├── test/
│   └── widget_test.dart          # Automated UI & controls test suite
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
