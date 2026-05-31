//
//  RepositoryListView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct RepositoryListView: View {
    @Bindable var appState: AppState
    @Query(sort: \SkillRepository.name) private var allRepositories: [SkillRepository]
    @Environment(\.modelContext) private var modelContext

    private var filtered: [SkillRepository] {
        let q = appState.listSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allRepositories }
        return allRepositories.filter {
            $0.name.lowercased().contains(q)
                || $0.gitURL.lowercased().contains(q)
                || $0.slug.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $appState.listSearchText, placeholder: "Buscar repositórios")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            if filtered.isEmpty {
                EmptyStateView(
                    systemImage: "books.vertical",
                    title: allRepositories.isEmpty ? "Nenhum repositório" : "Sem resultados",
                    message: allRepositories.isEmpty
                        ? "Adicione repositórios Git de Agent Skills para usar nos projetos."
                        : "Tente outro termo de busca.",
                    actionTitle: allRepositories.isEmpty ? "Adicionar primeiro repositório" : nil,
                    action: allRepositories.isEmpty ? { appState.startNewRepository() } : nil
                )
            } else {
                List(selection: $appState.selectedRepositoryID) {
                    ForEach(filtered) { repo in
                        RepositoryRowView(repository: repo)
                            .tag(repo.id)
                            .contextMenu {
                                Button("Editar") {
                                    appState.selectedRepositoryID = repo.id
                                    appState.repositoryInspectorMode = .edit
                                }
                                Button("Duplicar") { duplicate(repo) }
                                Divider()
                                Button("Excluir", role: .destructive) {
                                    delete(repo)
                                }
                            }
                    }
                }
                .listStyle(.inset)
                .onChange(of: appState.selectedRepositoryID) { _, newID in
                    if newID != nil, appState.repositoryInspectorMode == .none {
                        appState.repositoryInspectorMode = .view
                    }
                }
            }
        }
        .navigationTitle("Repositórios")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.startNewRepository()
                } label: {
                    Label("Novo", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("Novo repositório (⌘N)")
            }
        }
    }

    private func duplicate(_ repo: SkillRepository) {
        let copy = SkillRepository(
            name: repo.name + " (cópia)",
            gitURL: repo.gitURL,
            skillFolderName: repo.skillFolderName,
            slug: repo.slug + "-copy-\(Int.random(in: 1000...9999))",
            isBuiltIn: false,
            notes: repo.notes
        )
        modelContext.insert(copy)
        try? modelContext.save()
        appState.selectedRepositoryID = copy.id
        appState.repositoryInspectorMode = .edit
    }

    private func delete(_ repo: SkillRepository) {
        if appState.selectedRepositoryID == repo.id {
            appState.selectedRepositoryID = nil
            appState.repositoryInspectorMode = .none
        }
        modelContext.delete(repo)
        try? modelContext.save()
    }
}

struct RepositoryRowView: View {
    let repository: SkillRepository

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: repository.isBuiltIn ? "star.fill" : "book.closed")
                .foregroundStyle(repository.isBuiltIn ? .yellow : .secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(repository.name)
                    .font(.body)
                Text(repository.slug)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
