# ADR 0004: Scaffold de projetos para Cursor

## Status

Aceito (atualizado — foco em contexto e skills, sem código Swift)

## Contexto

Objetivo do produto: a partir de **contexto** + **skills selecionados** + **IDE** (Cursor no MVP), gerar uma pasta de projeto pronta para desenvolvimento com agentes.

## Decisão

### Saída gerada

Ver [ADR 0007](0007-swift-skeleton-and-gitignore-templates.md). Resumo:

```
{ProjectName}/
├── docs/xcode-setup.md   # apenas macOS/iOS (guia manual Xcode)
├── README.md, AGENTS.md, .gitignore (template por tipo; sem git init automático)
└── .cursor/skills/{slug}/, .cursor/rules/swift-project.mdc, .cursorignore
```

Não há geração de `.swift`, `Package.swift` nem `.xcodeproj`.

### Serviços

| Serviço | Função |
|---------|--------|
| `ProjectDocsTemplateLoader` | `docs/xcode-setup.md` para apps macOS/iOS |
| `GitignoreTemplateLoader` | `.gitignore` do bundle |
| `IDEProjectLayout` / `CursorProjectConfigurator` | Caminhos por IDE + regras Cursor |
| `ProjectTemplateBuilder` | README e AGENTS com tabela "Quando usar" |
| `ProjectScaffolder` | Orquestra criação de pastas e arquivos |
| `SkillCacheService` | Cache local (bundle + Application Support); cópia para projetos |
| `SkillGitInstaller` | Reservado (git sparse clone — não usado no sandbox) |

### Repositórios built-in (seed)

Cinco skills iniciais (twostraws ×4 + swift-architecture-skill), inseridos uma vez por `SeedDataService`, com campo **Quando usar** (`notes`).

### Wizard (5 etapas)

Identidade (nome, **tipo Swift**, IDE) → Contexto → Skills → Destino (pasta pai, flags) → Revisão (`FileTreePreview`).

Persistência: `SnippetProject` com bookmark da pasta gerada para reabrir no Finder/Cursor.

### IDE

`IDETool.cursor` activo; VS Code e Claude Code reservados na UI (“Em breve”).

## Alternativas rejeitadas

- **Apenas documentar `npx skills add`** — sem skills no repo; pior DX
- **Submodule Git por skill** — mais pesado para usuário casual
- **Copiar de cache global `~/.cursor/skills`** — fora do escopo sandbox/MVP
- **Gerar `.xcodeproj` ou stubs Swift via CLI** — sem comando Apple oficial; stubs sem projeto Xcode têm baixo valor

## Consequências

### Positivas

- Projeto versionável com skills em `.cursor/skills/`
- AGENTS.md com instruções de uso por skill
- Fallback `npx` documentado no README se clone falhar
- Histórico de projetos no app

### Negativas

- Clone Git requer rede e `git` no PATH — **substituído por cache local** (cópia de `SkillsCache.bundle` ou importação do usuário)
- Sandbox: pasta pai só via file picker (security-scoped)
- Regeneração completa de scaffold não implementada no MVP (apenas histórico + reabrir)
- Usuário cria código Swift / `.xcodeproj` manualmente quando necessário
