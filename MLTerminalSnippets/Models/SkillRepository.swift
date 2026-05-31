//
//  SkillRepository.swift
//  MLTerminalSnippets
//

import Foundation
import SwiftData

/// CloudKit: todas as propriedades com valor padrão; sem `@Attribute(.unique)`.
@Model
final class SkillRepository {
    var id: UUID = UUID()
    var name: String = ""
    var gitURL: String = ""
    var skillFolderName: String = ""
    var slug: String = ""
    var isBuiltIn: Bool = false
    var notes: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(inverse: \SnippetProject.selectedSkills)
    var projects: [SnippetProject]?

    init(
        id: UUID = UUID(),
        name: String,
        gitURL: String,
        skillFolderName: String,
        slug: String,
        isBuiltIn: Bool = false,
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.gitURL = gitURL
        self.skillFolderName = skillFolderName
        self.slug = slug
        self.isBuiltIn = isBuiltIn
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func touch() {
        updatedAt = .now
    }
}

extension SkillRepository {
    static func slug(from name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    var isValidGitHubURL: Bool {
        guard let url = URL(string: gitURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = url.host?.lowercased()
        else { return false }
        return host.contains("github.com") && url.scheme?.hasPrefix("http") == true
    }
}
