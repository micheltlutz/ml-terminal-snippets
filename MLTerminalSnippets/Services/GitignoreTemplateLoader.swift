//
//  GitignoreTemplateLoader.swift
//  MLTerminalSnippets
//

import Foundation

enum GitignoreTemplateLoaderError: LocalizedError, Sendable {
    case templateNotFound(SwiftProjectKind)

    nonisolated var errorDescription: String? {
        switch self {
        case .templateNotFound(let kind):
            return "Template .gitignore não encontrado no bundle para \(kind.displayName)."
        }
    }
}

/// Leitura de templates do bundle — isolamento explícito fora do MainActor.
enum GitignoreTemplateLoader: Sendable {
    private nonisolated static let subdirectory = "Templates/Gitignore"

    nonisolated static func content(for kind: SwiftProjectKind) throws -> String {
        let name = kind.gitignoreTemplateName
        guard let url = TemplateBundle.url(
            resource: name,
            extension: "gitignore",
            subdirectory: subdirectory
        ) else {
            throw GitignoreTemplateLoaderError.templateNotFound(kind)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }
}
