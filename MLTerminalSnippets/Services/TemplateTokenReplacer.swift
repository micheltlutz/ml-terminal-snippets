//
//  TemplateTokenReplacer.swift
//  MLTerminalSnippets
//

import Foundation

enum TemplateTokenReplacer: Sendable {
    struct Tokens: Sendable {
        let projectName: String
        let bundleID: String

        nonisolated init(projectName: String) {
            self.projectName = projectName
            let sanitized = projectName
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .filter { $0.isLetter || $0.isNumber || $0 == "-" }
            let slug = sanitized.isEmpty ? "app" : sanitized
            self.bundleID = "com.example.\(slug)"
        }
    }

    nonisolated static func apply(_ text: String, tokens: Tokens) -> String {
        text
            .replacingOccurrences(of: "{{PROJECT_NAME}}", with: tokens.projectName)
            .replacingOccurrences(of: "{{BUNDLE_ID}}", with: tokens.bundleID)
    }

    nonisolated static func applyPath(_ path: String, tokens: Tokens) -> String {
        apply(path, tokens: tokens)
    }
}
