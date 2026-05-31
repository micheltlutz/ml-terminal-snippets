//
//  ProjectWizardValidator.swift
//  MLTerminalSnippets
//

import Foundation

enum ProjectWizardValidator {
    static func canAdvance(step: Int, draft: ProjectCreationDraft) -> Bool {
        switch step {
        case 0: return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return !draft.contextMarkdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return !draft.selectedSkillIDs.isEmpty
        case 3: return draft.parentDirectoryURL != nil
        case 4: return true
        default: return false
        }
    }

    static func stepTitle(_ step: Int) -> String {
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
