// CloudAgentService.swift
// SeeSaw — Tier 2 companion app
//
// Minimal URLSession-based HTTPS client. Posts ScenePayload to the cloud story
// agent and decodes the StoryResponse. No third-party networking libraries.

import Foundation

actor CloudAgentService {

    // MARK: - Configuration

    private let session: URLSession
    private var baseURL: URL?

    // MARK: - Init

    init(baseURL: URL?) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        // 75s covers Cloud Run cold starts (~30s) + Gemini generation (~10s) with margin.
        // Cloud Run service timeout is 60s; iOS timeout is set higher so the server
        // error (504) surfaces rather than a client-side timeout.
        config.timeoutIntervalForRequest = 75
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public

    func updateBaseURL(_ url: URL?) {
        baseURL = url
    }

    func requestStory(payload: ScenePayload) async throws -> StoryResponse {
        guard let base = baseURL else {
            AppConfig.shared.log("requestStory: no cloud agent URL configured", level: .error)
            throw CloudError.notConfigured
        }
        let endpoint = base.appendingPathComponent("story/generate")
        var request  = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (body, apiKey): (Data, String) = try await MainActor.run {
            let encoded = try JSONEncoder().encode(payload)
            let key = UserDefaults.standard.cloudAgentKey
            return (encoded, key)
        }
        if !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "X-SeeSaw-Key")
        }
        request.httpBody = body
        AppConfig.shared.log("requestStory: POST \(endpoint), bodyBytes=\(body.count), keySet=\(!apiKey.isEmpty), objects=\(payload.objects), scene=\(payload.scene)")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            AppConfig.shared.log("requestStory: invalid response type", level: .error)
            throw CloudError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            AppConfig.shared.log("requestStory: HTTP \(httpResponse.statusCode)", level: .error)
            throw CloudError.unexpectedStatusCode(httpResponse.statusCode)
        }

        AppConfig.shared.log("requestStory: HTTP 200, responseBytes=\(data.count)")
        return try await MainActor.run { try JSONDecoder().decode(StoryResponse.self, from: data) }
    }
}

// MARK: - Errors

enum CloudError: LocalizedError, Sendable {
    case notConfigured
    case invalidResponse
    case unexpectedStatusCode(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "No cloud agent URL configured. Set it in Settings."
        case .invalidResponse:
            return "Cloud agent returned an invalid response."
        case .unexpectedStatusCode(let code):
            return "Cloud agent error: HTTP \(code)."
        }
    }
}

