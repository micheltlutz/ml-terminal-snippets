//
//  RepositoryFormDraft.swift
//  MLTerminalSnippets
//

import Foundation

struct RepositoryFormDraft: Equatable, Sendable {
    var name: String = ""
    var gitURL: String = ""
    var skillFolderName: String = ""
    var slug: String = ""
    var notes: String = ""

    init() {}

    @MainActor
    init(from repository: SkillRepository) {
        name = repository.name
        gitURL = repository.gitURL
        skillFolderName = repository.skillFolderName
        slug = repository.slug
        notes = repository.notes
    }

    var nameError: String? {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nome obrigatório" : nil
    }

    var urlError: String? {
        let trimmed = gitURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "URL obrigatória" }
        guard let url = URL(string: trimmed),
              let host = url.host?.lowercased(),
              host.contains("github.com")
        else { return "Informe uma URL GitHub válida" }
        return nil
    }

    var folderError: String? {
        skillFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Pasta do skill obrigatória"
            : nil
    }

    var slugError: String? {
        slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Slug obrigatório" : nil
    }

    var isValid: Bool {
        nameError == nil && urlError == nil && folderError == nil && slugError == nil
    }

    mutating func syncSlugFromNameIfNeeded() {
        if slug.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            slug = SkillRepository.slug(from: name)
        }
    }
}
