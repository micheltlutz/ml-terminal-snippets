//
//  SkillGitInstaller.swift
//  MLTerminalSnippets
//

import Foundation

struct SkillInstallProgress: Sendable {
    let current: Int
    let total: Int
    let skillName: String
    let message: String
}

enum SkillGitInstallerError: LocalizedError, Sendable {
    case gitNotFound
    case cloneFailed(skill: String, output: String)

    nonisolated var errorDescription: String? {
        switch self {
        case .gitNotFound:
            return "Git não encontrado. Instale as Xcode Command Line Tools."
        case .cloneFailed(let skill, let output):
            return "Falha ao clonar \(skill): \(output)"
        }
    }
}

enum SkillGitInstaller: Sendable {
    /// Ordem importa: `/usr/bin/git` é um stub que invoca `xcrun` (bloqueado no App Sandbox).
    private nonisolated static let gitSearchPaths = [
        "/Library/Developer/CommandLineTools/usr/bin/git",
        "/Applications/Xcode.app/Contents/Developer/usr/bin/git",
        "/opt/homebrew/bin/git",
        "/usr/local/bin/git",
        "/usr/bin/git",
    ]

    nonisolated static func gitExecutable() -> String? {
        gitSearchPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Ambiente para evitar que o Git invoque `xcrun` dentro do sandbox.
    nonisolated static func processEnvironment(for gitPath: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment

        if gitPath.hasPrefix("/Library/Developer/CommandLineTools/") {
            env["DEVELOPER_DIR"] = "/Library/Developer/CommandLineTools"
            env["PATH"] = "/Library/Developer/CommandLineTools/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        } else if gitPath.contains("/Xcode.app/Contents/Developer/") {
            env["DEVELOPER_DIR"] = "/Applications/Xcode.app/Contents/Developer"
            env["PATH"] = "/Applications/Xcode.app/Contents/Developer/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        } else if gitPath.hasPrefix("/opt/homebrew/") {
            env["PATH"] = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        } else if gitPath.hasPrefix("/usr/local/") {
            env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        }

        env["GIT_TERMINAL_PROMPT"] = "0"
        return env
    }

    nonisolated static func install(
        skills: [SkillScaffoldItem],
        skillsRoot: URL,
        onProgress: (@Sendable (SkillInstallProgress) -> Void)? = nil
    ) async throws -> [SkillInstallFailure] {
        guard let git = gitExecutable() else { throw SkillGitInstallerError.gitNotFound }

        try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        var failures: [SkillInstallFailure] = []
        let total = skills.count

        for (index, skill) in skills.enumerated() {
            onProgress?(
                SkillInstallProgress(
                    current: index + 1,
                    total: total,
                    skillName: skill.name,
                    message: "Clonando \(skill.skillFolderName)…"
                )
            )

            let dest = skillsRoot.appendingPathComponent(skill.slug, isDirectory: true)
            if FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
            }

            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("mlts-\(UUID().uuidString)", isDirectory: true)

            defer { try? FileManager.default.removeItem(at: temp) }

            do {
                try await runGit(git: git, arguments: [
                    "clone", "--depth", "1", "--filter=blob:none", "--sparse",
                    skill.gitURL, temp.path
                ])
                try await runGit(git: git, arguments: [
                    "-C", temp.path, "sparse-checkout", "set", skill.skillFolderName
                ])

                let source = temp.appendingPathComponent(skill.skillFolderName, isDirectory: true)
                guard FileManager.default.fileExists(atPath: source.path) else {
                    failures.append(SkillInstallFailure(
                        skillName: skill.name,
                        reason: "pasta '\(skill.skillFolderName)' não encontrada no repositório"
                    ))
                    continue
                }
                try FileManager.default.copyItem(at: source, to: dest)

                if skillMarkdownURL(in: dest) == nil {
                    try? FileManager.default.removeItem(at: dest)
                    failures.append(SkillInstallFailure(
                        skillName: skill.name,
                        reason: "SKILL.md não encontrado em '\(skill.skillFolderName)'"
                    ))
                }
            } catch let error as SkillGitInstallerError {
                failures.append(SkillInstallFailure(
                    skillName: skill.name,
                    reason: error.localizedDescription
                ))
            } catch {
                failures.append(SkillInstallFailure(
                    skillName: skill.name,
                    reason: error.localizedDescription
                ))
            }
        }

        return failures
    }

    /// `SKILL.md` na raiz do skill ou um nível abaixo (repositórios aninhados).
    nonisolated static func skillMarkdownURL(in skillDirectory: URL) -> URL? {
        SkillContentValidator.skillMarkdownURL(in: skillDirectory)
    }

    private nonisolated static func runGit(git: String, arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: git)
            process.arguments = arguments
            process.environment = processEnvironment(for: git)

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "unknown error"
                    let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    let friendly = sandboxFriendlyMessage(for: trimmed)
                    continuation.resume(throwing: SkillGitInstallerError.cloneFailed(
                        skill: arguments.joined(separator: " "),
                        output: friendly
                    ))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private nonisolated static func sandboxFriendlyMessage(for output: String) -> String {
        if output.contains("cannot be used within an App Sandbox") {
            return """
            Git bloqueado pelo App Sandbox (xcrun). Instale Xcode Command Line Tools \
            (`xcode-select --install`) e tente novamente, ou use os comandos `npx skills add` no README.
            """
        }
        return output
    }
}
