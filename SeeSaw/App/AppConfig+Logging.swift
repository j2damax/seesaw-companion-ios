// AppConfig+Logging.swift
// SeeSaw — Tier 2 companion app
//
// Structured logging helper on AppConfig.
// Emit via os.Logger (Unified Logging) — visible in Xcode console
// and Console.app (filter by subsystem "com.seesaw.companion").
//
// Usage (no #if DEBUG needed at call sites):
//   AppConfig.shared.log("Stage 3 – object detection", "labels=\(labels)")
//   AppConfig.shared.log("error occurred", level: .error)

import Foundation
import os

extension AppConfig {

    // MARK: - Log levels

    enum LogLevel: String {
        case debug, info, warning, error
    }

    // MARK: - Logger

    func log(
        _ message: String,
        level: LogLevel = .debug,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard enableLogging else { return }

        // Date.ISO8601FormatStyle is a value type — thread-safe for concurrent calls.
        // The old shared ISO8601DateFormatter was NOT thread-safe and caused EXC_GUARD
        // crashes when multiple Swift Tasks called log() simultaneously during tests.
        let timestamp = Date.now.ISO8601Format(.iso8601WithTimeZone())
        let fileName  = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let funcName  = function.components(separatedBy: "(").first ?? function
        let prefix    = "[\(timestamp)] [\(level.rawValue.uppercased())] [\(fileName).\(funcName):\(line)]"

        switch level {
        case .debug:   Self.logger.debug("\(prefix) \(message)")
        case .info:    Self.logger.info("\(prefix) \(message)")
        case .warning: Self.logger.warning("\(prefix) \(message)")
        case .error:   Self.logger.error("\(prefix) \(message)")
        }
    }

    // MARK: - Private

    private static let logger = Logger(subsystem: "com.seesaw.companion", category: "SeeSaw")
}
