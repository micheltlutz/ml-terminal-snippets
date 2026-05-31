//
//  ProjectTemplateBuilder.swift
//  MLTerminalSnippets
//

import Foundation

enum ProjectTemplateBuilder {
    static func readme(
        projectName: String,
        context: String,
        skills: [SkillRepository],
        installSkillsFailed: Bool
    ) -> String {
        var lines: [String] = [
            "# \(projectName)",
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
            "Se as pastas em `.cursor/skills/` não estiverem presentes, execute:",
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

        lines += [
            "---",
            "",
            "_Projeto gerado com [MLTerminalSnippets](https://github.com/micheltlutz/MLTerminalSnippets)._",
        ]

        return lines.joined(separator: "\n")
    }

    static func agentsMD(
        projectName: String,
        context: String,
        skills: [SkillRepository]
    ) -> String {
        var lines: [String] = [
            "# AGENTS.md — \(projectName)",
            "",
            "## Stack",
            "",
            "- Swift 6.2+",
            "- SwiftUI",
            "- SwiftData (quando aplicável)",
            "- macOS 15.7+ / iOS 26+ conforme o alvo do projeto",
            "",
            "## Contexto do projeto",
            "",
            context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "_Sem contexto adicional._"
                : context.trimmingCharacters(in: .whitespacesAndNewlines),
            "",
            "## Skills instalados (`.cursor/skills/`)",
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
            "- Evite APIs SwiftUI depreciadas; siga as regras dos skills Pro acima.",
            "- Só adicione dependências de terceiros após confirmar com o usuário.",
        ]

        return lines.joined(separator: "\n")
    }

    static let gitignore = """
        # Xcode
        DerivedData/
        *.xcuserstate
        *.xcscmblueprint
        xcuserdata/

        # SwiftPM
        .build/
        .swiftpm/

        # macOS
        .DS_Store

        # Cursor (manter .cursor/skills versionado)
        .cursor/projects/

        # Env / secrets
        .env
        *.pem
        """
}
