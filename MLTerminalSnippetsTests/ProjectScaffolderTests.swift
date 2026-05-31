//
//  ProjectScaffolderTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

@MainActor
struct ProjectScaffolderTests {
    @Test(.tags(.scaffold), arguments: ["", "  ", "bad/name", ".hidden", "../escape"])
    func scaffoldRejectsInvalidName(invalidName: String) async throws {
        let parent = try TempDirectory(prefix: "scaffold-invalid-name")
        let request = ScaffoldFixtures.request(name: invalidName, parent: parent.url)

        await #expect(throws: ProjectScaffolderError.self) {
            try await ProjectScaffolder.scaffold(request)
        }
    }

    @Test(.tags(.scaffold))
    func scaffoldCreatesProjectStructureWithoutSkills() async throws {
        let parent = try TempDirectory(prefix: "scaffold-happy")
        let request = ScaffoldFixtures.request(
            name: "MyAgentProject",
            parent: parent.url,
            skills: [],
            installSkills: false
        )

        let result = try await ProjectScaffolder.scaffold(request)
        let projectURL = result.projectURL

        #expect(FileManager.default.fileExists(atPath: projectURL.path))
        #expect(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("README.md").path))
        #expect(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("AGENTS.md").path))
        #expect(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent(".gitignore").path))
        #expect(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("docs/xcode-setup.md").path))
        #expect(result.installFailures.isEmpty)
        #expect(result.logLines.isEmpty == false)
    }

    @Test(.tags(.scaffold, .skills))
    func scaffoldCopiesSkillsFromUserCache() async throws {
        let slug = "scaffold-skill-\(UUID().uuidString)"
        let parent = try TempDirectory(prefix: "scaffold-skills")
        let cacheSource = try TempDirectory(prefix: "scaffold-cache-src")
        defer { try? FileManager.default.removeItem(at: SkillCacheService.userCacheDirectory(for: slug)) }

        try "# Cached".write(
            to: cacheSource.url.appendingPathComponent("SKILL.md"),
            atomically: true,
            encoding: .utf8
        )
        try SkillCacheService.importToUserCache(from: cacheSource.url, slug: slug)

        let request = ScaffoldFixtures.request(
            name: "WithSkills",
            parent: parent.url,
            skills: [SkillFixtures.custom(slug: slug)],
            installSkills: true
        )

        let result = try await ProjectScaffolder.scaffold(request)
        let skillFile = result.projectURL
            .appendingPathComponent(".cursor/skills/\(slug)/SKILL.md")

        #expect(result.installFailures.isEmpty)
        #expect(FileManager.default.fileExists(atPath: skillFile.path))
    }

    @Test(.tags(.scaffold))
    func scaffoldFailsWhenDirectoryExistsWithoutRecreateFlag() async throws {
        let parent = try TempDirectory(prefix: "scaffold-exists")
        let existing = parent.url.appendingPathComponent("Existing", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)

        let request = ScaffoldFixtures.request(
            name: "Existing",
            parent: parent.url,
            recreateIfExists: false
        )

        await #expect(throws: ProjectScaffolderError.self) {
            try await ProjectScaffolder.scaffold(request)
        }
    }

    @Test(.tags(.scaffold))
    func scaffoldRecreatesDirectoryWhenFlagEnabled() async throws {
        let parent = try TempDirectory(prefix: "scaffold-recreate")
        let existing = parent.url.appendingPathComponent("RecreateMe", isDirectory: true)
        try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
        try "old".write(
            to: existing.appendingPathComponent("old.txt"),
            atomically: true,
            encoding: .utf8
        )

        let request = ScaffoldFixtures.request(
            name: "RecreateMe",
            parent: parent.url,
            recreateIfExists: true
        )

        let result = try await ProjectScaffolder.scaffold(request)
        #expect(FileManager.default.fileExists(atPath: result.projectURL.path))
        #expect(
            FileManager.default.fileExists(atPath: result.projectURL.appendingPathComponent("old.txt").path) == false
        )
        #expect(FileManager.default.fileExists(atPath: result.projectURL.appendingPathComponent("README.md").path))
    }
}
