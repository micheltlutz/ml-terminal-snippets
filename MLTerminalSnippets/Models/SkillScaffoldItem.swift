//
//  SkillScaffoldItem.swift
//  MLTerminalSnippets
//

import Foundation

/// Snapshot `Sendable` de um skill para serviços de scaffold fora do MainActor.
struct SkillScaffoldItem: Sendable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let gitURL: String
    let skillFolderName: String
    let slug: String
    let usageNotes: String

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        gitURL: String,
        skillFolderName: String,
        slug: String,
        usageNotes: String = ""
    ) {
        self.id = id
        self.name = name
        self.gitURL = gitURL
        self.skillFolderName = skillFolderName
        self.slug = slug
        self.usageNotes = usageNotes
    }

    /// Texto para tabela "Quando usar" em AGENTS.md.
    nonisolated var whenToUseDisplay: String {
        let trimmed = usageNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Use ao trabalhar em código relacionado a este skill."
        }
        return trimmed
    }
}

extension SkillScaffoldItem {
    /// Cria snapshot no MainActor a partir do `@Model` (não cruzar isolamento).
    @MainActor
    init(repository: SkillRepository) {
        self.init(
            id: repository.id,
            name: repository.name,
            gitURL: repository.gitURL,
            skillFolderName: repository.skillFolderName,
            slug: repository.slug,
            usageNotes: repository.notes
        )
    }

    @MainActor
    static func snapshots(from repositories: [SkillRepository]) -> [SkillScaffoldItem] {
        repositories.map { SkillScaffoldItem(repository: $0) }
    }
}
