//
//  AppShellView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct AppShellView: View {
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var repositories: [SkillRepository]
    @Query private var projects: [SnippetProject]
    @Query private var sshConnections: [SSHConnection]

    var body: some View {
        NavigationSplitView(columnVisibility: $appState.columnVisibility) {
            AppSidebarView(appState: appState)
        } content: {
            contentColumn
                .navigationSplitViewColumnWidth(min: 260, ideal: 300)
        } detail: {
            detailColumn
        }
        .onAppear {
            SeedDataService.seedIfNeeded(context: modelContext)
            appState.syncStatusMessage = "Sincronizado via iCloud"
        }
        .onChange(of: appState.activeSection) { _, _ in
            appState.listSearchText = ""
        }
        .focusedSceneValue(\.appState, appState)
    }

    @ViewBuilder
    private var contentColumn: some View {
        switch appState.activeSection {
        case .home:
            HomeView(appState: appState)
        case .repositories:
            RepositoryListView(appState: appState)
        case .projects:
            ProjectListView(appState: appState)
        case .sshConnections:
            SSHConnectionListView(appState: appState)
        case .settings:
            SettingsPlaceholderView(appState: appState)
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        switch appState.activeSection {
        case .home:
            HomeView(appState: appState)
        case .repositories:
            repositoryDetail
        case .projects:
            projectDetail
        case .sshConnections:
            sshDetail
        case .settings:
            SettingsPlaceholderView(appState: appState)
        }
    }

    @ViewBuilder
    private var repositoryDetail: some View {
        let selected = repositories.first { $0.id == appState.selectedRepositoryID }
        RepositoryInspectorView(appState: appState, repository: selected)
    }

    @ViewBuilder
    private var sshDetail: some View {
        let selected = sshConnections.first { $0.id == appState.selectedSSHConnectionID }
        SSHConnectionInspectorView(appState: appState, connection: selected)
    }

    @ViewBuilder
    private var projectDetail: some View {
        switch appState.projectDetailMode {
        case .creating, .success:
            ProjectCreationFlowView(appState: appState)
        case .viewing, .none:
            let selected = projects.first { $0.id == appState.selectedProjectID }
            if appState.selectedProjectID != nil {
                ProjectDetailInspectorView(appState: appState, project: selected)
            } else if appState.projectDetailMode == .none {
                EmptyStateView(
                    systemImage: "folder.badge.plus",
                    title: "Projetos",
                    message: "Selecione um projeto ou crie um novo com o wizard.",
                    actionTitle: "Novo projeto",
                    action: { appState.startNewProject() }
                )
            } else {
                ProjectDetailInspectorView(appState: appState, project: selected)
            }
        }
    }
}

private struct AppStateFocusedKey: FocusedValueKey {
    typealias Value = AppState
}

extension FocusedValues {
    var appState: AppState? {
        get { self[AppStateFocusedKey.self] }
        set { self[AppStateFocusedKey.self] = newValue }
    }
}

struct AppCommands: Commands {
    @FocusedValue(\.appState) private var appState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Novo") {
                guard let appState else { return }
                switch appState.activeSection {
                case .repositories: appState.startNewRepository()
                case .projects: appState.startNewProject()
                case .sshConnections: appState.startNewSSHConnection()
                default: appState.startNewProject()
                }
            }
            .keyboardShortcut("n", modifiers: .command)
        }
    }
}
