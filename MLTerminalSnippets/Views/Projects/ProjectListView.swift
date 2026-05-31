//
//  ProjectListView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct ProjectListView: View {
    @Bindable var appState: AppState
    @Query(sort: \SnippetProject.createdAt, order: .reverse) private var allProjects: [SnippetProject]
    @Environment(\.modelContext) private var modelContext

    private var filtered: [SnippetProject] {
        let q = appState.listSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allProjects }
        return allProjects.filter {
            $0.name.lowercased().contains(q) || $0.outputPathDisplay.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $appState.listSearchText, placeholder: "Buscar projetos")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            if filtered.isEmpty {
                EmptyStateView(
                    systemImage: "folder.badge.plus",
                    title: allProjects.isEmpty ? "Nenhum projeto" : "Sem resultados",
                    message: allProjects.isEmpty
                        ? "Crie um projeto com skills, contexto e scaffold Cursor."
                        : "Tente outro termo de busca.",
                    actionTitle: allProjects.isEmpty ? "Novo projeto" : nil,
                    action: allProjects.isEmpty ? { appState.startNewProject() } : nil
                )
            } else {
                List(selection: $appState.selectedProjectID) {
                    ForEach(filtered) { project in
                        ProjectRowView(project: project)
                            .tag(project.id)
                            .contextMenu {
                                Button("Abrir no Finder") { openFinder(project) }
                                Button("Abrir no Cursor") { openCursor(project) }
                                Divider()
                                Button("Excluir do histórico", role: .destructive) {
                                    deleteProject(project)
                                }
                            }
                    }
                }
                .listStyle(.inset)
                .onChange(of: appState.selectedProjectID) { _, newID in
                    if newID != nil, appState.projectDetailMode == .none {
                        appState.projectDetailMode = .viewing
                    }
                }
            }
        }
        .navigationTitle("Projetos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.startNewProject()
                } label: {
                    Label("Novo Projeto", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }

    private func openFinder(_ project: SnippetProject) {
        guard let bookmark = project.outputPathBookmark,
              let url = BookmarkStore.resolveURL(from: bookmark)
        else { return }
        WorkspaceOpener.openInFinder(url)
    }

    private func openCursor(_ project: SnippetProject) {
        guard let bookmark = project.outputPathBookmark,
              let url = BookmarkStore.resolveURL(from: bookmark)
        else { return }
        WorkspaceOpener.openInCursor(url)
    }

    private func deleteProject(_ project: SnippetProject) {
        if appState.selectedProjectID == project.id {
            appState.selectedProjectID = nil
            appState.projectDetailMode = .none
        }
        modelContext.delete(project)
        try? modelContext.save()
    }
}

struct ProjectRowView: View {
    let project: SnippetProject

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(project.name)
                    .font(.body.weight(.medium))
                Spacer()
                Text(project.ideTool.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            if !project.outputPathDisplay.isEmpty {
                Text(project.outputPathDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Text("\(project.skillCount) skills · \(project.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
