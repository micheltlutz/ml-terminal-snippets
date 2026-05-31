# ADR 0002: MVVM leve e pastas por feature

## Status

Aceito

## Contexto

O app combina CRUD, wizard multi-etapa, geração de arquivos no disco e integração com Terminal. Era necessário definir um estilo arquitetural proporcional ao tamanho do projeto, sem over-engineering.

Alternativas consideradas:

- **TCA / Clean Architecture** — camadas e boilerplate excessivos para o escopo atual
- **Tudo em Views** — lógica de Git, templates e SSH misturada com SwiftUI
- **MVVM leve** — `AppState` + ViewModels mínimos (drafts/validação) + `Services`

## Decisão

Adotar **MVVM leve** com organização **por feature** no target:

| Pasta | Responsabilidade |
|-------|------------------|
| `Models/` | `@Model`, enums (`IDETool`, `SSHAuthMode`) |
| `Services/` | I/O, Git, templates, Terminal, bookmarks |
| `ViewModels/` | `*FormDraft`, validadores (sem camada espessa de VM por ecrã) |
| `Navigation/` | `AppState`, `AppSection` |
| `Views/{Feature}/` | SwiftUI por domínio |

Regra: lógica que não é UI nem persistência direta vive em **Services**, não em Views.

## Consequências

### Positivas

- Código legível e alinhado com [swift-architecture-skill](https://github.com/efremidze/swift-architecture-skill) para apps pequenos
- Fácil localizar código por funcionalidade
- Testes unitários focados em `Services` (ex.: `SSHCommandBuilder`, `ProjectTemplateBuilder`)

### Negativas

- Sem injecção de dependências formal; `Services` são enums/namespaces estáticos
- `AppState` concentra estado de navegação de várias features (aceitável no MVP)
