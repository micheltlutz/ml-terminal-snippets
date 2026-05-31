//
//  CursorProjectConfigurator.swift
//  MLTerminalSnippets
//

import Foundation

enum CursorProjectConfiguratorError: LocalizedError, Sendable {
    case templateNotFound(String)
    case writeFailed(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .templateNotFound(let name): return "Template Cursor não encontrado: \(name)"
        case .writeFailed(let msg): return msg
        }
    }
}

enum CursorProjectConfigurator: Sendable {
    private nonisolated static let cursorTemplatesSubdir = "Templates/Cursor"

    nonisolated static func configure(
        projectRoot: URL,
        layout: IDEProjectLayout,
        projectName: String,
        skillSlugs: [String] = []
    ) throws {
        guard layout.ide == .cursor else { return }

        let tokens = TemplateTokenReplacer.Tokens(projectName: projectName, skillSlugs: skillSlugs)

        if let rulesDir = layout.rulesDirectory(projectRoot: projectRoot) {
            try FileManager.default.createDirectory(at: rulesDir, withIntermediateDirectories: true)
            if let rulesContent = try? loadTemplate(named: "swift-project", extension: "mdc") {
                let rendered = TemplateTokenReplacer.apply(rulesContent, tokens: tokens)
                let rulesFile = rulesDir.appendingPathComponent("swift-project.mdc")
                try write(rendered, to: rulesFile)
            }
        }

        if let cursorIgnoreName = layout.cursorIgnoreFileName,
           let ignoreContent = try? loadTemplate(named: "cursorignore", extension: nil) {
            let dest = projectRoot.appendingPathComponent(cursorIgnoreName)
            try write(ignoreContent, to: dest)
        }
    }

    private nonisolated static func loadTemplate(named name: String, extension ext: String?) throws -> String {
        guard let url = TemplateBundle.url(
            resource: name,
            extension: ext,
            subdirectory: cursorTemplatesSubdir
        ) else {
            throw CursorProjectConfiguratorError.templateNotFound(name)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    private nonisolated static func write(_ content: String, to url: URL) throws {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw CursorProjectConfiguratorError.writeFailed(
                "Não foi possível escrever \(url.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }
}
