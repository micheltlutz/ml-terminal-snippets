//
//  AppSection.swift
//  MLTerminalSnippets
//

import Foundation

enum AppSection: String, CaseIterable, Identifiable {
    case home
    case repositories
    case projects
    case sshConnections
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Início"
        case .repositories: "Repositórios"
        case .projects: "Projetos"
        case .sshConnections: "Acessos SSH"
        case .settings: "Configurações"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .repositories: "books.vertical"
        case .projects: "folder.badge.plus"
        case .sshConnections: "terminal"
        case .settings: "gearshape"
        }
    }

    var sidebarGroup: SidebarGroup {
        switch self {
        case .home: .general
        case .repositories, .projects: .development
        case .sshConnections: .terminal
        case .settings: .app
        }
    }

    var isEnabled: Bool { true }
}

enum SidebarGroup: String, CaseIterable {
    case general
    case development
    case terminal
    case app

    var title: String {
        switch self {
        case .general: "Geral"
        case .development: "Desenvolvimento"
        case .terminal: "Terminal & Servidores"
        case .app: "App"
        }
    }

    var sections: [AppSection] {
        AppSection.allCases.filter { $0.sidebarGroup == self }
    }
}

enum FutureAppSection: String, Identifiable {
    case templates
    case skillCatalog
    case snippets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .templates: "Templates"
        case .skillCatalog: "Catálogo"
        case .snippets: "Snippets"
        }
    }

    var systemImage: String {
        switch self {
        case .templates: "doc.on.doc"
        case .skillCatalog: "globe"
        case .snippets: "terminal"
        }
    }
}
