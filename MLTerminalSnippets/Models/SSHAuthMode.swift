//
//  SSHAuthMode.swift
//  MLTerminalSnippets
//

import Foundation

enum SSHAuthMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard
    case customCommand

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .standard: return "SSH padrão"
        case .customCommand: return "Comando personalizado"
        }
    }
}
