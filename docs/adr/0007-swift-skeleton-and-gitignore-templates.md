# ADR 0007: Templates .gitignore, layouts por IDE e documentação de setup

## Status

Aceito (atualizado — esqueleto Swift removido)

## Contexto

O gerador de projetos (ADR 0004) evoluiu de documentação Cursor pura para incluir stubs Swift (decisão inicial deste ADR). Revisão posterior: **sem `.xcodeproj`**, stubs Swift têm baixo valor; o foco passa a ser contexto, skills clonados e documentação para agentes.

Permanecem necessários:

- `.gitignore` como **templates no bundle** (três variantes por `SwiftProjectKind`).
- Abstração de caminhos por IDE (Cursor principal; VS Code e Claude Code preparados).
- Configuração Cursor: `.cursor/rules/swift-project.mdc`, `.cursorignore`.
- Guia `docs/xcode-setup.md` para apps macOS/iOS (sem gerar código).

## Decisão

### Tipos

- `SwiftProjectKind`: `macOSApp`, `iOSApp`, `swiftPackage` — afeta `.gitignore`, textos de stack e README (não gera código).
- `IDEProjectLayout`: mapeia skills, arquivo do agente e regras por `IDETool`.
- `IDEProjectLayout.effectiveLayout(for:)`: no MVP, IDEs não disponíveis usam layout **Cursor**.

### Templates no bundle

```
MLTerminalSnippets/Resources/
├── Gitignore/              # swift-macos-xcode, swift-ios-xcode, swift-spm
├── Swift/                  # macOS-xcode-setup.md, iOS-xcode-setup.md (somente docs)
├── Cursor/                 # swift-project.mdc, cursorignore
└── SkillsCache.bundle/     # built-ins (preserva hierarquia; evita colisão no Copy Resources)
    └── Contents/Resources/{slug}/
```

### Serviços

| Serviço | Função |
|---------|--------|
| `ProjectDocsTemplateLoader` | Copia `docs/xcode-setup.md` para macOS/iOS |
| `GitignoreTemplateLoader` | Lê `.gitignore` do bundle por `SwiftProjectKind` |
| `CursorProjectConfigurator` | Regras + `.cursorignore` (só `IDETool.cursor`) |
| `TemplateTokenReplacer` | `{{PROJECT_NAME}}`, `{{BUNDLE_ID}}`, `{{SKILL_SLUGS}}` |
| `SkillCacheService` | Cache local; cópia para `.cursor/skills/` |

~~`SwiftProjectSkeletonBuilder`~~ — **removido** (stubs `.swift` e `Package.swift` não são mais gerados).

### Saída gerada (exemplo macOS + Cursor)

```
{ProjectName}/
├── docs/xcode-setup.md
├── README.md, AGENTS.md, .gitignore
├── .cursor/skills/{slug}/SKILL.md
├── .cursor/rules/swift-project.mdc
└── .cursorignore
```

### Wizard e persistência

- Picker **Tipo de projeto** na etapa Identidade.
- `SnippetProject.swiftProjectKindRaw` (default `macOSApp`).

## Alternativas rejeitadas

- **Gerar `.xcodeproj` programaticamente** — complexidade alta; fora do escopo.
- **Stubs Swift sem projeto Xcode** — removidos por baixo valor operacional.
- **Um único `.gitignore` inline** — não cobre SPM vs iOS vs macOS.

## Consequências

### Positivas

- Projetos prontos para agentes Cursor com skills e contexto versionáveis.
- Gitignore e guias versionáveis no repositório do app.
- Extensível para VS Code / Claude Code sem refatorar o orquestrador.

### Negativas

- Testes de bundle dependem do host app (recursos no target principal).
- Usuário cria código Swift e `.xcodeproj` manualmente (`docs/xcode-setup.md` ou `swift package init`).
