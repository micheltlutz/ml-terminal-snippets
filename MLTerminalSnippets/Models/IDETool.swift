//
//  IDETool.swift
//  MLTerminalSnippets
//

import Foundation

enum IDETool: String, Codable, CaseIterable, Identifiable {
    case cursor
    case vscode
    case claudeCode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cursor: "Cursor"
        case .vscode: "VS Code"
        case .claudeCode: "Claude Code"
        }
    }

    var isAvailable: Bool {
        self == .cursor
    }

    var systemImage: String {
        switch self {
        case .cursor: "cursorarrow.rays"
        case .vscode: "chevron.left.forwardslash.chevron.right"
        case .claudeCode: "sparkles"
        }
    }
}
