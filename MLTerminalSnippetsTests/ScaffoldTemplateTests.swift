//
//  ScaffoldTemplateTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

@MainActor
struct ScaffoldTemplateTests {
    @Test(.tags(.scaffold, .templates))
    func gitignoreTemplatesLoadForAllKinds() throws {
        for kind in SwiftProjectKind.allCases {
            let content = try GitignoreTemplateLoader.content(for: kind)
            #expect(
                content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
                "Gitignore vazio para \(kind.rawValue)"
            )
        }
    }

    @Test(.tags(.scaffold, .templates), arguments: [
        SwiftProjectKind.macOSApp,
        SwiftProjectKind.iOSApp,
        SwiftProjectKind.swiftPackage,
    ])
    func gitignoreTemplateNameMatchesKind(kind: SwiftProjectKind) {
        switch kind {
        case .macOSApp:
            #expect(kind.gitignoreTemplateName == "swift-macos-xcode")
        case .iOSApp:
            #expect(kind.gitignoreTemplateName == "swift-ios-xcode")
        case .swiftPackage:
            #expect(kind.gitignoreTemplateName == "swift-spm")
        }
    }

    @Test(.tags(.scaffold))
    func spmGitignoreContainsBuildDirectory() throws {
        let spm = try GitignoreTemplateLoader.content(for: .swiftPackage)
        #expect(spm.contains(".build/"))
    }

    @Test(.tags(.scaffold))
    func cursorLayoutPaths() {
        let layout = IDEProjectLayout.layout(for: .cursor)
        #expect(layout.skillsRelativePath == ".cursor/skills")
        #expect(layout.agentsFileName == "AGENTS.md")
        #expect(layout.rulesRelativePath == ".cursor/rules")
        #expect(layout.cursorIgnoreFileName == ".cursorignore")
    }

    @Test(.tags(.scaffold))
    func effectiveLayoutUsesCursorWhenIDEDisabled() {
        let layout = IDEProjectLayout.effectiveLayout(for: .vscode)
        #expect(layout.skillsRelativePath == ".cursor/skills")
    }

    @Test(.tags(.scaffold))
    func fileTreePreviewMacOSIncludesDocsNotSwiftStubs() {
        let lines = ProjectScaffolder.fileTreePreview(
            projectName: "Demo",
            swiftProjectKind: .macOSApp,
            ideTool: .cursor,
            skills: []
        )
        #expect(lines.first?.contains("Demo/") == true)
        #expect(lines.contains { $0.contains("docs/xcode-setup.md") })
        #expect(lines.contains { $0.contains("App/DemoApp.swift") } == false)
        #expect(lines.contains { $0.contains("AGENTS.md") })
    }

    @Test(.tags(.scaffold))
    func fileTreePreviewSPMExcludesGeneratedPackageSwift() {
        let lines = ProjectScaffolder.fileTreePreview(
            projectName: "Lib",
            swiftProjectKind: .swiftPackage,
            ideTool: .cursor,
            skills: []
        )
        #expect(lines.contains { $0.contains("Package.swift") } == false)
        #expect(lines.contains { $0.contains("AGENTS.md") })
    }

    @Test(.tags(.templates))
    func tokenReplacerSubstitutesProjectNameAndBundleID() {
        let tokens = TemplateTokenReplacer.Tokens(projectName: "My App")
        let result = TemplateTokenReplacer.apply("struct {{PROJECT_NAME}} id={{BUNDLE_ID}}", tokens: tokens)
        #expect(result.contains("struct My App"))
        #expect(result.contains("com.example.my-app"))
    }

    @Test(.tags(.templates))
    func tokenReplacerSubstitutesSkillSlugs() {
        let tokens = TemplateTokenReplacer.Tokens(projectName: "App", skillSlugs: ["swiftui-pro"])
        let result = TemplateTokenReplacer.apply("Skills:\n{{SKILL_SLUGS}}", tokens: tokens)
        #expect(result.contains("swiftui-pro"))
        #expect(result.contains(".cursor/skills/swiftui-pro/SKILL.md"))
    }

    @Test(.tags(.scaffold, .templates))
    func docsTemplateLoaderWritesXcodeSetupForApps() throws {
        let temp = try TempDirectory(prefix: "docs-template")
        try ProjectDocsTemplateLoader.writeXcodeSetupIfNeeded(
            projectName: "TestApp",
            kind: .macOSApp,
            at: temp.url
        )

        let setupFile = temp.url.appendingPathComponent("docs/xcode-setup.md")
        #expect(FileManager.default.fileExists(atPath: setupFile.path))
        let content = try String(contentsOf: setupFile, encoding: .utf8)
        #expect(content.contains("TestApp"))
    }

    @Test(.tags(.scaffold, .templates))
    func docsTemplateLoaderSkipsSPM() throws {
        let temp = try TempDirectory(prefix: "docs-spm-skip")
        try ProjectDocsTemplateLoader.writeXcodeSetupIfNeeded(
            projectName: "Pkg",
            kind: .swiftPackage,
            at: temp.url
        )
        let setupFile = temp.url.appendingPathComponent("docs/xcode-setup.md")
        #expect(FileManager.default.fileExists(atPath: setupFile.path) == false)
    }
}
