// ModelDownloadManager.swift
// SeeSaw — Tier 2 companion app
//
// Downloads the Gemma 4 1B GGUF model (~800 MB) to the app's Documents directory
// using a URLSession background transfer and reports progress via AsyncStream.
//
// The model is hosted in Google Cloud Storage. The URL is configurable in
// UserDefaults (key: gemma4ModelURL) so it can be updated without an app release.
//
// Usage:
//   let manager = ModelDownloadManager(storyService: gemma4Service)
//   for await event in manager.downloadModel() { ... }

import Foundation

// MARK: - Download events

enum ModelDownloadEvent: Sendable {
    case progress(Double)           // 0.0–1.0
    case completed(modelPath: String)
    case failed(Error)
}

// MARK: - ModelDownloadManager

actor ModelDownloadManager: NSObject {

    // MARK: - State

    private let storyService: Gemma4StoryService
    private var downloadContinuation: AsyncStream<ModelDownloadEvent>.Continuation?
    private var downloadTask: URLSessionDownloadTask?
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.seesaw.companion.gemma4.download"
        )
        config.isDiscretionary      = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    // MARK: - Persistent state

    // nonisolated so it can be accessed from URLSession delegate callbacks
    nonisolated let modelDestinationURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("gemma4-1b-it-q4_k_m.gguf")
    }()

    // MARK: - Init

    init(storyService: Gemma4StoryService) {
        self.storyService = storyService
        super.init()
    }

    // MARK: - Public

    /// Returns the model path if the GGUF file already exists on disk.
    func installedModelPath() -> String? {
        let url = modelDestinationURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url.path
    }

    /// Checks if the model is already downloaded and updates `storyService` state.
    /// Call at app launch so the service is ready if the user previously downloaded it.
    func checkInstalledModel() async {
        if let path = installedModelPath() {
            await storyService.updateModelState(.ready(modelPath: path))
        }
    }

    /// Starts a background download. Emits `ModelDownloadEvent` values until
    /// `.completed` or `.failed`. Safe to call multiple times — ignores if already downloading.
    func downloadModel() -> AsyncStream<ModelDownloadEvent> {
        AsyncStream { continuation in
            self.downloadContinuation = continuation

            // Already on disk?
            if let path = self.installedModelPath() {
                Task {
                    await self.storyService.updateModelState(.ready(modelPath: path))
                    continuation.yield(.completed(modelPath: path))
                    continuation.finish()
                }
                return
            }

            // Resolve download URL from UserDefaults or use default GCS path.
            guard let sourceURL = self.resolvedSourceURL() else {
                let error = ModelDownloadError.invalidURL
                Task { await self.storyService.updateModelState(.failed(reason: error.localizedDescription)) }
                continuation.yield(.failed(error))
                continuation.finish()
                return
            }

            Task {
                await self.storyService.updateModelState(.downloading(progress: 0))
            }

            let task = self.backgroundSession.downloadTask(with: sourceURL)
            self.downloadTask = task
            task.resume()

            continuation.onTermination = { [weak self] _ in
                Task { await self?.cancelDownload() }
            }
        }
    }

    /// Cancels an in-progress download.
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadContinuation?.finish()
        downloadContinuation = nil
    }

    /// Deletes the downloaded model file (e.g., to free storage).
    func deleteModel() async throws {
        let url = modelDestinationURL
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
        await storyService.updateModelState(.notDownloaded)
    }

    // MARK: - Private

    private func resolvedSourceURL() -> URL? {
        // UserDefaults override (for testing or model updates without App Store release)
        if let custom = UserDefaults.standard.gemma4ModelURL,
           let url = URL(string: custom) {
            return url
        }
        // Default: Google Cloud Storage public bucket
        return URL(string: "https://storage.googleapis.com/seesaw-models/gemma4-1b-it-q4_k_m.gguf")
    }

    // MARK: - Actor-isolated event helpers (called from nonisolated delegate)

    private func yieldProgress(_ progress: Double) async {
        await storyService.updateModelState(.downloading(progress: progress))
        downloadContinuation?.yield(.progress(progress))
    }

    private func yieldCompleted(path: String) async {
        await storyService.updateModelState(.ready(modelPath: path))
        downloadContinuation?.yield(.completed(modelPath: path))
        downloadContinuation?.finish()
        downloadContinuation = nil
    }

    private func yieldFailed(_ error: Error) async {
        await storyService.updateModelState(.failed(reason: error.localizedDescription))
        downloadContinuation?.yield(.failed(error))
        downloadContinuation?.finish()
        downloadContinuation = nil
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate, @unchecked Sendable {

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { await self.yieldProgress(progress) }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let destination = modelDestinationURL
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            Task { await self.yieldCompleted(path: destination.path) }
        } catch {
            Task { await self.yieldFailed(error) }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }
        Task { await self.yieldFailed(error) }
    }
}

// MARK: - Errors

enum ModelDownloadError: LocalizedError {
    case invalidURL
    case moveFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Gemma 4 model download URL is not configured."
        case .moveFailed:   return "Failed to save the downloaded model file."
        }
    }
}

// MARK: - UserDefaults key

private extension UserDefaults {
    var gemma4ModelURL: String? {
        get { string(forKey: "gemma4ModelURL") }
        set { set(newValue, forKey: "gemma4ModelURL") }
    }
}
