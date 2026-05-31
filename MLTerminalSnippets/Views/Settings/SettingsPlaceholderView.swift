//
//  SettingsPlaceholderView.swift
//  MLTerminalSnippets
//

import SwiftUI

struct SettingsPlaceholderView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section("iCloud") {
                SyncStatusView(message: appState.syncStatusMessage, isError: appState.syncStatusIsError)
                Text("Os repositórios e projetos sincronizam via SwiftData + CloudKit quando você está logado com a mesma Apple ID.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Projeto padrão") {
                LabeledContent("Pasta padrão") {
                    Text("Em breve")
                        .foregroundStyle(.secondary)
                }
                .help("Definir pasta padrão para novos projetos — Fase 4")
            }

            Section("Skills") {
                LabeledContent("Atualizações automáticas") {
                    Text("Em breve")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sobre") {
                LabeledContent("Versão", value: "1.0")
                LabeledContent("Bundle", value: "me.micheltlutz.MLTerminalSnippets")
            }
        }
        .formStyle(.grouped)
        .padding()
        .navigationTitle("Configurações")
    }
}
