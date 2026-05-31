//
//  SnippetProject.swift
//  MLTerminalSnippets
//

import Foundation
import SwiftData

/// CloudKit: todas as propriedades com valor padrão; sem `@Attribute(.unique)`.
@Model
final class SnippetProject {
    var id: UUID = UUID()
    var name: String = ""
    var contextMarkdown: String = ""
    var outputPathBookmark: Data?
    var outputPathDisplay: String = ""
    var ideToolRaw: String = IDETool.cursor.rawValue
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var gitInitOnGenerate: Bool = true
    var installSkillsOnGenerate: Bool = true

    @Relationship(deleteRule: .nullify)
    var selectedSkills: [SkillRepository]?

    init(
        id: UUID = UUID(),
        name: String,
        contextMarkdown: String,
        outputPathBookmark: Data? = nil,
        outputPathDisplay: String = "",
        ideTool: IDETool = .cursor,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        gitInitOnGenerate: Bool = true,
        installSkillsOnGenerate: Bool = true,
        selectedSkills: [SkillRepository]? = nil
    ) {
        self.id = id
        self.name = name
        self.contextMarkdown = contextMarkdown
        self.outputPathBookmark = outputPathBookmark
        self.outputPathDisplay = outputPathDisplay
        self.ideToolRaw = ideTool.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.gitInitOnGenerate = gitInitOnGenerate
        self.installSkillsOnGenerate = installSkillsOnGenerate
        self.selectedSkills = selectedSkills
    }

    var ideTool: IDETool {
        get { IDETool(rawValue: ideToolRaw) ?? .cursor }
        set { ideToolRaw = newValue.rawValue }
    }

    func touch() {
        updatedAt = .now
    }

    var skillCount: Int {
        selectedSkills?.count ?? 0
    }
}
