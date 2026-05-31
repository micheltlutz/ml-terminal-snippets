//
//  SkillFixtures.swift
//  MLTerminalSnippetsTests
//

import Foundation
@testable import MLTerminalSnippets

enum SkillFixtures {
    nonisolated static let swiftUIPro = SkillScaffoldItem(
        name: "SwiftUI Pro",
        gitURL: "https://github.com/twostraws/SwiftUI-Agent-Skill",
        skillFolderName: "swiftui-pro",
        slug: "swiftui-pro",
        usageNotes: "Views SwiftUI, navegação, acessibilidade, performance de UI"
    )

    nonisolated static let swiftArchitecture = SkillScaffoldItem(
        name: "Swift Architecture",
        gitURL: "https://github.com/efremidze/swift-architecture-skill",
        skillFolderName: "swift-architecture-skill",
        slug: "swift-architecture-skill",
        usageNotes: "MVVM, estrutura de pastas, decisões de arquitetura"
    )

    nonisolated static func custom(
        slug: String,
        name: String = "Custom Skill",
        usageNotes: String = ""
    ) -> SkillScaffoldItem {
        SkillScaffoldItem(
            name: name,
            gitURL: "https://github.com/example/\(slug)",
            skillFolderName: slug,
            slug: slug,
            usageNotes: usageNotes
        )
    }
}
