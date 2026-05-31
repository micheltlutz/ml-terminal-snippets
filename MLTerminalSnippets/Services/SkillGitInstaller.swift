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

enum SkillGitInstallerError: LocalizedError {
    case gitNotFound
    case cloneFailed(skill: String, output: String)

    var errorDescription: String? {
        switch self {
        case .gitNotFound:
            "Git não encontrado. Instale as Xcode Command Line Tools."
        case .cloneFailed(let skill, let output):
            "Falha ao clonar \(skill): \(output)"
        }
    }
}

enum SkillGitInstaller {
    private static let gitPaths = ["/usr/bin/git", "/opt/homebrew/bin/git", "/usr/local/bin/git"]

    static func gitExecutable() -> String? {
        gitPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func install(
        skills: [SkillRepository],
        into projectDirectory: URL,
        onProgress: (@Sendable (SkillInstallProgress) -> Void)? = nil
    ) async throws -> [String] {
        guard let git = gitExecutable() else { throw SkillGitInstallerError.gitNotFound }

        let skillsRoot = projectDirectory.appendingPathComponent(".cursor/skills", isDirectory: true)
        try FileManager.default.createDirectory(at: skillsRoot, withIntermediateDirectories: true)

        var failures: [String] = []
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
                    failures.append(skill.name)
                    continue
                }
                try FileManager.default.copyItem(at: source, to: dest)
            } catch {
                failures.append(skill.name)
            }
        }

        return failures
    }

    private static func runGit(git: String, arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: git)
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { proc in
                if proc.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? "unknown error"
                    continuation.resume(throwing: SkillGitInstallerError.cloneFailed(
                        skill: arguments.joined(separator: " "),
                        output: output
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
}
