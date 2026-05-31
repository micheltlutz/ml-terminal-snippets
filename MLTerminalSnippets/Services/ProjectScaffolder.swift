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
    let gitInit: Bool
    let installSkills: Bool
}

struct ProjectScaffoldResult: Sendable {
    let projectURL: URL
    let installFailures: [String]
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

        switch swiftProjectKind {
        case .macOSApp, .iOSApp:
            lines += [
                "├── \(name)/",
                "│   ├── App/\(name)App.swift",
                "│   ├── Models/",
                "│   ├── Views/ContentView.swift",
                "│   └── Services/",
                "├── \(name)Tests/",
                "├── docs/xcode-setup.md",
            ]
        case .swiftPackage:
            lines += [
                "├── Package.swift",
                "├── Sources/\(name)/",
                "└── Tests/\(name)Tests/",
            ]
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
        var installFailures: [String] = []

        let accessed = request.parentDirectory.startAccessingSecurityScopedResource()
        defer {
            if accessed { request.parentDirectory.stopAccessingSecurityScopedResource() }
        }

        if FileManager.default.fileExists(atPath: projectURL.path) {
            throw ProjectScaffolderError.directoryExists(projectURL)
        }
        try FileManager.default.createDirectory(at: projectURL, withIntermediateDirectories: true)

        try SwiftProjectSkeletonBuilder.build(
            projectName: trimmedName,
            kind: request.swiftProjectKind,
            at: projectURL
        )
        log.append("Esqueleto Swift (\(request.swiftProjectKind.displayName)) criado.")

        let skillsRoot = layout.skillsDirectory(projectRoot: projectURL)
        try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        if layout.ide == .cursor {
            try CursorProjectConfigurator.configure(
                projectRoot: projectURL,
                layout: layout,
                projectName: trimmedName
            )
            log.append("Configuração Cursor (.cursor/rules, .cursorignore) aplicada.")
        }

        if request.installSkills, !request.skills.isEmpty {
            log.append("Instalando skills via Git em \(layout.skillsRelativePath)…")
            installFailures = try await SkillGitInstaller.install(
                skills: request.skills,
                skillsRoot: skillsRoot,
                onProgress: onProgress
            )
            if installFailures.isEmpty {
                log.append("Skills instalados com sucesso.")
            } else {
                log.append("Falha parcial: \(installFailures.joined(separator: ", ")).")
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

        if request.gitInit, let git = SkillGitInstaller.gitExecutable() {
            try await runGitInit(git: git, at: projectURL)
            log.append("Repositório Git inicializado.")
        }

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

    private nonisolated static func runGitInit(git: String, at url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: git)
            process.arguments = ["init"]
            process.currentDirectoryURL = url
            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ProjectScaffolderError.writeFailed("git init falhou."))
                }
            }
            try? process.run()
        }
    }
}
