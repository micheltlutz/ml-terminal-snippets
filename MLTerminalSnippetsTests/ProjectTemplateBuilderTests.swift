//
//  ProjectTemplateBuilderTests.swift
//  MLTerminalSnippetsTests
//

import Testing
@testable import MLTerminalSnippets

@MainActor
struct ProjectTemplateBuilderTests {
    private let cursorLayout = IDEProjectLayout.layout(for: .cursor)

    @Test(.tags(.templates))
    func readmeContainsProjectContextAndSkillsTable() {
        let md = ProjectTemplateBuilder.readme(
            projectName: "MyApp",
            context: "Contexto de teste",
            skills: [SkillFixtures.swiftUIPro],
            swiftProjectKind: .macOSApp,
            layout: cursorLayout,
            installSkillsFailed: false
        )
        #expect(md.contains("# MyApp"))
        #expect(md.contains("Contexto de teste"))
        #expect(md.contains("swiftui-pro"))
        #expect(md.contains("Views SwiftUI"))
        #expect(md.contains("docs/xcode-setup.md"))
        #expect(md.contains("| Skill | Quando usar | Repositório |"))
    }

    @Test(.tags(.templates))
    func readmeNotesCacheFailureWhenInstallSkillsFailed() {
        let md = ProjectTemplateBuilder.readme(
            projectName: "App",
            context: "ctx",
            skills: [SkillFixtures.swiftUIPro],
            swiftProjectKind: .macOSApp,
            layout: cursorLayout,
            installSkillsFailed: true
        )
        #expect(md.contains("cópia automática do cache local falhou"))
    }

    @Test(.tags(.templates))
    func agentsMDListsSkillsWithWhenToUseAndPaths() {
        let md = ProjectTemplateBuilder.agentsMD(
            projectName: "ArchApp",
            context: "App com MVVM",
            skills: [SkillFixtures.swiftArchitecture],
            swiftProjectKind: .macOSApp,
            layout: cursorLayout
        )
        #expect(md.contains("ArchApp"))
        #expect(md.contains("swift-architecture-skill"))
        #expect(md.contains("| Skill | Quando usar | Caminho |"))
        #expect(md.contains("MVVM, estrutura de pastas"))
        #expect(md.contains(".cursor/skills/swift-architecture-skill/SKILL.md"))
        #expect(md.contains("npx skills add"))
    }

    @Test(.tags(.templates))
    func agentsMDIncludesSwiftPackageGuidanceForSPM() {
        let md = ProjectTemplateBuilder.agentsMD(
            projectName: "Lib",
            context: "Package",
            skills: [SkillFixtures.swiftUIPro],
            swiftProjectKind: .swiftPackage,
            layout: cursorLayout
        )
        #expect(md.contains("swift package init"))
    }

    @Test(.tags(.scaffold, .templates))
    func fileTreePreviewListsSelectedSkillSlug() {
        let skill = SkillFixtures.custom(slug: "test-skill")
        let lines = ProjectScaffolder.fileTreePreview(
            projectName: "Demo",
            swiftProjectKind: .macOSApp,
            ideTool: .cursor,
            skills: [skill]
        )
        #expect(lines.first?.contains("Demo/") == true)
        #expect(lines.contains { $0.contains("AGENTS.md") })
        #expect(lines.contains { $0.contains("test-skill") })
    }

    @Test(.tags(.validation))
    func repositoryFormValidationAcceptsValidGitHubURL() {
        var draft = RepositoryFormDraft()
        draft.name = "Test"
        draft.gitURL = "https://github.com/foo/bar"
        draft.skillFolderName = "skill"
        draft.slug = "skill"
        #expect(draft.isValid)
        #expect(draft.urlError == nil)
    }

    @Test(.tags(.validation))
    func repositoryFormValidationRejectsInvalidURL() {
        var draft = RepositoryFormDraft()
        draft.name = "Test"
        draft.gitURL = "not-a-url"
        draft.skillFolderName = "skill"
        draft.slug = "skill"
        #expect(draft.isValid == false)
        #expect(draft.urlError != nil)
    }

    @Test(.tags(.skills))
    func skillScaffoldItemWhenToUseFallbackWhenNotesEmpty() {
        let skill = SkillFixtures.custom(slug: "custom")
        #expect(skill.whenToUseDisplay.contains("relacionado a este skill"))
    }
}
