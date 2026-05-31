//
//  SSHConnectionInspectorView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SSHConnectionInspectorView: View {
    @Bindable var appState: AppState
    let connection: SSHConnection?
    @Environment(\.modelContext) private var modelContext

    @State private var draft = SSHConnectionFormDraft()
    @State private var showDeleteConfirm = false
    @State private var showLaunchError = false
    @State private var showPemPicker = false

    var body: some View {
        Group {
            switch appState.sshInspectorMode {
            case .none:
                EmptyStateView(
                    systemImage: "terminal",
                    title: "Selecione um acesso SSH",
                    message: "Escolha um item na lista ou cadastre um novo servidor.",
                    actionTitle: "Novo acesso SSH",
                    action: {
                        appState.sshInspectorMode = .create
                        draft = SSHConnectionFormDraft()
                    }
                )
            case .view, .edit, .create:
                formContent
            }
        }
        .navigationTitle(title)
        .toolbar { inspectorToolbar }
        .onAppear { loadDraft() }
        .onChange(of: appState.selectedSSHConnectionID) { _, _ in loadDraft() }
        .onChange(of: appState.sshInspectorMode) { _, _ in loadDraft() }
        .fileImporter(
            isPresented: $showPemPicker,
            allowedContentTypes: [.data, .item],
            allowsMultipleSelection: false
        ) { result in
            handlePemSelection(result)
        }
        .alert("Excluir acesso SSH?", isPresented: $showDeleteConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("Excluir", role: .destructive) { performDelete() }
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
        .alert("Erro ao abrir Terminal", isPresented: $showLaunchError) {
            Button("OK") {}
        } message: {
            Text(appState.sshLaunchErrorMessage ?? "")
        }
    }

    private var title: String {
        switch appState.sshInspectorMode {
        case .create: "Novo acesso SSH"
        case .edit: "Editar acesso SSH"
        case .view: connection?.name.isEmpty == false ? connection!.name : "Acesso SSH"
        case .none: ""
        }
    }

    private var isEditing: Bool {
        appState.sshInspectorMode == .edit || appState.sshInspectorMode == .create
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section("Servidor") {
                field("Nome", text: $draft.name, error: draft.nameError, disabled: !isEditing)
                field("Host", text: $draft.host, error: draft.hostError, disabled: !isEditing)
                    .help("Hostname ou endereço IP")
                portField
                field("Usuário", text: $draft.username, error: draft.usernameError, disabled: !isEditing)
            }

            Section("Autenticação") {
                if isEditing {
                    Picker("Modo", selection: $draft.authMode) {
                        ForEach(SSHAuthMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    LabeledContent("Modo", value: draft.authMode.displayName)
                }

                switch draft.authMode {
                case .standard:
                    standardAuthSection
                case .customCommand:
                    customCommandSection
                }
            }

            if isEditing || !draft.notes.isEmpty {
                Section("Notas") {
                    if isEditing {
                        TextEditor(text: $draft.notes)
                            .frame(minHeight: 60)
                    } else {
                        Text(draft.notes)
                    }
                }
            }

            if !isEditing, connection != nil {
                Section("Metadados") {
                    LabeledContent("Criado", value: connection!.createdAt.formatted())
                    LabeledContent("Atualizado", value: connection!.updatedAt.formatted())
                }
            }

            if draft.authMode == .standard, isEditing || connection != nil {
                iCloudPemNotice
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    @ViewBuilder
    private var standardAuthSection: some View {
        if isEditing {
            LabeledContent("Chave .pem") {
                HStack {
                    Text(draft.privateKeyPathDisplay.isEmpty ? "Nenhuma" : draft.privateKeyPathDisplay)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .font(.caption.monospaced())
                    Button("Escolher…") { showPemPicker = true }
                    if !draft.privateKeyPathDisplay.isEmpty {
                        Button("Remover", role: .destructive) {
                            draft.privateKeyPathDisplay = ""
                            draft.privateKeyBookmark = nil
                        }
                    }
                }
            }
            .help("Opcional. SSH usa -i quando uma chave é selecionada.")
            Text("A chave deve ter permissão 400 (chmod 400 caminho.pem).")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if !draft.privateKeyPathDisplay.isEmpty {
            LabeledContent("Chave .pem") {
                Text(draft.privateKeyPathDisplay)
                    .font(.caption.monospaced())
            }
        }

        Section("Comando gerado") {
            Text(draft.commandPreview)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var customCommandSection: some View {
        if isEditing {
            templateButtons
            VStack(alignment: .leading, spacing: 4) {
                Text("Comando")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $draft.customCommand)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
                if let error = draft.customCommandError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        } else {
            Text(draft.customCommand)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var templateButtons: some View {
        HStack {
            Button("SSH padrão") { applyTemplate(.standardSSH) }
            Button("ssh-copy-id") { applyTemplate(.sshCopyId) }
            Button("Adicionar usuário") { applyTemplate(.addUserExample) }
        }
        .buttonStyle(.link)
    }

    @ViewBuilder
    private var iCloudPemNotice: some View {
        Section {
            Text("O caminho da chave .pem sincroniza via iCloud, mas o bookmark do arquivo pode precisar ser reescolhido em outro Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var portField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Porta")
                Spacer()
                TextField("22", value: $draft.port, format: .number)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
                    .disabled(!isEditing)
            }
            if let error = draft.portError, isEditing {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ToolbarContentBuilder
    private var inspectorToolbar: some ToolbarContent {
        if let connection, !isEditing {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    openTerminal(connection)
                } label: {
                    Label("Abrir no Terminal", systemImage: "terminal")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .help("Abrir no Terminal (⌘↩)")
            }
            ToolbarItem(placement: .automatic) {
                Button("Editar") { appState.sshInspectorMode = .edit }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Excluir", systemImage: "trash")
                }
            }
        }
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
        }
    }

    @ViewBuilder
    private func field(
        _ label: String,
        text: Binding<String>,
        error: String?,
        disabled: Bool
    ) -> some View {
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
        switch appState.sshInspectorMode {
        case .create:
            draft = SSHConnectionFormDraft()
        case .view, .edit:
            if let connection {
                draft = SSHConnectionFormDraft(from: connection)
            }
        case .none:
            break
        }
    }

    private func handlePemSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() }
            }
            draft.privateKeyPathDisplay = url.path
            draft.privateKeyBookmark = try? BookmarkStore.makeBookmark(for: url)
        case .failure:
            break
        }
    }

    private func applyTemplate(_ template: SSHCommandBuilder.CommandTemplate) {
        draft.authMode = .customCommand
        draft.customCommand = template.text(
            host: draft.host,
            port: draft.port,
            username: draft.username,
            privateKeyPath: draft.resolvedPrivateKeyPath
        )
    }

    private func save() {
        guard draft.isValid else { return }
        switch appState.sshInspectorMode {
        case .create:
            let conn = SSHConnection(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                host: draft.host.trimmingCharacters(in: .whitespacesAndNewlines),
                port: draft.port,
                username: draft.username.trimmingCharacters(in: .whitespacesAndNewlines),
                authMode: draft.authMode,
                privateKeyPathDisplay: draft.privateKeyPathDisplay,
                privateKeyBookmark: draft.privateKeyBookmark,
                customCommand: draft.customCommand,
                notes: draft.notes
            )
            modelContext.insert(conn)
            try? modelContext.save()
            appState.selectedSSHConnectionID = conn.id
            appState.sshInspectorMode = .view
        case .edit:
            guard let connection else { return }
            connection.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            connection.host = draft.host.trimmingCharacters(in: .whitespacesAndNewlines)
            connection.port = draft.port
            connection.username = draft.username.trimmingCharacters(in: .whitespacesAndNewlines)
            connection.authMode = draft.authMode
            connection.privateKeyPathDisplay = draft.privateKeyPathDisplay
            connection.privateKeyBookmark = draft.privateKeyBookmark
            connection.customCommand = draft.customCommand
            connection.notes = draft.notes
            connection.touch()
            try? modelContext.save()
            appState.sshInspectorMode = .view
        default:
            break
        }
        loadDraft()
    }

    private func cancelEdit() {
        if appState.sshInspectorMode == .create {
            appState.sshInspectorMode = .none
            appState.selectedSSHConnectionID = nil
        } else {
            loadDraft()
            appState.sshInspectorMode = .view
        }
    }

    private func performDelete() {
        guard let connection else { return }
        modelContext.delete(connection)
        try? modelContext.save()
        appState.selectedSSHConnectionID = nil
        appState.sshInspectorMode = .none
    }

    private func openTerminal(_ connection: SSHConnection) {
        do {
            let command = try SSHCommandBuilder.build(from: connection)
            try TerminalLauncher.open(command: command)
        } catch {
            appState.sshLaunchErrorMessage = error.localizedDescription
            showLaunchError = true
        }
    }
}
