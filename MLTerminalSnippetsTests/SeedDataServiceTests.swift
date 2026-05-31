//
//  SeedDataServiceTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

@MainActor
struct SeedDataServiceTests {
    @Test(.tags(.skills, .smoke))
    func builtInRepositoriesHaveUniqueSlugs() {
        let slugs = SeedDataService.builtInRepositories.map(\.slug)
        #expect(Set(slugs).count == slugs.count, "Slugs built-in duplicados")
        #expect(slugs.count == 5)
    }

    @Test(.tags(.skills))
    func builtInRepositoriesIncludeUsageNotes() {
        for builtIn in SeedDataService.builtInRepositories {
            #expect(
                builtIn.usageNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                "Falta usageNotes em \(builtIn.slug)"
            )
        }
    }

    @Test(.tags(.skills), arguments: [
        ("SwiftUI Pro", "swiftui-pro"),
        ("SwiftData Pro", "swiftdata-pro"),
        ("Swift Concurrency Pro", "swift-concurrency-pro"),
    ])
    func repositorySlugGeneration(name: String, expectedSlug: String) {
        #expect(SkillRepository.slug(from: name) == expectedSlug)
    }
}
