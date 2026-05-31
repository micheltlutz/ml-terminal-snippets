//
//  ScaffoldTemplateTests.swift
//  MLTerminalSnippetsTests
//

import Foundation
import Testing
@testable import MLTerminalSnippets

struct ScaffoldTemplateTests {
    @Test func gitignoreTemplatesLoad() throws {
        for kind in SwiftProjectKind.allCases {
            let content = try GitignoreTemplateLoader.content(for: kind)
            #expect(!content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        let spm = try GitignoreTemplateLoader.content(for: .swiftPackage)
        #expect(spm.contains(".build/"))
    }

    @Test func cursorLayoutPaths() {
        let layout = IDEProjectLayout.layout(for: .cursor)
        #expect(layout.skillsRelativePath == ".cursor/skills")
        #expect(layout.agentsFileName == "AGENTS.md")
        #expect(layout.rulesRelativePath == ".cursor/rules")
    }

    @Test func effectiveLayoutUsesCursorWhenIDEDisabled() {
        let layout = IDEProjectLayout.effectiveLayout(for: .vscode)
        #expect(layout.skillsRelativePath == ".cursor/skills")
    }

    @Test func fileTreePreviewMacOS() {
        let lines = ProjectScaffolder.fileTreePreview(
            projectName: "Demo",
            swiftProjectKind: .macOSApp,
            ideTool: .cursor,
            skills: []
        )
        #expect(lines.first?.contains("Demo/") == true)
        #expect(lines.contains { $0.contains("App/DemoApp.swift") })
        #expect(lines.contains { $0.contains("AGENTS.md") })
    }

    @Test func fileTreePreviewSPM() {
        let lines = ProjectScaffolder.fileTreePreview(
            projectName: "Lib",
            swiftProjectKind: .swiftPackage,
            ideTool: .cursor,
            skills: []
        )
        #expect(lines.contains { $0.contains("Package.swift") })
    }

    @Test func tokenReplacerSubstitutesProjectName() {
        let tokens = TemplateTokenReplacer.Tokens(projectName: "My App")
        let result = TemplateTokenReplacer.apply("struct {{PROJECT_NAME}} {}", tokens: tokens)
        #expect(result.contains("struct My App"))
        #expect(result.contains("com.example."))
    }

    @Test func skeletonBuilderWritesMacOSFiles() throws {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("mlts-test-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temp) }

        try SwiftProjectSkeletonBuilder.build(
            projectName: "TestApp",
            kind: .macOSApp,
            at: temp
        )

        let appFile = temp
            .appendingPathComponent("TestApp/App/TestAppApp.swift")
        #expect(FileManager.default.fileExists(atPath: appFile.path))
        let content = try String(contentsOf: appFile, encoding: .utf8)
        #expect(content.contains("struct TestAppApp"))
    }
}
