//
//  ProjectTemplateBuilderTests.swift
//  MLTerminalSnippetsTests
//

import Testing
@testable import MLTerminalSnippets

struct ProjectTemplateBuilderTests {
    @Test func readmeContainsProjectName() {
        let skill = SkillScaffoldItem(
            name: "SwiftUI Pro",
            gitURL: "https://github.com/twostraws/SwiftUI-Agent-Skill",
            skillFolderName: "swiftui-pro",
            slug: "swiftui-pro"
        )
        let md = ProjectTemplateBuilder.readme(
            projectName: "MyApp",
            context: "Contexto de teste",
            skills: [skill],
            swiftProjectKind: .macOSApp,
            layout: IDEProjectLayout.layout(for: .cursor),
            installSkillsFailed: false
        )
        #expect(md.contains("# MyApp"))
        #expect(md.contains("Contexto de teste"))
        #expect(md.contains("swiftui-pro"))
    }

    @Test func agentsMDListsSkills() {
        let skill = SkillScaffoldItem(
            name: "Swift Architecture",
            gitURL: "https://github.com/efremidze/swift-architecture-skill",
            skillFolderName: "swift-architecture-skill",
            slug: "swift-architecture-skill"
        )
        let md = ProjectTemplateBuilder.agentsMD(
            projectName: "ArchApp",
            context: "App com MVVM",
            skills: [skill],
            swiftProjectKind: .macOSApp,
            layout: IDEProjectLayout.layout(for: .cursor)
        )
        #expect(md.contains("ArchApp"))
        #expect(md.contains("swift-architecture-skill"))
    }

    @Test func fileTreePreviewStructure() {
        let skill = SkillScaffoldItem(
            name: "Test",
            gitURL: "https://github.com/example/repo",
            skillFolderName: "test-skill",
            slug: "test-skill"
        )
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

    @Test func repositorySlugGeneration() {
        #expect(SkillRepository.slug(from: "SwiftUI Pro") == "swiftui-pro")
    }

    @Test func repositoryFormValidation() {
        var draft = RepositoryFormDraft()
        draft.name = "Test"
        draft.gitURL = "https://github.com/foo/bar"
        draft.skillFolderName = "skill"
        draft.slug = "skill"
        #expect(draft.isValid)
        #expect(draft.urlError == nil)
    }

    @Test func wizardValidatorSteps() {
        var draft = ProjectCreationDraft()
        #expect(ProjectWizardValidator.canAdvance(step: 0, draft: draft) == false)
        draft.name = "App"
        #expect(ProjectWizardValidator.canAdvance(step: 0, draft: draft))
    }
}
