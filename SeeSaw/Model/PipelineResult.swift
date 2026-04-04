// PipelineResult.swift
// SeeSaw — Tier 2 companion app
//
// Combines the cloud-bound ScenePayload with locally-stored privacy metrics.
// Returned by PrivacyPipelineService.process().

struct PipelineResult: Sendable {
    let payload: ScenePayload
    let metrics: PrivacyMetricsEvent
}
