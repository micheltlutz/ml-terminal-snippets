# ADR 0004: Scaffold de projetos para Cursor

## Status

Aceito

## Contexto

Objetivo do produto: a partir de **contexto** + **skills selecionados** + **IDE** (Cursor no MVP), gerar uma pasta de projeto pronta para desenvolvimento com agentes.

## Decisão

### Saída gerada

Ver [ADR 0007](0007-swift-skeleton-and-gitignore-templates.md) para o esqueleto Swift completo. Resumo:

```
{ProjectName}/
├── {ProjectName}/      # App, Models, Views, Services (ou Package.swift / Sources para SPM)
├── docs/xcode-setup.md # apps macOS/iOS
├── README.md, AGENTS.md, .gitignore (template por tipo)
├── .cursor/skills/{slug}/, .cursor/rules/swift-project.mdc, .cursorignore
└── .git/               # opcional
```

### Serviços

| Serviço | Função |
|---------|--------|
| `SwiftProjectSkeletonBuilder` | Esqueleto Swift por `SwiftProjectKind` |
| `GitignoreTemplateLoader` | `.gitignore` do bundle |
| `IDEProjectLayout` / `CursorProjectConfigurator` | Caminhos por IDE + regras Cursor |
| `ProjectTemplateBuilder` | Texto de README e AGENTS |
| `ProjectScaffolder` | Orquestra criação de pastas e arquivos |
| `SkillGitInstaller` | Sparse clone em `skillsRoot` configurável |

### Repositórios built-in (seed)

Cinco skills iniciais (twostraws ×4 + swift-architecture-skill), inseridos uma vez por `SeedDataService`.

### Wizard (5 etapas)

Identidade (nome, **tipo Swift**, IDE) → Contexto → Skills → Destino (pasta pai, flags) → Revisão (`FileTreePreview`).

Persistência: `SnippetProject` com bookmark da pasta gerada para reabrir no Finder/Cursor.

### IDE

`IDETool.cursor` activo; VS Code e Claude Code reservados na UI (“Em breve”).

## Alternativas rejeitadas

- **Apenas documentar `npx skills add`** — sem skills no repo; pior DX
- **Submodule Git por skill** — mais pesado para usuário casual
- **Copiar de cache global `~/.cursor/skills`** — fora do escopo sandbox/MVP

## Consequências

### Positivas

- Projeto versionável com skills em `.cursor/skills/`
- Fallback `npx` documentado no README se clone falhar
- Histórico de projetos no app

### Negativas

- Clone Git requer rede e `git` no PATH
- Sandbox: pasta pai só via file picker (security-scoped)
- Regeneração completa de scaffold não implementada no MVP (apenas histórico + reabrir)
