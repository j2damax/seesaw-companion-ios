# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SeeSaw Companion is an iOS app for a wearable AI companion device worn by children. It connects to a wearable (BLE headset or iPhone camera/mic), runs an on-device privacy pipeline (face blur → YOLO object detection → scene classify → STT → PII scrub), and sends a sanitized `ScenePayload` to a cloud agent that returns story narration.

## Build & Test Commands

```bash
# Build
xcodebuild build -scheme SeeSaw -destination generic/platform=iOS

# Run all tests
xcodebuild test -scheme SeeSaw -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test file
xcodebuild test -scheme SeeSaw -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:SeeSawTests/PrivacyPipelineTests
```

Tests use **Swift Testing** (`import Testing`, `#expect`) — not XCTest. The test plan is `SeeSaw.xctestplan`.

## Architecture

**MVVM + Coordinator + Dependency Injection**

```
SeeSawApp (@main)
  └── AppCoordinator (@MainActor)          — 5-route state machine (launch/terms/signIn/onboarding/home)
        └── AppDependencyContainer         — service singletons, ViewModel factories
              ├── Services/                — business logic (actors + @MainActor classes)
              ├── ViewModel/               — @Observable ViewModels
              └── View/                   — pure SwiftUI, no UIKit
```

Key patterns:
- **@Observable** (Swift 5.9 macro) instead of Combine for ViewModels
- **AsyncStream** instead of Combine for hardware event streams
- **Actors** for concurrency-safe services (`PrivacyPipelineService`, `SpeechRecognitionService`)
- **Protocol-driven hardware abstraction** — `WearableAccessory` protocol with 4 concrete implementations; Views/ViewModels never reference hardware directly

## Service Layer

`AppDependencyContainer` owns all service singletons and injects only what each ViewModel needs (not the full container).

| Service | File | Notes |
|---|---|---|
| `PrivacyPipelineService` | `Services/AI/` | Actor; 6-stage pipeline; emits OSSignpost for Instruments profiling |
| `BLEService` | `Services/BLE/` | CoreBluetooth GATT client; 20ms BLE chunk pacing |
| `AccessoryManager` | `Services/Accessory/` | Owns 4 accessory instances; resolves active one from UserDefaults |
| `CloudAgentService` | `Services/Cloud/` | HTTPS POST; base URL configurable via UserDefaults |
| `SpeechRecognitionService` | `Services/Audio/` | On-device only; no cloud STT fallback |
| `AuthenticationService` | `Services/Auth/` | Firebase + Google Sign-In + Sign In with Apple |

## Privacy Pipeline (Critical)

`PrivacyPipelineService` is a 6-stage actor running entirely on-device:
1. Face detection (Vision)
2. Face blur (CIFilter)
3. Object detection (YOLO11n via CoreML — `seesaw-yolo11n.mlpackage`, NMS baked in)
4. Scene classification (Vision)
5. Speech-to-text (on-device SFSpeechRecognizer)
6. PII scrub (regex — phones, emails, postcodes, addresses, 8 patterns)

**Invariant:** Raw JPEG/audio never stored or transmitted. `PrivacyMetricsEvent.rawDataTransmitted` is always `false`. This is enforced in `PrivacyPipelineTests` (80+ tests, 100-run statistical checks).

The `ScenePayload` sent to cloud contains only: `{objects, scene, transcript, childAge, sessionId, query, timestamp}`.

## State Management

`SessionState` (13-state enum in `Model/SessionState.swift`) models the full interaction lifecycle. `CompanionViewModel` is intentionally a single large ViewModel — this is a deliberate PoC choice, not a bug.

Persistent settings live in `UserDefaults` via `Extensions/UserDefaults+Settings.swift`: `cloudAgentURL`, `childAge`, `selectedWearableType`, `hasAcceptedTerms`, `hasCompletedOnboarding`.

`AppCoordinator` reads these on init to fast-path returning users directly to home.

## iOS / Xcode Notes

- **Minimum deployment:** iOS 26.2, iPhone only
- **No CocoaPods, no SPM** — native Xcode dependency management
- **100% SwiftUI** — no Storyboards or XIBs
- **Background modes:** `bluetooth-central` + `audio` declared so BLE stays live when backgrounded
- `AppConfig.swift` contains feature flags (`enableLogging`, `useTestImageForPreview`)
- If the YOLO model is missing at runtime, the pipeline continues gracefully (logged warning, no crash)
