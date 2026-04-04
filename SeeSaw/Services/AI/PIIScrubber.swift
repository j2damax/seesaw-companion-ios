// PIIScrubber.swift
// SeeSaw — Tier 2 companion app
//
// Single source of truth for PII pattern matching and redaction.
// Used by both PrivacyPipelineService and SpeechRecognitionService.
//
// PRIVACY CONTRACT: conservative scrubbing — only explicit PII patterns
// are redacted to avoid over-scrubbing valid story content.

import Foundation

enum PIIScrubber {

    static func scrub(_ text: String) -> (scrubbed: String, tokensRedacted: Int) {
        var result = text
        var count = 0

        for pattern in patterns {
            let matches = pattern.regex.matches(
                in: result,
                range: NSRange(result.startIndex..., in: result)
            )
            count += matches.count
            result = pattern.regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "[REDACTED]"
            )
        }

        return (result, count)
    }

    // MARK: - Patterns

    private struct PIIPattern {
        let regex: NSRegularExpression
    }

    private static let patterns: [PIIPattern] = {
        func make(_ pattern: String, options: NSRegularExpression.Options = []) -> PIIPattern {
            // Force-try is safe here — patterns are compile-time constants.
            // swiftlint:disable:next force_try
            PIIPattern(regex: try! NSRegularExpression(pattern: pattern, options: options))
        }
        return [
            // Email addresses (highest priority — match before generic number patterns)
            make(#"\S+@\S+\.\S+"#),

            // "My name is X" / "I'm called X" / "I am X" patterns
            make(#"\b(my name is|i'm called|i am)\s+\w+"#, options: .caseInsensitive),

            // Phone numbers (US/UK international format)
            make(#"\b(\+?\d{1,3}[\s-]?)?\(?\d{2,4}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}\b"#),

            // UK postcodes
            make(#"\b[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}\b"#, options: .caseInsensitive),

            // US ZIP codes (5 or 9 digit)
            make(#"\b\d{5}(-\d{4})?\b"#),

            // Street addresses
            make(#"\b\d+\s+[A-Za-z]+\s+(Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Court|Ct)\b"#, options: .caseInsensitive),

            // Long digit sequences (7+ digits — account numbers, IDs, etc.)
            make(#"\b\d{7,}\b"#),
        ]
    }()
}
