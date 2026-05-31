//
//  IDEProjectLayout.swift
//  MLTerminalSnippets
//

import Foundation

struct IDEProjectLayout: Sendable {
    let ide: IDETool
    let skillsRelativePath: String
    let agentsFileName: String
    let rulesRelativePath: String?
    let cursorIgnoreFileName: String?

    nonisolated static func layout(for ide: IDETool) -> IDEProjectLayout {
        switch ide {
        case .cursor:
            return IDEProjectLayout(
                ide: .cursor,
                skillsRelativePath: ".cursor/skills",
                agentsFileName: "AGENTS.md",
                rulesRelativePath: ".cursor/rules",
                cursorIgnoreFileName: ".cursorignore"
            )
        case .vscode:
            return IDEProjectLayout(
                ide: .vscode,
                skillsRelativePath: ".github/skills",
                agentsFileName: "AGENTS.md",
                rulesRelativePath: nil,
                cursorIgnoreFileName: nil
            )
        case .claudeCode:
            return IDEProjectLayout(
                ide: .claudeCode,
                skillsRelativePath: ".claude/skills",
                agentsFileName: "CLAUDE.md",
                rulesRelativePath: nil,
                cursorIgnoreFileName: nil
            )
        }
    }

    /// Layout efetivo no MVP: sempre Cursor até outras IDEs ficarem disponíveis.
    nonisolated static func effectiveLayout(for ide: IDETool) -> IDEProjectLayout {
        if ide.isAvailable {
            return layout(for: ide)
        }
        return layout(for: .cursor)
    }

    nonisolated func skillsDirectory(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(skillsRelativePath, isDirectory: true)
    }

    nonisolated func rulesDirectory(projectRoot: URL) -> URL? {
        guard let rulesRelativePath else { return nil }
        return projectRoot.appendingPathComponent(rulesRelativePath, isDirectory: true)
    }

    nonisolated func agentsFileURL(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(agentsFileName)
    }
}
