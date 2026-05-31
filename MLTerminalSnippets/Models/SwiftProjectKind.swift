//
//  SwiftProjectKind.swift
//  MLTerminalSnippets
//

import Foundation

/// Domínio puro — `nonisolated` para uso em serviços e `LocalizedError` fora do MainActor.
enum SwiftProjectKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case macOSApp
    case iOSApp
    case swiftPackage

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .macOSApp: return "macOS (SwiftUI)"
        case .iOSApp: return "iOS (SwiftUI)"
        case .swiftPackage: return "Swift Package"
        }
    }

    nonisolated var gitignoreTemplateName: String {
        switch self {
        case .macOSApp: return "swift-macos-xcode"
        case .iOSApp: return "swift-ios-xcode"
        case .swiftPackage: return "swift-spm"
        }
    }

    nonisolated var swiftTemplateFolder: String {
        switch self {
        case .macOSApp: return "macOS"
        case .iOSApp: return "iOS"
        case .swiftPackage: return "spm"
        }
    }
}
