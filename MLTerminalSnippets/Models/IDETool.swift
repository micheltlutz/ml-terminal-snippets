//
//  IDETool.swift
//  MLTerminalSnippets
//

import Foundation

enum IDETool: String, Codable, CaseIterable, Identifiable, Sendable {
    case cursor
    case vscode
    case claudeCode

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .cursor: return "Cursor"
        case .vscode: return "VS Code"
        case .claudeCode: return "Claude Code"
        }
    }

    nonisolated var isAvailable: Bool {
        self == .cursor
    }

    nonisolated var systemImage: String {
        switch self {
        case .cursor: return "cursorarrow.rays"
        case .vscode: return "chevron.left.forwardslash.chevron.right"
        case .claudeCode: return "sparkles"
        }
    }
}
