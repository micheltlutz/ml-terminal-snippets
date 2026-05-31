//
//  ProjectWizardValidatorTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

@MainActor
struct ProjectWizardValidatorTests {
    @Test(.tags(.validation), arguments: [
        (0, false),
        (1, false),
        (2, false),
        (3, false),
        (4, false),
    ])
    func emptyDraftBlocksAllSteps(step: Int, expected: Bool) {
        let draft = ProjectCreationDraft()
        #expect(ProjectWizardValidator.canAdvance(step: step, draft: draft) == expected)
    }

    @Test(.tags(.validation))
    func identityStepRequiresNonEmptyName() {
        var draft = ProjectCreationDraft()
        #expect(ProjectWizardValidator.canAdvance(step: 0, draft: draft) == false)

        draft.name = "   "
        #expect(ProjectWizardValidator.canAdvance(step: 0, draft: draft) == false)

        draft.name = "MyApp"
        #expect(ProjectWizardValidator.canAdvance(step: 0, draft: draft))
    }

    @Test(.tags(.validation))
    func skillsStepRequiresSelection() {
        var draft = ProjectCreationDraft()
        draft.name = "App"
        draft.contextMarkdown = "Contexto"
        #expect(ProjectWizardValidator.canAdvance(step: 2, draft: draft) == false)

        draft.selectedSkillIDs = [UUID()]
        #expect(ProjectWizardValidator.canAdvance(step: 2, draft: draft))
    }

    @Test(.tags(.validation))
    func destinationStepRequiresParentFolder() {
        var draft = ProjectCreationDraft()
        draft.name = "App"
        #expect(ProjectWizardValidator.canAdvance(step: 3, draft: draft) == false)

        draft.parentDirectoryURL = FileManager.default.temporaryDirectory
        #expect(ProjectWizardValidator.canAdvance(step: 3, draft: draft))
    }

    @Test(.tags(.validation))
    func canGenerateBlocksExistingDirectoryUnlessRecreateEnabled() throws {
        let parent = try TempDirectory(prefix: "wizard-dest")
        let draftName = "ExistingProject"
        try FileManager.default.createDirectory(
            at: parent.url.appendingPathComponent(draftName, isDirectory: true),
            withIntermediateDirectories: true
        )

        var draft = ProjectCreationDraft()
        draft.name = draftName
        draft.parentDirectoryURL = parent.url
        draft.recreateIfExists = false

        #expect(ProjectWizardValidator.canGenerate(draft: draft) == false)

        draft.recreateIfExists = true
        #expect(ProjectWizardValidator.canGenerate(draft: draft))
    }

    @Test(.tags(.validation), arguments: [
        (0, "Identidade"),
        (1, "Contexto"),
        (2, "Skills"),
        (3, "Destino"),
        (4, "Revisão"),
        (99, ""),
    ])
    func stepTitles(step: Int, expectedTitle: String) {
        #expect(ProjectWizardValidator.stepTitle(step) == expectedTitle)
    }

    @Test(.tags(.validation))
    func destinationURLCombinesParentAndTrimmedName() throws {
        let parent = try TempDirectory(prefix: "wizard-url")
        var draft = ProjectCreationDraft()
        draft.parentDirectoryURL = parent.url
        draft.name = "  TrimMe  "

        let destination = try #require(ProjectWizardValidator.destinationURL(for: draft))
        #expect(destination.lastPathComponent == "TrimMe")
        #expect(destination.deletingLastPathComponent().path == parent.url.path)
    }
}
