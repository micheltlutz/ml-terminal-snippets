//
//  SeedDataService.swift
//  MLTerminalSnippets
//

import Foundation
import SwiftData

struct BuiltInSkillRepository: Sendable {
    let name: String
    let gitURL: String
    let skillFolderName: String
    let slug: String
    let usageNotes: String
}

enum SeedDataService {
    private static let didSeedKey = "MLTerminalSnippets.didSeedBuiltInRepositories"

    nonisolated static let builtInRepositories: [BuiltInSkillRepository] = [
        BuiltInSkillRepository(
            name: "SwiftUI Pro",
            gitURL: "https://github.com/twostraws/SwiftUI-Agent-Skill",
            skillFolderName: "swiftui-pro",
            slug: "swiftui-pro",
            usageNotes: "Views SwiftUI, navegação, acessibilidade, performance de UI"
        ),
        BuiltInSkillRepository(
            name: "SwiftData Pro",
            gitURL: "https://github.com/twostraws/SwiftData-Agent-Skill",
            skillFolderName: "swiftdata-pro",
            slug: "swiftdata-pro",
            usageNotes: "Modelos `@Model`, CloudKit, relacionamentos, queries"
        ),
        BuiltInSkillRepository(
            name: "Swift Concurrency Pro",
            gitURL: "https://github.com/twostraws/Swift-Concurrency-Agent-Skill",
            skillFolderName: "swift-concurrency-pro",
            slug: "swift-concurrency-pro",
            usageNotes: "async/await, `@MainActor`, Sendable, task groups"
        ),
        BuiltInSkillRepository(
            name: "Swift Testing Pro",
            gitURL: "https://github.com/twostraws/Swift-Testing-Agent-Skill",
            skillFolderName: "swift-testing-pro",
            slug: "swift-testing-pro",
            usageNotes: "Testes com framework Testing (`@Test`, `#expect`)"
        ),
        BuiltInSkillRepository(
            name: "Swift Architecture",
            gitURL: "https://github.com/efremidze/swift-architecture-skill",
            skillFolderName: "swift-architecture-skill",
            slug: "swift-architecture-skill",
            usageNotes: "MVVM, estrutura de pastas, decisões de arquitetura"
        ),
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: didSeedKey) else { return }

        let descriptor = FetchDescriptor<SkillRepository>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingSlugs = Set(existing.map(\.slug))

        for builtIn in builtInRepositories where !existingSlugs.contains(builtIn.slug) {
            let repo = SkillRepository(
                name: builtIn.name,
                gitURL: builtIn.gitURL,
                skillFolderName: builtIn.skillFolderName,
                slug: builtIn.slug,
                isBuiltIn: true,
                notes: builtIn.usageNotes
            )
            context.insert(repo)
        }

        syncBuiltInUsageNotes(in: existing)
        try? context.save()
        UserDefaults.standard.set(true, forKey: didSeedKey)
    }

    @MainActor
    static func restoreBuiltInRepositories(context: ModelContext) {
        let descriptor = FetchDescriptor<SkillRepository>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingSlugs = Set(existing.map(\.slug))

        for builtIn in builtInRepositories where !existingSlugs.contains(builtIn.slug) {
            context.insert(
                SkillRepository(
                    name: builtIn.name,
                    gitURL: builtIn.gitURL,
                    skillFolderName: builtIn.skillFolderName,
                    slug: builtIn.slug,
                    isBuiltIn: true,
                    notes: builtIn.usageNotes
                )
            )
        }
        syncBuiltInUsageNotes(in: existing)
        try? context.save()
    }

    /// Atualiza `notes` de built-ins já seedados antes de termos hints de uso.
    @MainActor
    private static func syncBuiltInUsageNotes(in existing: [SkillRepository]) {
        let notesBySlug = Dictionary(uniqueKeysWithValues: builtInRepositories.map { ($0.slug, $0.usageNotes) })
        for repo in existing where repo.isBuiltIn {
            guard let notes = notesBySlug[repo.slug] else { continue }
            if repo.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                repo.notes = notes
            }
        }
    }
}
