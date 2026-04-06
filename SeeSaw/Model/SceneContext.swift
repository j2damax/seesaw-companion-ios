// SceneContext.swift
// SeeSaw — Tier 2 companion app
//
// Bridges ScenePayload (privacy pipeline output) to OnDeviceStoryService input.
// Decouples the story service from the privacy pipeline's internal types.

struct SceneContext: Sendable {
    let labels: [String]
    let sceneCategories: [String]
    let transcript: String?
    let childAge: Int

    init(from payload: ScenePayload) {
        self.labels          = payload.objects
        self.sceneCategories = payload.scene
        self.transcript      = payload.transcript
        self.childAge        = payload.childAge
    }

    init(labels: [String], sceneCategories: [String], transcript: String?, childAge: Int) {
        self.labels          = labels
        self.sceneCategories = sceneCategories
        self.transcript      = transcript
        self.childAge        = childAge
    }
}
