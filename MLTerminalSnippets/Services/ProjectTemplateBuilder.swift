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
            "| Skill | Quando usar | Repositório |",
            "|-------|-------------|-------------|",
        ]

        for skill in skills {
            lines.append(
                "| \(skill.name) (`\(skill.slug)`) | \(skill.whenToUseDisplay) | [GitHub](\(skill.gitURL)) |"
            )
        }

        lines += [
            "",
            "Skills copiados de `\(layout.skillsRelativePath)/{slug}/` (cada pasta deve conter `SKILL.md`).",
            "",
            "## Instalar skills (fallback)",
            "",
            "Se as pastas em `\(layout.skillsRelativePath)/` não estiverem presentes, importe no app (Repositórios → Cache local) ou execute:",
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
                "> **Nota:** A cópia automática do cache local falhou parcialmente ou totalmente. Importe as pastas em Repositórios ou use os comandos acima.",
                "",
            ]
        }

        switch swiftProjectKind {
        case .macOSApp, .iOSApp:
            lines += [
                "## Próximo passo: Xcode",
                "",
                "Este repositório contém contexto, skills e documentação para agentes — **sem** `.xcodeproj` gerado.",
                "Siga [docs/xcode-setup.md](docs/xcode-setup.md) para criar o projeto Xcode manualmente.",
                "",
            ]
        case .swiftPackage:
            lines += [
                "## Próximo passo: Swift Package",
                "",
                "Inicialize o pacote na pasta deste projeto, se ainda não existir:",
                "",
                "```bash",
                "swift package init --name \(projectName)",
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
            "Leia o `SKILL.md` de cada skill antes de implementar ou revisar código relacionado.",
            "",
            "| Skill | Quando usar | Caminho |",
            "|-------|-------------|---------|",
        ]

        for skill in skills {
            lines.append(
                "| `\(skill.slug)` | \(skill.whenToUseDisplay) | `\(layout.skillsRelativePath)/\(skill.slug)/SKILL.md` |"
            )
        }

        lines += [
            "",
            "## Instalar skills localmente",
            "",
        ]

        for skill in skills {
            let url = skill.gitURL.lowercased()
            lines.append("```bash")
            lines.append("npx skills add \(url) --skill \(skill.skillFolderName)")
            lines.append("```")
            lines.append("")
        }

        lines += [
            "## Convenções",
            "",
            "- Organize código por feature, alinhado ao contexto acima.",
            "- Prefira Swift Concurrency (`async`/`await`, `@MainActor`) em vez de callbacks.",
            "- Evite APIs SwiftUI depreciadas; siga as regras dos skills acima.",
            "- Só adicione dependências de terceiros após confirmar com o usuário.",
        ]

        if swiftProjectKind == .macOSApp || swiftProjectKind == .iOSApp {
            lines += [
                "",
                "## Xcode",
                "",
                "Consulte [docs/xcode-setup.md](docs/xcode-setup.md) para criar o `.xcodeproj` manualmente.",
            ]
        } else if swiftProjectKind == .swiftPackage {
            lines += [
                "",
                "## Swift Package",
                "",
                "Use `swift package init` nesta pasta se ainda não houver `Package.swift`.",
            ]
        }

        if layout.ide == .cursor {
            lines += [
                "",
                "## Cursor",
                "",
                "- Regras do projeto: `.cursor/rules/swift-project.mdc`",
                "- Skills: `.cursor/skills/{slug}/SKILL.md`",
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
            - Sem `.xcodeproj` gerado — ver `docs/xcode-setup.md`
            """
        case .iOSApp:
            """
            - Swift 6.0+
            - SwiftUI (iOS 18+)
            - SwiftData (quando aplicável)
            - Sem `.xcodeproj` gerado — ver `docs/xcode-setup.md`
            """
        case .swiftPackage:
            """
            - Swift 6.0+ / Swift Package Manager
            - Inicialize com `swift package init` se necessário
            - `swift build` / `swift test`
            """
        }
    }
}
