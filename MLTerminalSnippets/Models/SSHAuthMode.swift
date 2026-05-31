//
//  SSHAuthMode.swift
//  MLTerminalSnippets
//

import Foundation

enum SSHAuthMode: String, Codable, CaseIterable, Identifiable {
    case standard
    case customCommand

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: "SSH padrão"
        case .customCommand: "Comando personalizado"
        }
    }
}
