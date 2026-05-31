//
//  ProjectCreationFlowView.swift
//  MLTerminalSnippets
//

import AppKit
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ProjectCreationFlowView: View {
    @Bindable var appState: AppState
    @Query(sort: \SkillRepository.name) private var repositories: [SkillRepository]
    @Environment(\.modelContext) private var modelContext

    @State private var skillFilter: SkillFilter = .all
    @State private var showFolderPicker = false
    @State private var showErrorAlert = false

    enum SkillFilter: String, CaseIterable {
        case all = "Todos"
        case builtIn = "Built-in"
        case custom = "Custom"
    }

    private var filteredSkills: [SkillRepository] {
        switch skillFilter {
        case .all: repositories
        case .builtIn: repositories.filter(\.isBuiltIn)
        case .custom: repositories.filter { !$0.isBuiltIn }
        }
    }

    private var selectedSkills: [SkillRepository] {
        repositories.filter { appState.projectDraft.selectedSkillIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if appState.isGeneratingProject {
                generatingOverlay
            } else if case .success(let path) = appState.projectDetailMode {
                successView(path: path)
            } else {
                wizardContent
            }
        }
        .navigationTitle("Novo Projeto")
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                _ = url.startAccessingSecurityScopedResource()
                appState.projectDraft.parentDirectoryURL = url
                appState.projectDraft.parentDirectoryDisplay = url.path
            case .failure(let error):
                appState.lastErrorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
        .alert("Erro", isPresented: $showErrorAlert) {
            Button("OK") {}
            if appState.lastErrorLog != nil {
                Button("Copiar log") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.lastErrorLog ?? "", forType: .string)
                }
            }
        } message: {
            Text(appState.lastErrorMessage ?? "Erro desconhecido")
        }
    }

    @ViewBuilder
    private var wizardContent: some View {
        VStack(spacing: 16) {
            StepIndicator(
                currentStep: appState.projectDraft.currentStep,
                stepCount: ProjectCreationDraft.stepCount,
                stepTitle: ProjectWizardValidator.stepTitle
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)

            ScrollView {
                stepContent
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                if appState.projectDraft.currentStep > 0 {
                    Button("Voltar") { appState.projectDraft.currentStep -= 1 }
                }
                Spacer()
                if appState.projectDraft.currentStep < ProjectCreationDraft.stepCount - 1 {
                    Button("Continuar") { appState.projectDraft.currentStep += 1 }
                        .buttonStyle(.borderedProminent)
                        .disabled(!ProjectWizardValidator.canAdvance(step: appState.projectDraft.currentStep, draft: appState.projectDraft))
                } else {
                    Button("Gerar projeto") {
                        Task { await generateProject() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!ProjectWizardValidator.canAdvance(step: appState.projectDraft.currentStep, draft: appState.projectDraft))
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch appState.projectDraft.currentStep {
        case 0: identityStep
        case 1: contextStep
        case 2: skillsStep
        case 3: destinationStep
        case 4: reviewStep
        default: EmptyView()
        }
    }

    private var identityStep: some View {
        Form {
            TextField("Nome do projeto", text: $appState.projectDraft.name)
            Picker("IDE", selection: $appState.projectDraft.ideTool) {
                Text("Cursor").tag(IDETool.cursor)
            }
            LabeledContent("VS Code") { Text("Em breve").foregroundStyle(.secondary) }
            LabeledContent("Claude Code") { Text("Em breve").foregroundStyle(.secondary) }
        }
        .formStyle(.grouped)
    }

    private var contextStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Descreva o contexto do projeto (Markdown)")
                .font(.headline)
            TextEditor(text: $appState.projectDraft.contextMarkdown)
                .font(.body)
                .frame(minHeight: 200)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            Text("\(appState.projectDraft.contextMarkdown.count) caracteres")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var skillsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Filtro", selection: $skillFilter) {
                    ForEach(SkillFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                Button("Selecionar recomendados") {
                    let builtIn = repositories.filter(\.isBuiltIn)
                    appState.projectDraft.selectedSkillIDs = Set(builtIn.map(\.id))
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 10)], spacing: 10) {
                ForEach(filteredSkills) { repo in
                    SkillChip(
                        repository: repo,
                        isSelected: appState.projectDraft.selectedSkillIDs.contains(repo.id)
                    ) {
                        if appState.projectDraft.selectedSkillIDs.contains(repo.id) {
                            appState.projectDraft.selectedSkillIDs.remove(repo.id)
                        } else {
                            appState.projectDraft.selectedSkillIDs.insert(repo.id)
                        }
                    }
                }
            }
        }
    }

    private var destinationStep: some View {
        Form {
            LabeledContent("Pasta pai") {
                HStack {
                    Text(appState.projectDraft.parentDirectoryDisplay.isEmpty ? "Não selecionada" : appState.projectDraft.parentDirectoryDisplay)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Escolher…") { showFolderPicker = true }
                }
            }
            if let parent = appState.projectDraft.parentDirectoryURL, !appState.projectDraft.name.isEmpty {
                LabeledContent("Destino final") {
                    Text(parent.appendingPathComponent(appState.projectDraft.name).path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Toggle("Inicializar Git", isOn: $appState.projectDraft.gitInit)
            Toggle("Instalar skills via Git", isOn: $appState.projectDraft.installSkills)
        }
        .formStyle(.grouped)
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pré-visualização")
                .font(.headline)
            FileTreePreview(
                lines: ProjectScaffolder.fileTreePreview(
                    projectName: appState.projectDraft.name,
                    skills: selectedSkills
                )
            )
            .frame(height: 180)

            Text("AGENTS.md (trecho)")
                .font(.headline)
            Text(String(ProjectTemplateBuilder.agentsMD(
                projectName: appState.projectDraft.name,
                context: appState.projectDraft.contextMarkdown,
                skills: selectedSkills
            ).prefix(600)))
            .font(.caption.monospaced())
            .textSelection(.enabled)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var generatingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .controlSize(.large)
            Text(appState.generationProgress)
                .font(.headline)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(appState.generationLog, id: \.self) { line in
                        Text(line)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func successView(path: String) -> some View {
        let url = URL(fileURLWithPath: path)
        return VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Projeto criado com sucesso")
                .font(.title2.weight(.semibold))
            Text(path)
                .font(.caption.monospaced())
                .textSelection(.enabled)
            HStack(spacing: 16) {
                Button("Abrir no Finder") { WorkspaceOpener.openInFinder(url) }
                    .keyboardShortcut("O", modifiers: [.command, .shift])
                Button("Abrir no Cursor") { WorkspaceOpener.openInCursor(url) }
                    .buttonStyle(.borderedProminent)
            }
            Button("Criar outro projeto") {
                appState.resetProjectDraft()
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @MainActor
    private func generateProject() async {
        guard let parent = appState.projectDraft.parentDirectoryURL else { return }
        let skills = selectedSkills
        let draft = appState.projectDraft

        appState.isGeneratingProject = true
        appState.generationLog = []
        appState.generationProgress = "Preparando…"

        let request = ProjectScaffoldRequest(
            name: draft.name,
            contextMarkdown: draft.contextMarkdown,
            skills: skills,
            parentDirectory: parent,
            ideTool: draft.ideTool,
            gitInit: draft.gitInit,
            installSkills: draft.installSkills
        )

        do {
            let result = try await ProjectScaffolder.scaffold(request) { progress in
                Task { @MainActor in
                    appState.generationProgress = progress.message
                }
            }
            appState.generationLog = result.logLines

            let bookmark = try BookmarkStore.makeBookmark(for: result.projectURL)
            let project = SnippetProject(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                contextMarkdown: draft.contextMarkdown,
                outputPathBookmark: bookmark,
                outputPathDisplay: result.projectURL.path,
                ideTool: draft.ideTool,
                gitInitOnGenerate: draft.gitInit,
                installSkillsOnGenerate: draft.installSkills,
                selectedSkills: skills
            )
            modelContext.insert(project)
            try? modelContext.save()

            appState.selectedProjectID = project.id
            appState.projectDetailMode = .success(path: result.projectURL.path)
            appState.isGeneratingProject = false
        } catch {
            appState.isGeneratingProject = false
            appState.lastErrorMessage = error.localizedDescription
            appState.lastErrorLog = (error as NSError).localizedDescription + "\n" + appState.generationLog.joined(separator: "\n")
            showErrorAlert = true
        }
    }
}
