//
//  TemplateBundle.swift
//  MLTerminalSnippets
//

import Foundation

/// Resolve templates no bundle; suporta subpastas ou cópia achatada em `Resources/` (Xcode).
enum TemplateBundle: Sendable {
    nonisolated static func url(
        resource name: String,
        extension ext: String?,
        subdirectory: String? = nil
    ) -> URL? {
        if let subdirectory,
           let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    nonisolated static func string(
        resource name: String,
        extension ext: String?,
        subdirectory: String?
    ) throws -> String {
        guard let url = url(resource: name, extension: ext, subdirectory: subdirectory) else {
            throw TemplateBundleError.notFound(path: [subdirectory, name, ext].compactMap { $0 }.joined(separator: "/"))
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}

enum TemplateBundleError: LocalizedError, Sendable {
    case notFound(path: String)

    nonisolated var errorDescription: String? {
        switch self {
        case .notFound(let path):
            return "Recurso de template não encontrado: \(path)"
        }
    }
}
