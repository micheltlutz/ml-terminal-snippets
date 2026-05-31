//
//  ProjectWizardValidator.swift
//  MLTerminalSnippets
//

import Foundation

enum ProjectWizardValidator: Sendable {
    nonisolated static func canAdvance(step: Int, draft: ProjectCreationDraft) -> Bool {
        switch step {
        case 0: return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return !draft.contextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return !draft.selectedSkillIDs.isEmpty
        case 3: return draft.parentDirectoryURL != nil
        case 4: return canGenerate(draft: draft)
        default: return false
        }
    }

    nonisolated static func destinationURL(for draft: ProjectCreationDraft) -> URL? {
        guard let parent = draft.parentDirectoryURL else { return nil }
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return parent.appendingPathComponent(trimmed, isDirectory: true)
    }

    nonisolated static func destinationAlreadyExists(draft: ProjectCreationDraft) -> Bool {
        guard let url = destinationURL(for: draft) else { return false }
        let parent = url.deletingLastPathComponent()
        let accessed = parent.startAccessingSecurityScopedResource()
        defer {
            if accessed { parent.stopAccessingSecurityScopedResource() }
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    /// Bloqueia geração se a pasta de destino já existe e o usuário não optou por recriar.
    nonisolated static func canGenerate(draft: ProjectCreationDraft) -> Bool {
        guard draft.parentDirectoryURL != nil else { return false }
        if destinationAlreadyExists(draft: draft) {
            return draft.recreateIfExists
        }
        return true
    }

    nonisolated static func stepTitle(_ step: Int) -> String {
        switch step {
        case 0: "Identidade"
        case 1: "Contexto"
        case 2: "Skills"
        case 3: "Destino"
        case 4: "Revisão"
        default: ""
        }
    }
}
