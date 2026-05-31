//
//  ProjectTemplateBuilder.swift
//  MLTerminalSnippets
//

import Foundation

enum ProjectTemplateBuilder: Sendable {
    nonisolated static func readme(
        projectName: String,
        context: String,
        skills: [SkillScaffoldItem],
        swiftProjectKind: SwiftProjectKind,
        layout: IDEProjectLayout,
        installSkillsFailed: Bool
    ) -> String {
        var lines: [String] = [
            "# \(projectName)",
            "",
            "## Tipo de projeto",
            "",
            "- \(swiftProjectKind.displayName)",
            "- IDE: \(layout.ide.displayName)",
            "",
            "## Contexto",
            "",
            context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "_Adicione o contexto do projeto._"
                : context.trimmingCharacters(in: .whitespacesAndNewlines),
            "",
            "## Agent Skills",
            "",
            "| Skill | Repositório |",
            "|-------|-------------|",
        ]

        for skill in skills {
            lines.append("| \(skill.name) (`\(skill.slug)`) | [GitHub](\(skill.gitURL)) |")
        }

        lines += [
            "",
            "## Instalar skills (fallback)",
            "",
            "Se as pastas em `\(layout.skillsRelativePath)/` não estiverem presentes, execute:",
            "",
        ]

        for skill in skills {
            let url = skill.gitURL.lowercased()
            lines.append("```bash")
            lines.append("npx skills add \(url) --skill \(skill.skillFolderName)")
            lines.append("```")
            lines.append("")
        }

        if installSkillsFailed {
            lines += [
                "> **Nota:** A instalação automática via Git falhou parcialmente ou totalmente. Use os comandos acima.",
                "",
            ]
        }

        switch swiftProjectKind {
        case .macOSApp, .iOSApp:
            lines += [
                "## Próximo passo: Xcode",
                "",
                "Este repositório foi gerado **sem** `.xcodeproj`. Siga [docs/xcode-setup.md](docs/xcode-setup.md).",
                "",
            ]
        case .swiftPackage:
            lines += [
                "## Próximo passo: Swift Package",
                "",
                "```bash",
                "swift build",
                "swift test",
                "```",
                "",
                "Para abrir no Xcode: `open Package.swift`.",
                "",
            ]
        }

        lines += [
            "---",
            "",
            "_Projeto gerado com [MLTerminalSnippets](https://github.com/micheltlutz/MLTerminalSnippets)._",
        ]

        return lines.joined(separator: "\n")
    }

    nonisolated static func agentsMD(
        projectName: String,
        context: String,
        skills: [SkillScaffoldItem],
        swiftProjectKind: SwiftProjectKind,
        layout: IDEProjectLayout
    ) -> String {
        let stackBlock = stackSection(for: swiftProjectKind)

        var lines: [String] = [
            "# \(layout.agentsFileName) — \(projectName)",
            "",
            "## Stack",
            "",
            stackBlock,
            "",
            "## Contexto do projeto",
            "",
            context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "_Sem contexto adicional._"
                : context.trimmingCharacters(in: .whitespacesAndNewlines),
            "",
            "## Skills instalados (`\(layout.skillsRelativePath)/`)",
            "",
        ]

        for skill in skills {
            lines += [
                "### \(skill.name) (`\(skill.slug)`)",
                "",
                "- Repositório: \(skill.gitURL)",
                "- Pasta: `\(skill.skillFolderName)`",
                "- Use ao trabalhar em código relacionado a este skill.",
                "",
            ]
        }

        lines += [
            "## Convenções",
            "",
            "- Organize código por feature, não por tipo.",
            "- Prefira Swift Concurrency (`async`/`await`, `@MainActor`) em vez de callbacks.",
            "- Evite APIs SwiftUI depreciadas; siga as regras dos skills acima.",
            "- Só adicione dependências de terceiros após confirmar com o usuário.",
        ]

        if swiftProjectKind == .macOSApp || swiftProjectKind == .iOSApp {
            lines += [
                "",
                "## Xcode",
                "",
                "Consulte [docs/xcode-setup.md](docs/xcode-setup.md) para criar o `.xcodeproj` a partir deste esqueleto.",
            ]
        }

        if layout.ide == .cursor {
            lines += [
                "",
                "## Cursor",
                "",
                "- Regras do projeto: `.cursor/rules/swift-project.mdc`",
                "- Skills: `.cursor/skills/`",
            ]
        }

        return lines.joined(separator: "\n")
    }

    private nonisolated static func stackSection(for kind: SwiftProjectKind) -> String {
        switch kind {
        case .macOSApp:
            """
            - Swift 6.0+
            - SwiftUI (macOS 15+)
            - SwiftData (quando aplicável)
            - Esqueleto sem `.xcodeproj` — ver `docs/xcode-setup.md`
            """
        case .iOSApp:
            """
            - Swift 6.0+
            - SwiftUI (iOS 18+)
            - SwiftData (quando aplicável)
            - Esqueleto sem `.xcodeproj` — ver `docs/xcode-setup.md`
            """
        case .swiftPackage:
            """
            - Swift 6.0+ / Swift Package Manager
            - `swift build` / `swift test`
            """
        }
    }
}
