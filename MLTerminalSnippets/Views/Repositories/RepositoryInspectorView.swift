//
//  RepositoryInspectorView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct RepositoryInspectorView: View {
    @Bindable var appState: AppState
    let repository: SkillRepository?
    @Environment(\.modelContext) private var modelContext

    @State private var draft = RepositoryFormDraft()
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            switch appState.repositoryInspectorMode {
            case .none:
                EmptyStateView(
                    systemImage: "sidebar.right",
                    title: "Selecione um repositório",
                    message: "Escolha um item na lista ou crie um novo repositório.",
                    actionTitle: "Novo repositório",
                    action: { appState.repositoryInspectorMode = .create; draft = RepositoryFormDraft() }
                )
            case .view, .edit, .create:
                formContent
            }
        }
        .navigationTitle(title)
        .toolbar { inspectorToolbar }
        .onAppear { loadDraft() }
        .onChange(of: appState.selectedRepositoryID) { _, _ in loadDraft() }
        .onChange(of: appState.repositoryInspectorMode) { _, _ in loadDraft() }
        .alert("Excluir repositório?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) { performDelete() }
        } message: {
            if repository?.isBuiltIn == true {
                Text("Este é um repositório recomendado. Você pode restaurá-lo em Início → Repositórios incluídos.")
            } else {
                Text("Esta ação não pode ser desfeita.")
            }
        }
    }

    private var title: String {
        switch appState.repositoryInspectorMode {
        case .create: "Novo repositório"
        case .edit: "Editar repositório"
        case .view: repository?.name ?? "Repositório"
        case .none: ""
        }
    }

    private var isEditing: Bool {
        appState.repositoryInspectorMode == .edit || appState.repositoryInspectorMode == .create
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section("Informações") {
                field("Nome", text: $draft.name, error: draft.nameError, disabled: !isEditing)
                field("URL GitHub", text: $draft.gitURL, error: draft.urlError, disabled: !isEditing)
                    .help("URL do repositório Git que contém o skill")
                field("Pasta do skill", text: $draft.skillFolderName, error: draft.folderError, disabled: !isEditing)
                    .help("Subpasta onde está o SKILL.md, ex: swiftui-pro")
                field("Slug", text: $draft.slug, error: draft.slugError, disabled: !isEditing)
                    .help("Identificador usado em .cursor/skills/")
                if isEditing {
                    notesField
                } else if !draft.notes.isEmpty {
                    LabeledContent("Notas") { Text(draft.notes) }
                }
            }

            if let repository, !isEditing {
                Section("Metadados") {
                    if repository.isBuiltIn {
                        Label("Repositório recomendado", systemImage: "star.fill")
                    }
                    LabeledContent("Criado", value: repository.createdAt.formatted())
                    LabeledContent("Atualizado", value: repository.updatedAt.formatted())
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onChange(of: draft.name) { _, _ in
            if appState.repositoryInspectorMode == .create {
                draft.syncSlugFromNameIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Notas")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $draft.notes)
                .frame(minHeight: 80)
        }
    }

    @ToolbarContentBuilder
    private var inspectorToolbar: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { cancelEdit() }
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") { save() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(!draft.isValid)
            }
        } else if repository != nil {
            ToolbarItem(placement: .primaryAction) {
                Button("Editar") {
                    appState.repositoryInspectorMode = .edit
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private func field(_ label: String, text: Binding<String>, error: String?, disabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(label, text: text)
                .disabled(disabled)
            if let error, isEditing {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func loadDraft() {
        switch appState.repositoryInspectorMode {
        case .create:
            draft = RepositoryFormDraft()
        case .view, .edit:
            if let repository {
                draft = RepositoryFormDraft(from: repository)
            }
        case .none:
            break
        }
    }

    private func save() {
        guard draft.isValid else { return }
        switch appState.repositoryInspectorMode {
        case .create:
            let repo = SkillRepository(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                gitURL: draft.gitURL.trimmingCharacters(in: .whitespacesAndNewlines),
                skillFolderName: draft.skillFolderName.trimmingCharacters(in: .whitespacesAndNewlines),
                slug: draft.slug.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: draft.notes
            )
            modelContext.insert(repo)
            try? modelContext.save()
            appState.selectedRepositoryID = repo.id
            appState.repositoryInspectorMode = .view
        case .edit:
            guard let repository else { return }
            repository.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            repository.gitURL = draft.gitURL.trimmingCharacters(in: .whitespacesAndNewlines)
            repository.skillFolderName = draft.skillFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
            repository.slug = draft.slug.trimmingCharacters(in: .whitespacesAndNewlines)
            repository.notes = draft.notes
            repository.touch()
            try? modelContext.save()
            appState.repositoryInspectorMode = .view
        default:
            break
        }
    }

    private func cancelEdit() {
        if appState.repositoryInspectorMode == .create {
            appState.repositoryInspectorMode = .none
            appState.selectedRepositoryID = nil
        } else {
            loadDraft()
            appState.repositoryInspectorMode = .view
        }
    }

    private func performDelete() {
        guard let repository else { return }
        modelContext.delete(repository)
        try? modelContext.save()
        appState.selectedRepositoryID = nil
        appState.repositoryInspectorMode = .none
    }
}
