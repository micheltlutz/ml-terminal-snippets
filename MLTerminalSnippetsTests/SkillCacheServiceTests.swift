//
//  SkillCacheServiceTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

@MainActor
struct SkillCacheServiceTests {
    @Test(.tags(.skills))
    func skillContentValidatorFindsNestedSkillMarkdown() throws {
        let temp = try TempDirectory(prefix: "nested-skill")
        let nested = temp.url.appendingPathComponent("swiftui-pro", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "# Skill".write(to: nested.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let found = SkillContentValidator.skillMarkdownURL(in: temp.url)
        #expect(found?.lastPathComponent == "SKILL.md")
    }

    @Test(.tags(.skills))
    func skillContentValidatorRejectsEmptyDirectory() throws {
        let temp = try TempDirectory(prefix: "empty-skill")
        #expect(SkillContentValidator.isValidSkillDirectory(temp.url) == false)
    }

    @Test(.tags(.skills))
    func importAndCopyToProject() throws {
        let slug = "test-skill-\(UUID().uuidString)"
        let sourceRoot = try TempDirectory(prefix: "skill-src")
        let projectRoot = try TempDirectory(prefix: "skill-proj")
        defer { try? FileManager.default.removeItem(at: SkillCacheService.userCacheDirectory(for: slug)) }

        try "# Test Skill".write(
            to: sourceRoot.url.appendingPathComponent("SKILL.md"),
            atomically: true,
            encoding: .utf8
        )
        try SkillCacheService.importToUserCache(from: sourceRoot.url, slug: slug)

        let skill = SkillFixtures.custom(slug: slug)
        let skillsRoot = projectRoot.url.appendingPathComponent(".cursor/skills", isDirectory: true)
        let failures = try SkillCacheService.installFromCache(skills: [skill], skillsRoot: skillsRoot)

        #expect(failures.isEmpty)
        let dest = skillsRoot.appendingPathComponent("\(slug)/SKILL.md")
        #expect(FileManager.default.fileExists(atPath: dest.path))
    }

    @Test(.tags(.skills))
    func importRejectsFolderWithoutSkillMarkdown() throws {
        let slug = "invalid-skill-\(UUID().uuidString)"
        let temp = try TempDirectory(prefix: "invalid-import")
        defer { try? FileManager.default.removeItem(at: SkillCacheService.userCacheDirectory(for: slug)) }

        try "readme".write(
            to: temp.url.appendingPathComponent("README.md"),
            atomically: true,
            encoding: .utf8
        )

        #expect(throws: SkillCacheError.self) {
            try SkillCacheService.importToUserCache(from: temp.url, slug: slug)
        }
    }

    @Test(.tags(.skills))
    func installFailsWhenCacheMissing() throws {
        let projectRoot = try TempDirectory(prefix: "cache-miss")
        let skill = SkillFixtures.custom(slug: "missing-skill-xyz-\(UUID().uuidString)")

        let failures = try SkillCacheService.installFromCache(
            skills: [skill],
            skillsRoot: projectRoot.url.appendingPathComponent(".cursor/skills", isDirectory: true)
        )

        #expect(failures.count == 1)
        #expect(failures.first?.skillName == skill.name)
        #expect(failures.first?.reason.contains("cache local") == true)
    }

    @Test(.tags(.skills, .smoke))
    func userCacheOverridesBundledSource() throws {
        let slug = "swiftui-pro"
        let userSource = try TempDirectory(prefix: "user-override")
        defer { try? FileManager.default.removeItem(at: SkillCacheService.userCacheDirectory(for: slug)) }

        let marker = "# User override marker"
        try marker.write(
            to: userSource.url.appendingPathComponent("SKILL.md"),
            atomically: true,
            encoding: .utf8
        )
        try SkillCacheService.importToUserCache(from: userSource.url, slug: slug)

        let resolved = try #require(SkillCacheService.resolveSource(for: SkillFixtures.swiftUIPro))
        #expect(resolved.location == .userCache)

        let content = try String(
            contentsOf: resolved.url.appendingPathComponent("SKILL.md"),
            encoding: .utf8
        )
        #expect(content == marker)
    }

    @Test(.tags(.skills, .smoke))
    func bundledBuiltInSkillsAreAvailableInAppBundle() {
        for builtIn in SeedDataService.builtInRepositories {
            let directory = SkillCacheService.bundledSkillDirectory(slug: builtIn.slug)
            #expect(
                directory != nil,
                "Skill built-in ausente no bundle: \(builtIn.slug)"
            )
        }
    }
}
