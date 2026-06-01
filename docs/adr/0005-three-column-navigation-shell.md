# ADR 0005: Shell de navegação em 3 colunas

## Status

Aceito

## Contexto

O app terá várias áreas (Início, Repositórios, Projetos, SSH, Configurações) e mais no futuro (Templates, Snippets). Era necessário um padrão macOS nativo, eficiente e extensível.

## Decisão

### Layout

`NavigationSplitView` com três colunas:

| Coluna | Conteúdo | Largura |
|--------|----------|---------|
| 1 — Sidebar | Grupos + seções | ~200pt |
| 2 — Lista | Busca + itens + toolbar | ~300pt |
| 3 — Detalhe | Inspector / wizard / empty state | flex |

### Grupos da sidebar (`SidebarGroup`)

| Grupo | Itens |
|-------|--------|
| Geral | Início |
| Desenvolvimento | Repositórios, Projetos (+ futuros Templates, Catálogo) |
| Terminal & Servidores | Acessos SSH (+ Snippets em breve) |
| App | Configurações |

### Navegação

- `AppSection` enum — novo caso = nova feature
- `AppState` (`@Observable`) — seleção, busca, modos de inspector (`RepositoryInspectorMode`, `SSHInspectorMode`, `ProjectDetailMode`)
- CRUD no **inspector** (coluna 3), não em sheets

### Sidebar e visibilidade de colunas

- Coluna 1: `AppSidebarView` — `List` agrupada por `SidebarGroup`, seleção em `$appState.activeSection`, estilo `.sidebar`, largura ~200 pt.
- Visibilidade: `AppState.columnVisibility` (padrão `.all`) ligado a `NavigationSplitView(columnVisibility:)` em `AppShellView`.
- Botão ocultar/mostrar: toggle **nativo** do macOS (sem botão customizado no código). Exige `.navigationTitle(...)` na view-folha da coluna visível para a toolbar aparecer.
- Detalhes, valores de `NavigationSplitViewVisibility` e checklist: [navigation-sidebar.md](../navigation-sidebar.md).

### Componentes partilhados

`SearchField`, `EmptyStateView`, `SyncStatusView`, `SkillChip`, `StepIndicator`, `FileTreePreview`.

### Atalhos

- `⌘N` — novo (contextual por secção)
- `⌘S` — salvar inspector
- `⌘↩` — abrir Terminal (SSH, modo view)

## Alternativas rejeitadas

- **Sheets para CRUD** — pior fluxo em desktop
- **Single column + tabs** — menos HIG macOS
- **TCA router** — complexidade desnecessária

## Consequências

### Positivas

- UX consistente entre Repositórios, Projetos e SSH
- Home com CTAs e contadores
- Extensão: adicionar `AppSection` + `Views/NovaFeature/` sem reescrever shell

### Negativas

- Home duplicada nas colunas 2 e 3 (aceitável)
- `AppState` cresce com cada feature (mitigar com sub-estados por domínio no futuro)
