//
//  SkillContentValidator.swift
//  MLTerminalSnippets
//

import Foundation

enum SkillContentValidator: Sendable {
    /// `SKILL.md` na raiz do skill ou um nível abaixo (repositórios aninhados).
    nonisolated static func skillMarkdownURL(in skillDirectory: URL) -> URL? {
        let root = skillDirectory.appendingPathComponent("SKILL.md")
        if FileManager.default.fileExists(atPath: root.path) {
            return root
        }
        guard let children = try? FileManager.default.contentsOfDirectory(
            at: skillDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for child in children {
            let isDir = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir {
                let nested = child.appendingPathComponent("SKILL.md")
                if FileManager.default.fileExists(atPath: nested.path) {
                    return nested
                }
            }
        }
        return nil
    }

    nonisolated static func isValidSkillDirectory(_ url: URL) -> Bool {
        skillMarkdownURL(in: url) != nil
    }
}
