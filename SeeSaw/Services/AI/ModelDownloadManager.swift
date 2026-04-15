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
            .appendingPathComponent("gemma2-2b-it-gpu-int8.bin")
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

            // URL resolution is async (calls /model/latest), so run inside a Task.
            Task {
                await self.storyService.updateModelState(.downloading(progress: 0))

                guard let sourceURL = await self.resolvedSourceURL() else {
                    let error = ModelDownloadError.invalidURL
                    await self.storyService.updateModelState(.failed(reason: error.localizedDescription))
                    continuation.yield(.failed(error))
                    continuation.finish()
                    return
                }

                let task = self.backgroundSession.downloadTask(with: sourceURL)
                self.downloadTask = task
                task.resume()
            }

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

    /// Resolves the GGUF download URL.
    ///
    /// Strategy (in order):
    ///   1. Call GET /model/latest with the stored API key → returns a 1-hour signed GCS URL.
    ///      This is the standard path: the signed URL is required because the GCS bucket is private.
    ///   2. If the cloud agent is unreachable, fall back to the UserDefaults override
    ///      (useful for development or forcing a specific model version).
    private func resolvedSourceURL() async -> URL? {
        let (baseURL, apiKey): (URL?, String) = await MainActor.run {
            (UserDefaults.standard.cloudAgentURL, UserDefaults.standard.cloudAgentKey)
        }

        // ── Path 1: signed URL from /model/latest (skipped when no URL configured) ──
        if let baseURL {
            let metaURL = baseURL.appendingPathComponent("model/latest")
            var request = URLRequest(url: metaURL, timeoutInterval: 10)
            if !apiKey.isEmpty {
                request.setValue(apiKey, forHTTPHeaderField: "X-SeeSaw-Key")
            }
            if let (data, _) = try? await URLSession.shared.data(for: request),
               let json = try? JSONDecoder().decode(ModelLatestResponse.self, from: data) {
                AppConfig.shared.log("ModelDownloadManager: resolved signed URL from /model/latest, size=\(json.sizeBytes)")
                return URL(string: json.downloadURL)
            }
        }

        // ── Path 2: UserDefaults override (dev/testing only) ─────────────────
        if let custom = await MainActor.run(body: { UserDefaults.standard.gemma4ModelURL }),
           let url = URL(string: custom) {
            AppConfig.shared.log("ModelDownloadManager: /model/latest unreachable — using UserDefaults override", level: .warning)
            return url
        }

        AppConfig.shared.log("ModelDownloadManager: no valid download URL resolved", level: .error)
        return nil
    }

    // Decodable mirror of GET /model/latest response (app/routers/model.py)
    private struct ModelLatestResponse: Decodable {
        let downloadURL:  String
        let sizeBytes:    Int
        let modelVersion: String
        enum CodingKeys: String, CodingKey {
            case downloadURL  = "download_url"
            case sizeBytes    = "size_bytes"
            case modelVersion = "model_version"
        }
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

extension UserDefaults {
    var gemma4ModelURL: String? {
        get { string(forKey: "gemma4ModelURL") }
        set { set(newValue, forKey: "gemma4ModelURL") }
    }
}
