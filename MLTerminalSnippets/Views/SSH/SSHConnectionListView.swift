//
//  SSHConnectionListView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct SSHConnectionListView: View {
    @Bindable var appState: AppState
    @Query(sort: \SSHConnection.name) private var allConnections: [SSHConnection]
    @Environment(\.modelContext) private var modelContext

    @State private var showLaunchError = false

    private var filtered: [SSHConnection] {
        let q = appState.listSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return allConnections }
        return allConnections.filter {
            $0.name.lowercased().contains(q)
                || $0.host.lowercased().contains(q)
                || $0.username.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchField(text: $appState.listSearchText, placeholder: "Buscar acessos SSH")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            if filtered.isEmpty {
                EmptyStateView(
                    systemImage: "terminal",
                    title: allConnections.isEmpty ? "Nenhum acesso SSH" : "Sem resultados",
                    message: allConnections.isEmpty
                        ? "Cadastre servidores com usuário, chave .pem opcional ou comando personalizado."
                        : "Tente outro termo de busca.",
                    actionTitle: allConnections.isEmpty ? "Adicionar primeiro acesso" : nil,
                    action: allConnections.isEmpty ? { appState.startNewSSHConnection() } : nil
                )
            } else {
                List(selection: $appState.selectedSSHConnectionID) {
                    ForEach(filtered) { connection in
                        SSHConnectionRowView(connection: connection)
                            .tag(connection.id)
                            .contextMenu {
                                Button("Abrir no Terminal") {
                                    openTerminal(connection)
                                }
                                Button("Editar") {
                                    appState.selectedSSHConnectionID = connection.id
                                    appState.sshInspectorMode = .edit
                                }
                                Button("Duplicar") { duplicate(connection) }
                                Divider()
                                Button("Excluir", role: .destructive) {
                                    delete(connection)
                                }
                            }
                    }
                }
                .listStyle(.inset)
                .onChange(of: appState.selectedSSHConnectionID) { _, newID in
                    if newID != nil, appState.sshInspectorMode == .none {
                        appState.sshInspectorMode = .view
                    }
                }
            }
        }
        .navigationTitle("Acessos SSH")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.startNewSSHConnection()
                } label: {
                    Label("Novo", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .alert("Erro ao abrir Terminal", isPresented: $showLaunchError) {
            Button("OK") {}
        } message: {
            Text(appState.sshLaunchErrorMessage ?? "")
        }
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

    private func duplicate(_ connection: SSHConnection) {
        let copy = SSHConnection(
            name: connection.name + " (cópia)",
            host: connection.host,
            port: connection.port,
            username: connection.username,
            authMode: connection.authMode,
            privateKeyPathDisplay: connection.privateKeyPathDisplay,
            privateKeyBookmark: connection.privateKeyBookmark,
            customCommand: connection.customCommand,
            notes: connection.notes
        )
        modelContext.insert(copy)
        try? modelContext.save()
        appState.selectedSSHConnectionID = copy.id
        appState.sshInspectorMode = .edit
    }

    private func delete(_ connection: SSHConnection) {
        if appState.selectedSSHConnectionID == connection.id {
            appState.selectedSSHConnectionID = nil
            appState.sshInspectorMode = .none
        }
        modelContext.delete(connection)
        try? modelContext.save()
    }
}

struct SSHConnectionRowView: View {
    let connection: SSHConnection

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(connection.name.isEmpty ? "Sem nome" : connection.name)
                .font(.body.weight(.medium))
            Text("\(connection.username)@\(connection.host):\(connection.port)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if connection.authMode == .customCommand {
                Text("Comando personalizado")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if connection.resolvedPrivateKeyPath != nil {
                Text("Chave .pem")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
