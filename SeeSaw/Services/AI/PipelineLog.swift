// PipelineLog.swift
// SeeSaw — Tier 2 companion app
//
// DEBUG-only structured logger for the on-device pipeline.
// Logs are emitted via os.Logger (Unified Logging) and are
// visible in Xcode console and Console.app during development.
// All call sites must be wrapped in #if DEBUG so the compiler
// elides them entirely from release builds.
//
// Format: [ISO8601 timestamp] [ClassName.methodName] message

#if DEBUG
import Foundation
import os

enum PipelineLog {

    private static let logger = Logger(subsystem: "com.seesaw.companion", category: "Pipeline")
    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func log(_ stage: String, _ message: String, file: String = #file, function: String = #function) {
        let timestamp = iso8601.string(from: Date())
        let filename  = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let funcName  = function.components(separatedBy: "(").first ?? function
        logger.debug("[\(timestamp)] [\(filename).\(funcName)] \(stage): \(message)")
    }
}
#endif
