//
//  SwiftProjectSkeletonBuilder.swift
//  MLTerminalSnippets
//

import Foundation

enum SwiftProjectSkeletonBuilderError: LocalizedError, Sendable {
    case templateNotFound(String)
    case writeFailed(String)

    nonisolated var errorDescription: String? {
        switch self {
        case .templateNotFound(let path): return "Template não encontrado: \(path)"
        case .writeFailed(let msg): return msg
        }
    }
}

enum SwiftProjectSkeletonBuilder: Sendable {
    private nonisolated static let swiftTemplatesSubdir = "Templates/Swift"

    /// Nomes únicos no bundle (Xcode achata `Resources/` — sem colisão macOS/iOS).
    private enum AppTemplate: String, Sendable {
        case appEntry
        case contentView
        case xcodeSetup

        nonisolated func resourceName(for kind: SwiftProjectKind) -> String {
            let prefix = kind.swiftTemplateFolder
            switch self {
            case .appEntry: return "\(prefix)-App.swift"
            case .contentView: return "\(prefix)-ContentView.swift"
            case .xcodeSetup: return "\(prefix)-xcode-setup"
            }
        }

        nonisolated var fileExtension: String {
            switch self {
            case .appEntry, .contentView: return "tpl"
            case .xcodeSetup: return "md"
            }
        }
    }

    private enum SPMTemplate: String, Sendable {
        case package = "spm-Package.swift"
        case main = "spm-Main.swift"
        case tests = "spm-Tests.swift"

        nonisolated var fileExtension: String { "tpl" }
    }

    nonisolated static func build(
        projectName: String,
        kind: SwiftProjectKind,
        at projectRoot: URL
    ) throws {
        let tokens = TemplateTokenReplacer.Tokens(projectName: projectName)

        switch kind {
        case .macOSApp, .iOSApp:
            try buildAppSkeleton(projectName: projectName, kind: kind, projectRoot: projectRoot, tokens: tokens)
        case .swiftPackage:
            try buildSPMSkeleton(projectName: projectName, projectRoot: projectRoot, tokens: tokens)
        }
    }

    private nonisolated static func buildAppSkeleton(
        projectName: String,
        kind: SwiftProjectKind,
        projectRoot: URL,
        tokens: TemplateTokenReplacer.Tokens
    ) throws {
        let moduleRoot = projectRoot.appendingPathComponent(projectName, isDirectory: true)
        let folders = [
            moduleRoot.appendingPathComponent("App", isDirectory: true),
            moduleRoot.appendingPathComponent("Models", isDirectory: true),
            moduleRoot.appendingPathComponent("Views", isDirectory: true),
            moduleRoot.appendingPathComponent("Services", isDirectory: true),
            projectRoot.appendingPathComponent("\(projectName)Tests", isDirectory: true),
            projectRoot.appendingPathComponent("docs", isDirectory: true),
        ]
        for folder in folders {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        let folder = kind.swiftTemplateFolder
        try writeAppTemplate(.appEntry, kind: kind, swiftFolder: folder,
                             to: moduleRoot.appendingPathComponent("App/\(projectName)App.swift"), tokens: tokens)
        try writeAppTemplate(.contentView, kind: kind, swiftFolder: folder,
                             to: moduleRoot.appendingPathComponent("Views/ContentView.swift"), tokens: tokens)
        try writeAppTemplate(.xcodeSetup, kind: kind, swiftFolder: folder,
                             to: projectRoot.appendingPathComponent("docs/xcode-setup.md"), tokens: tokens)
    }

    private nonisolated static func buildSPMSkeleton(
        projectName: String,
        projectRoot: URL,
        tokens: TemplateTokenReplacer.Tokens
    ) throws {
        let sourceDir = projectRoot
            .appendingPathComponent("Sources/\(projectName)", isDirectory: true)
        let testDir = projectRoot
            .appendingPathComponent("Tests/\(projectName)Tests", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        try writeSPMTemplate(.package, to: projectRoot.appendingPathComponent("Package.swift"), tokens: tokens)
        try writeSPMTemplate(.main, to: sourceDir.appendingPathComponent("\(projectName).swift"), tokens: tokens)
        try writeSPMTemplate(.tests, to: testDir.appendingPathComponent("\(projectName)Tests.swift"), tokens: tokens)
    }

    private nonisolated static func writeAppTemplate(
        _ template: AppTemplate,
        kind: SwiftProjectKind,
        swiftFolder: String,
        to destination: URL,
        tokens: TemplateTokenReplacer.Tokens
    ) throws {
        try writeTemplate(
            bundleName: template.resourceName(for: kind),
            extension: template.fileExtension,
            swiftFolder: swiftFolder,
            to: destination,
            tokens: tokens
        )
    }

    private nonisolated static func writeSPMTemplate(
        _ template: SPMTemplate,
        to destination: URL,
        tokens: TemplateTokenReplacer.Tokens
    ) throws {
        try writeTemplate(
            bundleName: template.rawValue,
            extension: template.fileExtension,
            swiftFolder: "spm",
            to: destination,
            tokens: tokens
        )
    }

    private nonisolated static func writeTemplate(
        bundleName: String,
        extension ext: String,
        swiftFolder: String,
        to destination: URL,
        tokens: TemplateTokenReplacer.Tokens
    ) throws {
        let subdirectory = "\(swiftTemplatesSubdir)/\(swiftFolder)"
        guard let url = TemplateBundle.url(resource: bundleName, extension: ext, subdirectory: subdirectory) else {
            throw SwiftProjectSkeletonBuilderError.templateNotFound("\(subdirectory)/\(bundleName).\(ext)")
        }
        let raw = try String(contentsOf: url, encoding: .utf8)
        let content = TemplateTokenReplacer.apply(raw, tokens: tokens)
        let parent = destination.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        do {
            try content.write(to: destination, atomically: true, encoding: .utf8)
        } catch {
            throw SwiftProjectSkeletonBuilderError.writeFailed(
                "Não foi possível escrever \(destination.lastPathComponent): \(error.localizedDescription)"
            )
        }
    }
}
