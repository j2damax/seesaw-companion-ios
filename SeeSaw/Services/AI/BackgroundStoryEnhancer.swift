// BackgroundStoryEnhancer.swift
// SeeSaw — Tier 2 companion app
//
// Actor that owns the concurrent cloud enhancement task for hybrid mode.
// The cloud runs during speak + listen dead time (8–15s). If the enhanced
// beat arrives before consumeEnhancedBeat()'s deadline, the child gets a
// richer beat; otherwise the local model fills in instantly.

import Foundation

actor BackgroundStoryEnhancer {

    private let cloudService: any CloudEnhancing
    private var pendingTask: Task<(StoryBeat, Double)?, Never>?
    private var cachedResult: (StoryBeat, Double)?
    private var storyHistory: [StoryTurn] = []

    init(cloudService: any CloudEnhancing) {
        self.cloudService = cloudService
    }

    // MARK: - Request

    /// Fire a background cloud enhancement request. Returns immediately.
    /// The task runs concurrently and will populate cachedResult when complete.
    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        turnNumber: Int
    ) {
        // Maintain history before firing — so the captured snapshot is consistent.
        storyHistory.append(StoryTurn(role: "model", text: baseBeat.storyText))
        if let answer = childAnswer {
            storyHistory.append(StoryTurn(role: "user", text: answer))
        }
        let history = storyHistory

        pendingTask = Task {
            let start = CFAbsoluteTimeGetCurrent()
            do {
                let beat = try await cloudService.requestEnhancement(
                    payload: payload,
                    baseBeat: baseBeat,
                    childAnswer: childAnswer,
                    storyHistory: history,
                    turnNumber: turnNumber
                )
                let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
                await self.setCached((beat, ms))
                return (beat, ms)
            } catch {
                AppConfig.shared.log(
                    "BackgroundStoryEnhancer: cloud failed: \(error)", level: .warning
                )
                return nil
            }
        }
    }

    // MARK: - Consume

    /// Race the cloud task against `deadline`. Returns immediately if already cached.
    ///
    /// - If cloud wins within deadline: clears task and returns the beat.
    /// - If timeout wins: leaves pendingTask running — it will call setCached()
    ///   when it finishes, seeding the next turn's fast path via `cachedResult`.
    ///
    /// Uses polling (50ms step) rather than withTaskGroup so that the function
    /// truly returns after the deadline. withTaskGroup implicitly awaits ALL child
    /// tasks, including the one blocking on the unstructured pendingTask.value,
    /// which would defeat the deadline guarantee.
    func consumeEnhancedBeat(deadline: Duration = .seconds(1)) async -> (StoryBeat, Double)? {
        // Fast path: cloud completed while child was answering
        if let cached = cachedResult {
            let result = cached
            cachedResult = nil
            pendingTask = nil
            return result
        }
        guard pendingTask != nil else { return nil }

        let pollInterval = Duration.milliseconds(50)
        var remaining = deadline
        while remaining > .zero {
            try? await Task.sleep(for: min(pollInterval, remaining))
            remaining -= pollInterval
            if let cached = cachedResult {
                let result = cached
                cachedResult = nil
                pendingTask = nil
                return result
            }
        }
        // Cloud didn't respond in time. pendingTask continues running and
        // will call setCached() when it finishes — available for the next turn.
        return nil
    }

    // MARK: - Reset

    /// Cancel any in-flight task and clear all state. Call at session end.
    func reset() {
        pendingTask?.cancel()
        pendingTask = nil
        cachedResult = nil
        storyHistory = []
    }

    // MARK: - Private

    private func setCached(_ value: (StoryBeat, Double)) {
        cachedResult = value
    }
}
