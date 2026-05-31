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

    init(
        id: UUID = UUID(),
        name: String,
        gitURL: String,
        skillFolderName: String,
        slug: String
    ) {
        self.id = id
        self.name = name
        self.gitURL = gitURL
        self.skillFolderName = skillFolderName
        self.slug = slug
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
            slug: repository.slug
        )
    }

    @MainActor
    static func snapshots(from repositories: [SkillRepository]) -> [SkillScaffoldItem] {
        repositories.map { SkillScaffoldItem(repository: $0) }
    }
}
