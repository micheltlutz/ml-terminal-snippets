//
//  ScaffoldFixtures.swift
//  MLTerminalSnippetsTests
//

import Foundation
@testable import MLTerminalSnippets

enum ScaffoldFixtures {
    nonisolated static func request(
        name: String = "TestProject",
        parent: URL,
        skills: [SkillScaffoldItem] = [SkillFixtures.swiftUIPro],
        installSkills: Bool = false,
        recreateIfExists: Bool = false,
        kind: SwiftProjectKind = .macOSApp
    ) -> ProjectScaffoldRequest {
        ProjectScaffoldRequest(
            name: name,
            contextMarkdown: "Contexto de teste",
            skills: skills,
            parentDirectory: parent,
            ideTool: .cursor,
            swiftProjectKind: kind,
            recreateIfExists: recreateIfExists,
            installSkills: installSkills
        )
    }
}
