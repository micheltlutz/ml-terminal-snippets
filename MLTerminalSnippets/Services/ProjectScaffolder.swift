//
//  ProjectScaffolder.swift
//  MLTerminalSnippets
//

import Foundation

struct ProjectScaffoldRequest: Sendable {
    let name: String
    let contextMarkdown: String
    let skills: [SkillScaffoldItem]
    let parentDirectory: URL
    let ideTool: IDETool
    let swiftProjectKind: SwiftProjectKind
    let recreateIfExists: Bool
    let installSkills: Bool
}

struct SkillInstallFailure: Sendable, Equatable {
    let skillName: String
    let reason: String

    nonisolated var displayMessage: String { "\(skillName): \(reason)" }
}

struct ProjectScaffoldResult: Sendable {
    let projectURL: URL
    let installFailures: [SkillInstallFailure]
    let logLines: [String]
}

enum ProjectScaffolderError: LocalizedError, Sendable {
    case invalidName
    case directoryExists(URL)
    case parentNotAccessible
    case writeFailed(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .invalidName: return "Nome do projeto inválido."
        case .directoryExists(let url): return "A pasta já existe: \(url.path)"
        case .parentNotAccessible: return "Sem permissão na pasta de destino."
        case .writeFailed(let msg): return msg
        }
    }
}

enum ProjectScaffolder: Sendable {
    nonisolated static func fileTreePreview(
        projectName: String,
        swiftProjectKind: SwiftProjectKind,
        ideTool: IDETool,
        skills: [SkillScaffoldItem]
    ) -> [String] {
        let layout = IDEProjectLayout.effectiveLayout(for: ideTool)
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "ProjectName" : trimmed

        var lines = ["\(name)/"]

        if swiftProjectKind == .macOSApp || swiftProjectKind == .iOSApp {
            lines.append("├── docs/xcode-setup.md")
        }

        lines += [
            "├── README.md",
            "├── \(layout.agentsFileName)",
            "├── .gitignore",
        ]

        if layout.ide == .cursor {
            lines += ["└── .cursor/"]
            if layout.rulesRelativePath != nil {
                lines.append("    ├── rules/swift-project.mdc")
            }
            if layout.cursorIgnoreFileName != nil {
                lines.append("    ├── …/.cursorignore (raiz)")
            }
            lines.append("    └── skills/")
            appendSkillLines(to: &lines, skills: skills, indent: "        ")
        } else {
            lines.append("└── \(layout.skillsRelativePath)/")
            appendSkillLines(to: &lines, skills: skills, indent: "    ")
        }

        return lines
    }

    private nonisolated static func appendSkillLines(
        to lines: inout [String],
        skills: [SkillScaffoldItem],
        indent: String
    ) {
        if skills.isEmpty {
            lines.append("\(indent)└── (vazio)")
            return
        }
        for (i, skill) in skills.enumerated() {
            let prefix = i == skills.count - 1 ? "└── " : "├── "
            lines.append("\(indent)\(prefix)\(skill.slug)/")
        }
    }

    nonisolated static func scaffold(
        _ request: ProjectScaffoldRequest,
        onProgress: (@Sendable (SkillInstallProgress) -> Void)? = nil
    ) async throws -> ProjectScaffoldResult {
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !trimmedName.contains("/"),
              !trimmedName.hasPrefix(".")
        else { throw ProjectScaffolderError.invalidName }

        let layout = IDEProjectLayout.effectiveLayout(for: request.ideTool)
        var log: [String] = ["Criando estrutura em \(request.parentDirectory.path)…"]

        let projectURL = request.parentDirectory.appendingPathComponent(trimmedName, isDirectory: true)
        var installFailures: [SkillInstallFailure] = []

        let accessed = request.parentDirectory.startAccessingSecurityScopedResource()
        defer {
            if accessed { request.parentDirectory.stopAccessingSecurityScopedResource() }
        }

        if FileManager.default.fileExists(atPath: projectURL.path) {
            if request.recreateIfExists {
                try FileManager.default.removeItem(at: projectURL)
                log.append("Pasta existente removida; recriando…")
            } else {
                throw ProjectScaffolderError.directoryExists(projectURL)
            }
        }
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)

        if request.swiftProjectKind == .macOSApp || request.swiftProjectKind == .iOSApp {
            try ProjectDocsTemplateLoader.writeXcodeSetupIfNeeded(
                projectName: trimmedName,
                kind: request.swiftProjectKind,
                at: projectURL
            )
            log.append("Guia docs/xcode-setup.md escrito (\(request.swiftProjectKind.displayName)).")
        }

        let skillsRoot = layout.skillsDirectory(projectRoot: projectURL)
        try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        if layout.ide == .cursor {
            try CursorProjectConfigurator.configure(
                projectRoot: projectURL,
                layout: layout,
                projectName: trimmedName,
                skillSlugs: request.skills.map(\.slug)
            )
            log.append("Configuração Cursor (.cursor/rules, .cursorignore) aplicada.")
        }

        if request.installSkills, !request.skills.isEmpty {
            log.append("Copiando skills do cache local para \(layout.skillsRelativePath)…")
            installFailures = try SkillCacheService.installFromCache(
                skills: request.skills,
                skillsRoot: skillsRoot,
                onProgress: onProgress
            )
            if installFailures.isEmpty {
                log.append("Skills copiados com sucesso.")
            } else {
                let details = installFailures.map(\.displayMessage).joined(separator: "; ")
                log.append("Falha parcial na instalação de skills: \(details)")
            }
        }

        let readme = ProjectTemplateBuilder.readme(
            projectName: trimmedName,
            context: request.contextMarkdown,
            skills: request.skills,
            swiftProjectKind: request.swiftProjectKind,
            layout: layout,
            installSkillsFailed: !installFailures.isEmpty && request.installSkills
        )
        let agents = ProjectTemplateBuilder.agentsMD(
            projectName: trimmedName,
            context: request.contextMarkdown,
            skills: request.skills,
            swiftProjectKind: request.swiftProjectKind,
            layout: layout
        )

        try writeFile(readme, to: projectURL.appendingPathComponent("README.md"))
        try writeFile(agents, to: layout.agentsFileURL(projectRoot: projectURL))
        let gitignore = try GitignoreTemplateLoader.content(for: request.swiftProjectKind)
        try writeFile(gitignore, to: projectURL.appendingPathComponent(".gitignore"))
        log.append("README.md, \(layout.agentsFileName) e .gitignore escritos.")

        return ProjectScaffoldResult(
            projectURL: projectURL,
            installFailures: installFailures,
            logLines: log
        )
    }

    private nonisolated static func writeFile(_ content: String, to url: URL) throws {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ProjectScaffolderError.writeFailed("Não foi possível escrever \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

}
