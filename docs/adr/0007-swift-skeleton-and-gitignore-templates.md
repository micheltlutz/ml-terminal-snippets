# ADR 0007: Esqueleto Swift, templates .gitignore e layouts por IDE

## Status

Aceito

## Contexto

O gerador de projetos (ADR 0004) produzia apenas documentação Cursor (`README.md`, `AGENTS.md`, `.gitignore` inline, `.cursor/skills/`). Era necessário:

- Esqueleto Swift alinhado ao tipo de alvo (macOS, iOS, SPM), **sem** `.xcodeproj`.
- `.gitignore` como **templates no bundle** do app (três variantes).
- Abstração de caminhos por IDE (Cursor principal; VS Code e Claude Code preparados).
- Configuração Cursor adicional: `.cursor/rules/swift-project.mdc`, `.cursorignore`.

## Decisão

### Tipos

- `SwiftProjectKind`: `macOSApp`, `iOSApp`, `swiftPackage`.
- `IDEProjectLayout`: mapeia skills, arquivo do agente e regras por `IDETool`.
- `IDEProjectLayout.effectiveLayout(for:)`: no MVP, IDEs não disponíveis usam layout **Cursor**.

### Templates no bundle

```
MLTerminalSnippets/Resources/Templates/
├── Gitignore/          # swift-macos-xcode, swift-ios-xcode, swift-spm
├── Swift/              # macOS, iOS, spm (.swift.tpl — não compilados pelo target)
└── Cursor/             # swift-project.mdc, cursorignore
```

### Serviços

| Serviço | Função |
|---------|--------|
| `SwiftProjectSkeletonBuilder` | Pastas + stubs Swift a partir de `.tpl` |
| `GitignoreTemplateLoader` | Lê `.gitignore` do bundle por `SwiftProjectKind` |
| `CursorProjectConfigurator` | Regras + `.cursorignore` (só `IDETool.cursor`) |
| `TemplateTokenReplacer` | `{{PROJECT_NAME}}`, `{{BUNDLE_ID}}` |
| `SkillGitInstaller` | `skillsRoot: URL` explícito (não path fixo) |

### Saída gerada (exemplo macOS + Cursor)

```
{ProjectName}/
├── {ProjectName}/App|Models|Views|Services
├── {ProjectName}Tests/
├── docs/xcode-setup.md
├── README.md, AGENTS.md, .gitignore
├── .cursor/skills/, .cursor/rules/swift-project.mdc
└── .cursorignore
```

### Wizard e persistência

- Picker **Tipo de projeto** na etapa Identidade.
- `SnippetProject.swiftProjectKindRaw` (default `macOSApp`).

## Alternativas rejeitadas

- **Gerar `.xcodeproj` programaticamente** — complexidade alta; fora do escopo.
- **`.swift` nos templates do app** — Xcode synchronized group tentaria compilar; usamos `.swift.tpl`.
- **Um único `.gitignore` inline** — não cobre SPM vs iOS vs macOS.

## Consequências

### Positivas

- Projetos prontos para código Swift e para agentes Cursor.
- Gitignore e stubs versionáveis no repositório do app.
- Extensível para VS Code / Claude Code sem refatorar o orquestrador.

### Negativas

- Testes de bundle dependem do host app (recursos no target principal).
- Usuário ainda cria `.xcodeproj` manualmente (`docs/xcode-setup.md`).
