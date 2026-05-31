# AGENTS.md — MLTerminalSnippets

## Stack

- Swift 6.0+
- SwiftUI (macOS 15.7+)
- SwiftData com sincronização CloudKit (iCloud)
- App Sandbox com acesso a pastas escolhidas pelo usuário e rede para `git clone` de skills

## Contexto do projeto

MLTerminalSnippets é um app macOS para:

1. Cadastrar e sincronizar repositórios Git de Agent Skills (via iCloud entre Macs).
2. Criar projetos com contexto, skills selecionados e IDE (Cursor no MVP).
3. Gerar scaffold: esqueleto Swift (macOS/iOS/SPM), `README.md`, `AGENTS.md`, `.gitignore` (templates no bundle), `.cursor/skills/` + `.cursor/rules/` (clone sparse do Git).

## Skills instalados (`.cursor/skills/`)

Use estes skills ao revisar ou implementar código neste repositório:

| Skill | Quando usar |
|-------|-------------|
| `swiftui-pro` | Views SwiftUI, navegação, acessibilidade, performance de UI |
| `swiftdata-pro` | Modelos `@Model`, CloudKit, relacionamentos, queries |
| `swift-concurrency-pro` | `async`/`await`, `@MainActor`, `Sendable`, task groups |
| `swift-testing-pro` | Testes com framework Testing (`@Test`, `#expect`) |
| `swift-architecture-skill` | MVVM, estrutura de pastas, decisões de arquitetura |

## Documentação

- [docs/architecture.md](docs/architecture.md) — arquitetura e fluxos
- [docs/setup.md](docs/setup.md) — Xcode, iCloud, Terminal
- [docs/adr/](docs/adr/README.md) — decisões arquiteturais (ADRs)

## Convenções

- Organize por feature: `Models/`, `Services/`, `Views/`, `Navigation/`.
- Mantenha ViewModels/`AppState` enxutos; lógica de arquivo/Git em `Services/`.
- UI: `NavigationSplitView` 3 colunas; não introduza sheets para CRUD principal.
- Prefira Swift Concurrency; UI em `@MainActor`.
- Não adicione dependências SPM sem confirmar com o usuário.

## Instalar skills localmente

```bash
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
npx skills add https://github.com/twostraws/swiftdata-agent-skill --skill swiftdata-pro
npx skills add https://github.com/twostraws/swift-concurrency-agent-skill --skill swift-concurrency-pro
npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro
npx skills add https://github.com/efremidze/swift-architecture-skill --skill swift-architecture-skill
```
