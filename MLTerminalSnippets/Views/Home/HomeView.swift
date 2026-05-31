//
//  HomeView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Bindable var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var repositories: [SkillRepository]
    @Query private var projects: [SnippetProject]
    @Query private var sshConnections: [SSHConnection]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MLTerminalSnippets")
                        .font(.largeTitle.weight(.bold))
                    Text("Gerencie skills, projetos Cursor e acessos SSH com abertura direta no Terminal.")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    statCard(title: "Repositórios", value: "\(repositories.count)", icon: "books.vertical")
                    statCard(title: "Projetos", value: "\(projects.count)", icon: "folder")
                    statCard(title: "Acessos SSH", value: "\(sshConnections.count)", icon: "terminal")
                }

                Text("Ações rápidas")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                    actionCard(
                        title: "Novo acesso SSH",
                        subtitle: "Servidor, chave .pem ou comando customizado",
                        icon: "terminal",
                        action: { appState.startNewSSHConnection() }
                    )
                    actionCard(
                        title: "Novo projeto",
                        subtitle: "Wizard com skills e scaffold",
                        icon: "folder.badge.plus",
                        action: { appState.startNewProject() }
                    )
                    actionCard(
                        title: "Adicionar repositório",
                        subtitle: "Cadastre um repo Git de skill",
                        icon: "plus.rectangle.on.folder",
                        action: { appState.startNewRepository() }
                    )
                    actionCard(
                        title: "Repositórios incluídos",
                        subtitle: "\(SeedDataService.builtInRepositories.count) skills recomendados",
                        icon: "star.fill",
                        action: {
                            appState.navigateTo(.repositories)
                            SeedDataService.restoreBuiltInRepositories(context: modelContext)
                        }
                    )
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func actionCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }
}
