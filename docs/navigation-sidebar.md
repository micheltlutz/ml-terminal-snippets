# Sidebar e botão ocultar/mostrar

Guia de uso do menu lateral (coluna 1) e da visibilidade de colunas no shell SwiftUI do **MLTerminalSnippets**.

Decisão de layout em [ADR 0005](adr/0005-three-column-navigation-shell.md). Implementação: `AppSidebarView`, `AppShellView`, `AppState`, `AppSection`.

---

## Visão geral do shell

O app usa um único `NavigationSplitView` de **três colunas**, sempre com a mesma estrutura:

| Coluna | Closure | Conteúdo | Largura |
|--------|---------|----------|---------|
| 1 — Sidebar | (primeira) | `AppSidebarView` | min 180, ideal 200 pt |
| 2 — Conteúdo | `content:` | Lista ou tela da seção ativa | min 260, ideal 300 pt |
| 3 — Detalhe | `detail:` | Inspector, wizard ou empty state | flex |

```swift
NavigationSplitView(columnVisibility: $appState.columnVisibility) {
    AppSidebarView(appState: appState)
} content: {
    contentColumn
        .navigationSplitViewColumnWidth(min: 260, ideal: 300)
} detail: {
    detailColumn
}
```

A seção ativa (`appState.activeSection`) determina o que aparece nas colunas 2 e 3 via `switch` em `AppShellView`.

---

## Formato da sidebar

### Estrutura de dados

A sidebar é montada a partir de dois enums em `Navigation/AppSection.swift`:

| Tipo | Papel |
|------|--------|
| `AppSection` | Item clicável do menu (Início, Repositórios, Projetos, …) |
| `SidebarGroup` | Agrupamento visual na lista (`Section` do SwiftUI) |

Grupos e itens atuais:

| Grupo (`SidebarGroup`) | Itens (`AppSection`) |
|------------------------|----------------------|
| Geral | Início |
| Desenvolvimento | Repositórios, Projetos |
| Terminal & Servidores | Acessos SSH |
| App | Configurações |

Itens futuros (`FutureAppSection`: Templates, Catálogo, Snippets) aparecem **desabilitados** na sidebar até virarem `AppSection` real.

### Implementação (`AppSidebarView`)

```swift
List(selection: $appState.activeSection) {
    ForEach(SidebarGroup.allCases, id: \.self) { group in
        Section(group.title) {
            ForEach(group.sections) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            // rows futuros desabilitados por grupo…
        }
    }
}
.listStyle(.sidebar)
.navigationSplitViewColumnWidth(min: 180, ideal: 200)
.safeAreaInset(edge: .bottom) {
    SyncStatusView(...)
}
```

**Comportamento:**

- **Seleção:** `List(selection: $appState.activeSection)` — trocar item atualiza a coluna 2 e 3 sem navegação empilhada.
- **Estilo:** `.listStyle(.sidebar)` — aparência nativa macOS (destaque, hover).
- **Rodapé:** `SyncStatusView` fixo na base via `.safeAreaInset(edge: .bottom)`.
- **Navegação programática:** `appState.navigateTo(_:)` ou métodos como `startNewProject()` que também definem `activeSection`.

### Adicionar nova seção na sidebar

1. Novo `case` em `AppSection` com `title`, `systemImage` e `sidebarGroup`.
2. Casos correspondentes em `AppShellView.contentColumn` e `detailColumn`.
3. Views da feature em `Views/NovaFeature/`.
4. Nenhuma alteração manual em `AppSidebarView` — ela itera `SidebarGroup.allCases` e `group.sections`.

---

## Botão ocultar/mostrar sidebar

### Configuração atual

A visibilidade das colunas é controlada por **um único binding** entre o shell e o estado global:

| Peça | Arquivo | Valor / uso |
|------|---------|-------------|
| Estado | `AppState.columnVisibility` | Padrão: `.all` (sidebar visível) |
| Binding | `AppShellView` | `NavigationSplitView(columnVisibility: $appState.columnVisibility)` |
| Botão customizado | — | **Não existe** no código; usa-se o toggle **nativo** do macOS |

```swift
// AppState.swift
var columnVisibility: NavigationSplitViewVisibility = .all

// AppShellView.swift
NavigationSplitView(columnVisibility: $appState.columnVisibility) { … }
```

Não há `ToolbarItem` com `sidebar.leading`, nem função `syncColumnVisibility` — o sistema gerencia o toggle quando a toolbar está presente.

### Como o toggle nativo aparece

No macOS, o `NavigationSplitView` injeta automaticamente o botão de sidebar (ícone de barra lateral, canto superior esquerdo da toolbar) quando:

1. O split recebe `columnVisibility:` como `Binding`.
2. A coluna visível expõe uma **toolbar de navegação**, o que exige `.navigationTitle(...)` na view-folha.

Views que **já** definem título (e portanto podem exibir o toggle na coluna 2):

| View | `.navigationTitle` |
|------|-------------------|
| `RepositoryListView` | `"Repositórios"` |
| `ProjectListView` | `"Projetos"` |
| `SSHConnectionListView` | `"Acessos SSH"` |
| `SettingsPlaceholderView` | `"Configurações"` |
| Inspectors / wizard | título dinâmico por contexto |

**Exceção:** `HomeView` **não** usa `.navigationTitle`. Na seção Início, a toolbar (e o botão nativo de sidebar) pode não aparecer na coluna de conteúdo.

### Valores de `NavigationSplitViewVisibility` (3 colunas)

Com o inicializador de **3 colunas** (`sidebar` + `content` + `detail`):

| Valor | Efeito |
|-------|--------|
| `.all` | Sidebar + conteúdo + detalhe visíveis (padrão) |
| `.doubleColumn` | Sidebar **oculta**; conteúdo + detalhe permanecem |
| `.detailOnly` | Apenas a coluna de detalhe (comportamento raro neste app) |

> **Armadilha:** `.doubleColumn` num split de 3 colunas **esconde a sidebar**, não “esconde o detalhe”. Não use `.doubleColumn` para colapsar só o inspector — use estado de seleção/inspector em `AppState`.

O usuário altera esse valor pelo botão nativo; o binding persiste em `AppState` enquanto o app estiver aberto. Trocar de seção **não** reseta `columnVisibility` hoje — se a sidebar foi ocultada, permanece oculta ao mudar de menu.

### Onde **não** adicionar botão

- **Não** duplique o toggle com `Button { … } label: { Label("Barra lateral", systemImage: "sidebar.leading") }` nas listas que já têm `.navigationTitle` — o macOS já fornece o controle.
- **Não** coloque toggle na sidebar (`AppSidebarView`); o padrão HIG coloca-o na toolbar da coluna principal à direita da sidebar.

### Se o toggle não aparecer (checklist)

1. A view da coluna 2 (ou 3, conforme o caso) tem `.navigationTitle(...)`?
2. `NavigationSplitView` recebe `columnVisibility: $appState.columnVisibility`?
3. A view está dentro da hierarquia do split (não em sheet/popover)?

Para a seção **Início**, adicionar `.navigationTitle("Início")` em `HomeView` é suficiente para habilitar a toolbar e o botão nativo.

---

## Mapa seção → colunas

| Seção | Coluna 2 (`content`) | Coluna 3 (`detail`) |
|-------|----------------------|---------------------|
| Início | `HomeView` | `HomeView` (mesmo conteúdo) |
| Repositórios | `RepositoryListView` | `RepositoryInspectorView` |
| Projetos | `ProjectListView` | wizard / inspector / empty state |
| Acessos SSH | `SSHConnectionListView` | `SSHConnectionInspectorView` |
| Configurações | `SettingsPlaceholderView` | `SettingsPlaceholderView` (mesmo conteúdo) |

Início e Configurações repetem a mesma view nas colunas 2 e 3 — comportamento conhecido; ver consequências no [ADR 0005](adr/0005-three-column-navigation-shell.md).

---

## Referência rápida de arquivos

| Arquivo | Responsabilidade |
|---------|------------------|
| `Navigation/AppSection.swift` | Enum de seções, ícones, grupos |
| `Navigation/AppState.swift` | `activeSection`, `columnVisibility`, seleções e modos de inspector |
| `Views/Shell/AppSidebarView.swift` | Lista lateral agrupada |
| `Views/Shell/AppShellView.swift` | `NavigationSplitView`, roteamento por seção |
| `Views/*/…ListView.swift` | Coluna 2 + `.navigationTitle` + toolbar de ações |

---

## Leitura relacionada

- [ADR 0005 — Shell de navegação em 3 colunas](adr/0005-three-column-navigation-shell.md)
- [Arquitetura](architecture.md)
