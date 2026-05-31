# MLTerminalSnippets

App **macOS** para gerenciar repositórios de **Agent Skills**, gerar **projetos Cursor** com scaffold completo e cadastrar **acessos SSH** com abertura no Terminal.

**Bundle:** `me.micheltlutz.MLTerminalSnippets` · **macOS** 15.7+ · **Swift** 6

## Funcionalidades

| Módulo | Descrição |
|--------|-----------|
| **Repositórios** | CRUD de repos Git de skills; 5 built-in na primeira execução (SwiftUI Pro, SwiftData Pro, etc.) |
| **Projetos** | Wizard → contexto, skills, `README.md`, `AGENTS.md`, `.gitignore`, `.cursor/skills/` (cópia do cache local) + regras |
| **Acessos SSH** | Host, utilizador, porta, `.pem` opcional, comando personalizado → **Abrir no Terminal** |
| **iCloud** | SwiftData + CloudKit — sync entre Macs com a mesma Apple ID |

## Início rápido

```bash
git clone <repo>
open MLTerminalSnippets.xcworkspace   # ou .xcodeproj
```

1. Configure **Signing**, **iCloud** e **Hardened Runtime** (Apple Events) no target — ver [docs/setup.md](docs/setup.md).
2. Run no Xcode ou abra `Products/Debug/MLTerminalSnippets.app` pelo Finder (recomendado para permissão de Automação do Terminal).
3. Em **Repositórios**, confira os skills built-in; em **Projetos**, crie um scaffold; em **Acessos SSH**, cadastre um servidor.

## Documentação

| Documento | Conteúdo |
|-----------|----------|
| [**docs/README.md**](docs/README.md) | Índice da documentação |
| [**docs/architecture.md**](docs/architecture.md) | Arquitetura, modelos, fluxos, diagramas |
| [**docs/setup.md**](docs/setup.md) | Xcode, iCloud, sandbox, Terminal, debug |
| [**docs/adr/**](docs/adr/README.md) | Architecture Decision Records (ADRs) |
| [**AGENTS.md**](AGENTS.md) | Contexto para agentes de código (Cursor) |

## ADRs (decisões principais)

| ADR | Decisão |
|-----|---------|
| [0002](docs/adr/0002-mvvm-light-and-feature-folders.md) | MVVM leve + pastas por feature |
| [0003](docs/adr/0003-swiftdata-cloudkit-persistence.md) | SwiftData + CloudKit, regras de modelo |
| [0004](docs/adr/0004-cursor-project-scaffolding.md) | Geração de projetos Cursor |
| [0007](docs/adr/0007-swift-skeleton-and-gitignore-templates.md) | Templates .gitignore + layouts IDE (sem stubs Swift) |
| [0005](docs/adr/0005-three-column-navigation-shell.md) | UI em 3 colunas, sidebar por grupos |
| [0006](docs/adr/0006-ssh-access-and-terminal-launcher.md) | SSH + Terminal.app + fallback clipboard |

## Estrutura do repositório

```
MLTerminalSnippets/          # Target Swift
docs/                      # Documentação e ADRs
.cursor/skills/            # Agent skills (desenvolvimento)
AGENTS.md                  # Instruções para Cursor
```

## Requisitos

- macOS 15.7+, Xcode 16+, Apple ID (iCloud)
- Git; Node opcional (`npx skills add`)

## Skills recomendados (desenvolvimento)

```bash
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
npx skills add https://github.com/twostraws/swiftdata-agent-skill --skill swiftdata-pro
npx skills add https://github.com/twostraws/swift-concurrency-agent-skill --skill swift-concurrency-pro
npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro
npx skills add https://github.com/efremidze/swift-architecture-skill --skill swift-architecture-skill
```

## Licença

Projeto privado — Michel Anderson Lutz Teixeira.
