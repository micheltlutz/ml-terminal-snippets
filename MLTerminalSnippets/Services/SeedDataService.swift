//
//  SeedDataService.swift
//  MLTerminalSnippets
//

import Foundation
import SwiftData

enum SeedDataService {
    private static let didSeedKey = "MLTerminalSnippets.didSeedBuiltInRepositories"

    struct BuiltInRepository {
        let name: String
        let gitURL: String
        let skillFolderName: String
        let slug: String
    }

    static let builtInRepositories: [BuiltInRepository] = [
        BuiltInRepository(
            name: "SwiftUI Pro",
            gitURL: "https://github.com/twostraws/SwiftUI-Agent-Skill",
            skillFolderName: "swiftui-pro",
            slug: "swiftui-pro"
        ),
        BuiltInRepository(
            name: "SwiftData Pro",
            gitURL: "https://github.com/twostraws/SwiftData-Agent-Skill",
            skillFolderName: "swiftdata-pro",
            slug: "swiftdata-pro"
        ),
        BuiltInRepository(
            name: "Swift Concurrency Pro",
            gitURL: "https://github.com/twostraws/Swift-Concurrency-Agent-Skill",
            skillFolderName: "swift-concurrency-pro",
            slug: "swift-concurrency-pro"
        ),
        BuiltInRepository(
            name: "Swift Testing Pro",
            gitURL: "https://github.com/twostraws/Swift-Testing-Agent-Skill",
            skillFolderName: "swift-testing-pro",
            slug: "swift-testing-pro"
        ),
        BuiltInRepository(
            name: "Swift Architecture",
            gitURL: "https://github.com/efremidze/swift-architecture-skill",
            skillFolderName: "swift-architecture-skill",
            slug: "swift-architecture-skill"
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
                isBuiltIn: true
            )
            context.insert(repo)
        }

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
                    isBuiltIn: true
                )
            )
        }
        try? context.save()
    }
}
