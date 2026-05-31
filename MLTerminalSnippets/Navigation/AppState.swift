//
//  AppState.swift
//  MLTerminalSnippets
//

import Foundation
import Observation
import SwiftUI

enum RepositoryInspectorMode: Equatable {
    case none
    case view
    case edit
    case create
}

enum SSHInspectorMode: Equatable {
    case none
    case view
    case edit
    case create
}

enum ProjectDetailMode: Equatable {
    case none
    case viewing
    case creating
    case success(path: String)

    static func == (lhs: ProjectDetailMode, rhs: ProjectDetailMode) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.viewing, .viewing), (.creating, .creating):
            return true
        case (.success(let a), .success(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct ProjectCreationDraft: Equatable {
    var name: String = ""
    var contextMarkdown: String = ""
    var selectedSkillIDs: Set<UUID> = []
    var ideTool: IDETool = .cursor
    var swiftProjectKind: SwiftProjectKind = .macOSApp
    var parentDirectoryURL: URL?
    var parentDirectoryDisplay: String = ""
    var gitInit: Bool = true
    var installSkills: Bool = true
    var currentStep: Int = 0

    static let stepCount = 5
}

@Observable
@MainActor
final class AppState {
    var activeSection: AppSection = .home
    var columnVisibility: NavigationSplitViewVisibility = .all

    var listSearchText: String = ""
    var syncStatusMessage: String = "iCloud"
    var syncStatusIsError: Bool = false

    var selectedRepositoryID: UUID?
    var repositoryInspectorMode: RepositoryInspectorMode = .none

    var selectedProjectID: UUID?
    var projectDetailMode: ProjectDetailMode = .none
    var projectDraft: ProjectCreationDraft = ProjectCreationDraft()

    var selectedSSHConnectionID: UUID?
    var sshInspectorMode: SSHInspectorMode = .none
    var sshLaunchErrorMessage: String?

    var isGeneratingProject: Bool = false
    var generationLog: [String] = []
    var generationProgress: String = ""
    var lastErrorMessage: String?
    var lastErrorLog: String?

    var focusSearchTrigger: Bool = false

    func navigateTo(_ section: AppSection) {
        activeSection = section
    }

    func startNewRepository() {
        activeSection = .repositories
        selectedRepositoryID = nil
        repositoryInspectorMode = .create
    }

    func startNewProject() {
        activeSection = .projects
        selectedProjectID = nil
        projectDetailMode = .creating
        projectDraft = ProjectCreationDraft()
    }

    func resetProjectDraft() {
        projectDraft = ProjectCreationDraft()
        projectDetailMode = .creating
    }

    func startNewSSHConnection() {
        activeSection = .sshConnections
        selectedSSHConnectionID = nil
        sshInspectorMode = .create
    }
}
