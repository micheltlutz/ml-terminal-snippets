//
//  MLTerminalSnippetsApp.swift
//  MLTerminalSnippets
//

import SwiftUI
import SwiftData

@main
struct MLTerminalSnippetsApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SkillRepository.self,
            SnippetProject.self,
            SSHConnection.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Schema incompatível após alteração do modelo (ex.: migração CloudKit).
            // Apaga o store local e tenta uma vez — dados locais não sincronizados serão perdidos.
            let storeURL = configuration.url
            let related = [
                storeURL,
                URL(fileURLWithPath: storeURL.path + "-wal"),
                URL(fileURLWithPath: storeURL.path + "-shm"),
            ]
            for url in related where FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppShellView(appState: appState)
        }
        .modelContainer(sharedModelContainer)
        .commands {
            AppCommands()
        }
        .defaultSize(width: 1200, height: 800)
    }
}
