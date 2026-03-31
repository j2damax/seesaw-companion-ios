---
name: swift6-mvvm
description: >
  Swift 6 MVVM patterns for seesaw-companion-ios. Use when creating new ViewModels,
  SwiftUI views, service classes, or when asked about concurrency, @Observable,
  actor isolation, or state management patterns.
---

# Swift 6 MVVM Skill

Teaches correct Swift 6 MVVM patterns for `seesaw-companion-ios`, including `@Observable`, `actor` services, and structured concurrency.

## ViewModel Pattern (`@Observable` + `@MainActor`)

```swift
// ✅ Correct Swift 6 ViewModel
@MainActor
@Observable
final class CompanionViewModel {
    var sessionState: SessionState = .idle
    var lastError: String? = nil

    private let bleService: BLEService
    private let privacyPipeline: PrivacyPipelineService

    init(bleService: BLEService, privacyPipeline: PrivacyPipelineService) {
        self.bleService = bleService
        self.privacyPipeline = privacyPipeline
    }

    func startScanning() {
        sessionState = .scanning
        Task { await bleService.startScanning() }
    }
}
```

```swift
// ❌ Never in this project
class OldViewModel: ObservableObject {
    @Published var state: SessionState = .idle  // use @Observable instead
}
```

## Service Pattern (`actor`)

```swift
// ✅ All services are actors
actor CloudAgentService {
    private let session = URLSession.shared

    func requestStory(payload: ScenePayload) async throws -> StoryResponse {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(StoryResponse.self, from: data)
    }
}
```

## SwiftUI View Pattern

```swift
// ✅ Views only display ViewModel state — no business logic
struct ContentView: View {
    @State private var vm = CompanionViewModel(...)  // @State owns the @Observable

    var body: some View {
        StatusView(state: vm.sessionState)
        Button("Connect") { vm.startScanning() }
            .disabled(vm.sessionState != .idle)
    }
}
```

## Error Handling Pattern

```swift
// ✅ Services throw — ViewModel catches and surfaces to UI
private func runPipeline(jpegData: Data) async {
    do {
        sessionState = .processingPrivacy
        let payload = try await privacyPipeline.process(jpegData: jpegData, childAge: childAge)
        sessionState = .requestingStory
        let story = try await cloudService.requestStory(payload: payload)
        sessionState = .connected
    } catch {
        sessionState = .error(error.localizedDescription)
        lastError = error.localizedDescription
    }
}
```

## Parallel Work Pattern

```swift
// ✅ Use async let for independent parallel work
let blurred = try detectAndBlurFaces(in: image)
async let objects = detectObjects(in: blurred)
async let scene   = classifyScene(in: blurred)
let (detectedObjects, sceneLabels) = try await (objects, scene)
```

## Model Pattern (Zero Imports)

```swift
// ✅ Model structs have zero framework imports
// Model/ScenePayload.swift
struct ScenePayload: Codable, Sendable {
    let objects: [String]
    let scene: [String]
    let transcript: String?
    let childAge: Int
}
```

## UserDefaults Pattern (Settings)

```swift
// ✅ Simple UserDefaults access for PoC — no @AppStorage in services
extension UserDefaults {
    var cloudAgentURL: URL {
        get {
            let str = string(forKey: "cloudAgentURL") ?? "https://your-cloud-run-url"
            return URL(string: str) ?? URL(string: "https://your-cloud-run-url")!
        }
        set { set(newValue.absoluteString, forKey: "cloudAgentURL") }
    }
    var childAge: Int {
        get { integer(forKey: "childAge").clamped(to: 2...12) == 0 ? 5 : integer(forKey: "childAge") }
        set { set(newValue, forKey: "childAge") }
    }
}
```

## Anti-Patterns Checklist

- [ ] No `ObservableObject` / `@Published`
- [ ] No `DispatchQueue.main.async`
- [ ] No `@escaping` completion handlers for async work
- [ ] No `!` force-unwrap in service or ViewModel layer
- [ ] No `import UIKit`
- [ ] No Swift Package dependencies
- [ ] No `@StateObject` (use `@State` with `@Observable`)
- [ ] No business logic in SwiftUI `View` structs
