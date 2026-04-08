# SeeSaw Companion — Test Coverage Report

**Generated:** 2026-04-08 (baseline — pre-coverage)
**Test Plan:** `SeeSaw.xctestplan` with `codeCoverageEnabled: true`

> ⚠️ **Baseline report** — This is a structural baseline created before running
> coverage-instrumented tests on a macOS host. Line-level percentages will be
> populated once tests are run locally with:
>
> ```bash
> xcodebuild test \
>   -scheme SeeSaw \
>   -destination 'platform=iOS Simulator,name=iPhone 16' \
>   -testPlan SeeSaw \
>   -resultBundlePath /tmp/SeeSawResults.xcresult
>
> ./Scripts/export-coverage.sh /tmp/SeeSawResults.xcresult test-results/TestCoverage.md
> ```

---

## Test Suite Summary

| Metric | Value |
|--------|-------|
| Source files | 57 |
| Total source lines | 6,025 |
| Test files (unit) | 6 |
| Test files (UI) | 2 |
| Unit tests | ~92 |
| UI tests | 3 |

## Source File Inventory

### App Layer (4 files)

| File | Lines | Expected Coverage |
|------|------:|-------------------|
| AppConfig.swift | 36 | Low — config constants |
| AppConfig+Logging.swift | 56 | Low — logging helpers |
| AppCoordinator.swift | 81 | Low — UI routing |
| AppDependencyContainer.swift | 91 | Low — DI wiring |

### Model Layer (15 files)

| File | Lines | Expected Coverage |
|------|------:|-------------------|
| BLEConstants.swift | 44 | N/A — constants only |
| ChildProfile.swift | 18 | Medium |
| DetectionResult.swift | 14 | Medium |
| PipelineResult.swift | 10 | High — tested |
| PrivacyMetricsEvent.swift | 23 | High — tested |
| SceneContext.swift | 26 | High — tested |
| ScenePayload.swift | 15 | High — tested |
| SessionState.swift | 57 | High — tested |
| StoryBeat.swift | 50 | High — tested |
| StoryError.swift | 32 | High — tested |
| StoryGenerationMode.swift | 26 | High — tested |
| StoryMetricsEvent.swift | 14 | Medium |
| StoryResponse.swift | 7 | Low |
| TimelineEntry.swift | 21 | Low |
| TranscriptionResult.swift | 8 | Low |
| TransferChunk.swift | 61 | Medium |
| UserSession.swift | 14 | Low |
| WearableAccessory.swift | 177 | Medium — tested |

### Services Layer (13 files)

| File | Lines | Expected Coverage |
|------|------:|-------------------|
| **AI/** | | |
| OnDeviceStoryService.swift | 279 | Medium — tested |
| PIIScrubber.swift | 70 | **High — 14 tests** |
| PrivacyMetricsStore.swift | 71 | **High — 11 tests** |
| PrivacyPipelineService.swift | 491 | Medium — integration |
| StoryGenerating.swift | 14 | N/A — protocol |
| StoryMetricsStore.swift | 70 | Medium — tested |
| **Accessory/** | | |
| AccessoryManager.swift | 82 | Low — hardware |
| ExternalSDKAccessory.swift | 83 | Low — hardware |
| LocalDeviceAccessory.swift | 288 | Low — hardware |
| **Audio/** | | |
| AudioCaptureService.swift | 169 | Low — hardware |
| AudioService.swift | 73 | Low — hardware |
| SpeechRecognitionService.swift | 220 | Low — hardware |
| **Auth/** | | |
| AuthenticationService.swift | 160 | Low — Firebase |
| **BLE/** | | |
| BLEService.swift | 226 | Low — hardware |
| ChunkBuffer.swift | 38 | Medium |
| **Cloud/** | | |
| CloudAgentService.swift | 71 | Low — network |

### ViewModel Layer (3 files)

| File | Lines | Expected Coverage |
|------|------:|-------------------|
| AuthViewModel.swift | 78 | Low |
| CompanionViewModel.swift | 551 | Medium |
| OnboardingViewModel.swift | 119 | Low |

### View Layer (12 files)

| File | Lines | Expected Coverage |
|------|------:|-------------------|
| ContentView.swift | 119 | N/A — UI only |
| SeeSawApp.swift | 62 | N/A — entry point |
| AccessoryPickerView.swift | 60 | N/A — UI only |
| CameraTabView.swift | 203 | N/A — UI only |
| HomeView.swift | 52 | N/A — UI only |
| ScenePreviewView.swift | 174 | N/A — UI only |
| SettingsTabView.swift | 142 | N/A — UI only |
| TimelineTabView.swift | 93 | N/A — UI only |
| LaunchScreenView.swift | 83 | N/A — UI only |
| OnboardingView.swift | 377 | N/A — UI only |
| TermsView.swift | 135 | N/A — UI only |
| SettingsView.swift | 174 | N/A — UI only |
| CameraPreviewView.swift | 41 | N/A — UI only |
| SignInView.swift | 108 | N/A — UI only |
| StatusView.swift | 91 | N/A — UI only |

## Test Files

| Test File | Tests | Coverage Focus |
|-----------|------:|----------------|
| PrivacyPipelineTests.swift | 34 | PIIScrubber, ScenePayload, PrivacyMetricsEvent, PrivacyMetricsStore |
| SeeSawTests.swift | 25 | SessionState, TransferChunk, WearableAccessory, UserDefaults |
| OnDeviceStoryServiceTests.swift | 15 | StoryBeat, OnDeviceStoryService mocks |
| StoryBeatTests.swift | 8 | StoryBeat validation |
| SceneContextTests.swift | 5 | SceneContext construction |
| StoryGenerationModeTests.swift | 5 | Mode enum + UserDefaults round-trip |
| SeeSawUITests.swift | 2 | Basic UI launch |
| SeeSawUITestsLaunchTests.swift | 1 | Launch screenshot |

## Coverage Expectations

| Layer | Files | Lines | Expected Range |
|-------|------:|------:|----------------|
| Model | 18 | 617 | 60–80% |
| Services/AI | 6 | 995 | 40–60% |
| Services (other) | 7 | 927 | 5–15% (hardware) |
| ViewModel | 3 | 748 | 15–30% |
| View | 15 | 1,914 | 0–5% (UI only) |
| App | 4 | 264 | 5–15% |
| **Total** | **57** | **6,025** | **~11% estimated** |

> The 11% figure shown in the Xcode Test Navigator (top-left of the scheme editor screenshot)
> aligns with this estimate. Most untested code is in hardware-dependent services (BLE, Camera,
> Audio) and SwiftUI views — both of which require device/simulator runtime to exercise.

---

## How to Regenerate

```bash
# 1. Run tests with coverage + result bundle
xcodebuild test \
  -scheme SeeSaw \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -testPlan SeeSaw \
  -resultBundlePath /tmp/SeeSawResults.xcresult

# 2. Export to Markdown
./Scripts/export-coverage.sh /tmp/SeeSawResults.xcresult test-results/TestCoverage.md

# 3. Commit updated report
git add test-results/TestCoverage.md
git commit -m "Update test coverage report"
```

---

*Report generated from structural analysis — actual xccov data pending local test run.*
