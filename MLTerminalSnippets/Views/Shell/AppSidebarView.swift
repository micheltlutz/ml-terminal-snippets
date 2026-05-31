//
//  AppSidebarView.swift
//  MLTerminalSnippets
//

import SwiftUI

struct AppSidebarView: View {
    @Bindable var appState: AppState

    var body: some View {
        List(selection: $appState.activeSection) {
            ForEach(SidebarGroup.allCases, id: \.self) { group in
                Section(group.title) {
                    ForEach(group.sections) { section in
                        Label(section.title, systemImage: section.systemImage)
                            .tag(section)
                    }
                    if group == .terminal {
                        futureSidebarRow(
                            title: FutureAppSection.snippets.title,
                            systemImage: FutureAppSection.snippets.systemImage
                        )
                    }
                    if group == .development {
                        futureSidebarRow(
                            title: FutureAppSection.templates.title,
                            systemImage: FutureAppSection.templates.systemImage
                        )
                        futureSidebarRow(
                            title: FutureAppSection.skillCatalog.title,
                            systemImage: FutureAppSection.skillCatalog.systemImage
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        .safeAreaInset(edge: .bottom) {
            SyncStatusView(message: appState.syncStatusMessage, isError: appState.syncStatusIsError)
                .padding(12)
        }
    }

    private func futureSidebarRow(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(.secondary)
            .disabled(true)
            .help("Disponível em uma versão futura")
    }
}
