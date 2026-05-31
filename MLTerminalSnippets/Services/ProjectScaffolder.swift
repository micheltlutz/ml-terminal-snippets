//
//  ProjectScaffolder.swift
//  MLTerminalSnippets
//

import Foundation

struct ProjectScaffoldRequest {
    let name: String
    let contextMarkdown: String
    let skills: [SkillRepository]
    let parentDirectory: URL
    let ideTool: IDETool
    let gitInit: Bool
    let installSkills: Bool
}

struct ProjectScaffoldResult {
    let projectURL: URL
    let installFailures: [String]
    let logLines: [String]
}

enum ProjectScaffolderError: LocalizedError {
    case invalidName
    case directoryExists(URL)
    case parentNotAccessible
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidName: "Nome do projeto inválido."
        case .directoryExists(let url): "A pasta já existe: \(url.path)"
        case .parentNotAccessible: "Sem permissão na pasta de destino."
        case .writeFailed(let msg): msg
        }
    }
}

enum ProjectScaffolder {
    static func fileTreePreview(projectName: String, skills: [SkillRepository]) -> [String] {
        var lines = [
            "\(projectName)/",
            "├── README.md",
            "├── AGENTS.md",
            "├── .gitignore",
            "└── .cursor/",
            "    └── skills/",
        ]
        for (i, skill) in skills.enumerated() {
            let prefix = i == skills.count - 1 ? "        └── " : "        ├── "
            lines.append("\(prefix)\(skill.slug)/")
        }
        if skills.isEmpty {
            lines.append("        └── (vazio)")
        }
        return lines
    }

    static func scaffold(
        _ request: ProjectScaffoldRequest,
        onProgress: (@Sendable (SkillInstallProgress) -> Void)? = nil
    ) async throws -> ProjectScaffoldResult {
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !trimmedName.contains("/"),
              !trimmedName.hasPrefix(".")
        else { throw ProjectScaffolderError.invalidName }

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
        try FileManager.default.createDirectory(
            at: projectURL.appendingPathComponent(".cursor/skills", isDirectory: true),
            withIntermediateDirectories: true
        )
        log.append("Pastas criadas.")

        if request.installSkills, !request.skills.isEmpty {
            log.append("Instalando skills via Git…")
            installFailures = try await SkillGitInstaller.install(
                skills: request.skills,
                into: projectURL,
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
            installSkillsFailed: !installFailures.isEmpty && request.installSkills
        )
        let agents = ProjectTemplateBuilder.agentsMD(
            projectName: trimmedName,
            context: request.contextMarkdown,
            skills: request.skills
        )

        try writeFile(readme, to: projectURL.appendingPathComponent("README.md"))
        try writeFile(agents, to: projectURL.appendingPathComponent("AGENTS.md"))
        try writeFile(ProjectTemplateBuilder.gitignore, to: projectURL.appendingPathComponent(".gitignore"))
        log.append("README.md, AGENTS.md e .gitignore escritos.")

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

    private static func writeFile(_ content: String, to url: URL) throws {
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ProjectScaffolderError.writeFailed("Não foi possível escrever \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private static func runGitInit(git: String, at url: URL) async throws {
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
