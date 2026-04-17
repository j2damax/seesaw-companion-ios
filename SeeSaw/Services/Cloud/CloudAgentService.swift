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

    // MARK: - Enhancement (hybrid mode)

    /// POST to /story/enhance with full context for a richer cloud beat.
    /// On 404 (endpoint not yet deployed) falls back to /story/generate
    /// with storyHistory injected into ScenePayload — same privacy boundary.
    /// Returns StoryBeat directly so BackgroundStoryEnhancer stays type-safe.
    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        storyHistory: [StoryTurn],
        turnNumber: Int
    ) async throws -> StoryBeat {
        guard let base = baseURL else {
            AppConfig.shared.log("requestEnhancement: no cloud agent URL", level: .error)
            throw CloudError.notConfigured
        }

        let maxTurns = 6
        let req = EnhancementRequest(
            scenePayload: payload,
            baseBeat: baseBeat,
            childAnswer: childAnswer,
            storyHistory: storyHistory,
            turnNumber: turnNumber,
            maxTurns: maxTurns,
            childAge: payload.childAge,
            childName: payload.childName
        )

        let endpoint = base.appendingPathComponent("story/enhance")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (body, apiKey): (Data, String) = try await MainActor.run {
            let encoded = try JSONEncoder().encode(req)
            let key = UserDefaults.standard.cloudAgentKey
            return (encoded, key)
        }
        if !apiKey.isEmpty {
            urlRequest.setValue(apiKey, forHTTPHeaderField: "X-SeeSaw-Key")
        }
        urlRequest.httpBody = body
        AppConfig.shared.log("requestEnhancement: POST \(endpoint), turn=\(turnNumber), historyLen=\(storyHistory.count)")

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw CloudError.invalidResponse
        }

        if http.statusCode == 200 {
            AppConfig.shared.log("requestEnhancement: HTTP 200, responseBytes=\(data.count)")
            return try await MainActor.run { try JSONDecoder().decode(StoryBeat.self, from: data) }
        }

        // /story/enhance not yet deployed — fall back to /story/generate with history context.
        // child_answer goes into storyHistory (not transcript — that field is PII-scrubbed
        // ambient speech only).
        AppConfig.shared.log("requestEnhancement: HTTP \(http.statusCode), falling back to /story/generate", level: .warning)
        let payloadWithHistory = ScenePayload(
            objects: payload.objects,
            scene: payload.scene,
            transcript: payload.transcript,
            childAge: payload.childAge,
            childName: payload.childName,
            sessionId: payload.sessionId,
            storyHistory: storyHistory
        )
        let storyResponse = try await requestStory(payload: payloadWithHistory)
        return StoryBeat(
            storyText: storyResponse.storyText,
            question:  storyResponse.question,
            isEnding:  storyResponse.isEnding
        )
    }
}

// MARK: - Cloud enhancement protocol (testability seam)

protocol CloudEnhancing: Sendable {
    func requestEnhancement(
        payload: ScenePayload,
        baseBeat: StoryBeat,
        childAnswer: String?,
        storyHistory: [StoryTurn],
        turnNumber: Int
    ) async throws -> StoryBeat
}

extension CloudAgentService: CloudEnhancing {}

// MARK: - Enhancement request

struct EnhancementRequest: Codable {
    let scenePayload: ScenePayload
    let baseBeat: StoryBeat
    let childAnswer: String?
    let storyHistory: [StoryTurn]
    let turnNumber: Int
    let maxTurns: Int
    let childAge: Int
    let childName: String

    enum CodingKeys: String, CodingKey {
        case scenePayload = "scene_payload"
        case baseBeat     = "base_beat"
        case childAnswer  = "child_answer"
        case storyHistory = "story_history"
        case turnNumber   = "turn_number"
        case maxTurns     = "max_turns"
        case childAge     = "child_age"
        case childName    = "child_name"
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
