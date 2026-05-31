//
//  ProjectDocsTemplateLoader.swift
//  MLTerminalSnippets
//

import Foundation

enum ProjectDocsTemplateLoaderError: LocalizedError, Sendable {
    case templateNotFound(String)
    case writeFailed(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .templateNotFound(let path): return "Template não encontrado: \(path)"
        case .writeFailed(let msg): return msg
        }
    }
}

enum ProjectDocsTemplateLoader: Sendable {
    private nonisolated static let docsTemplatesSubdir = "Templates/Swift"

    /// Copia `docs/xcode-setup.md` do bundle para apps macOS/iOS (sem código Swift).
    nonisolated static func writeXcodeSetupIfNeeded(
        projectName: String,
        kind: SwiftProjectKind,
        at projectRoot: URL
    ) throws {
        guard kind == .macOSApp || kind == .iOSApp else { return }

        let tokens = TemplateTokenReplacer.Tokens(projectName: projectName)
        let bundleName = "\(kind.swiftTemplateFolder)-xcode-setup"
        let subdirectory = "\(docsTemplatesSubdir)/\(kind.swiftTemplateFolder)"

        guard let url = TemplateBundle.url(
            resource: bundleName,
            extension: "md",
            subdirectory: subdirectory
        ) else {
            throw ProjectDocsTemplateLoaderError.templateNotFound("\(subdirectory)/\(bundleName).md")
        }

        let raw = try String(contentsOf: url, encoding: .utf8)
        let content = TemplateTokenReplacer.apply(raw, tokens: tokens)
        let docsDir = projectRoot.appendingPathComponent("docs", isDirectory: true)
        try FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
        let destination = docsDir.appendingPathComponent("xcode-setup.md")
        do {
            try content.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            throw ProjectDocsTemplateLoaderError.writeFailed(
                "Não foi possível escrever xcode-setup.md: \(error.localizedDescription)"
            )
        }
    }
}
