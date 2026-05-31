# ADR 0004: Scaffold de projetos para Cursor

## Status

Aceito

## Contexto

Objetivo do produto: a partir de **contexto** + **skills selecionados** + **IDE** (Cursor no MVP), gerar uma pasta de projeto pronta para desenvolvimento com agentes.

## Decisão

### Saída gerada

```
{ProjectName}/
├── README.md           # contexto + tabela de skills + fallback npx
├── AGENTS.md           # instruções para o agente Cursor
├── .gitignore          # Xcode, macOS, .cursor/projects (não ignora skills)
├── .cursor/skills/{slug}/   # opcional, via Git
└── .git/               # opcional, git init
```

### Serviços

| Serviço | Função |
|---------|--------|
| `ProjectTemplateBuilder` | Texto de README, AGENTS, gitignore |
| `ProjectScaffolder` | Orquestra criação de pastas e arquivos |
| `SkillGitInstaller` | Sparse clone: `git clone --depth 1 --sparse` + `sparse-checkout set {skillFolderName}` |

### Repositórios built-in (seed)

Cinco skills iniciais (twostraws ×4 + swift-architecture-skill), inseridos uma vez por `SeedDataService`.

### Wizard (5 etapas)

Identidade → Contexto → Skills → Destino (pasta pai, flags) → Revisão (`FileTreePreview`).

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
