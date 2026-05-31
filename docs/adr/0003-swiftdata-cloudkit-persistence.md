# ADR 0003: SwiftData com sincronização CloudKit

## Status

Aceito

## Contexto

O usuário precisa dos mesmos **repositórios de skills**, **projetos** e **acessos SSH** no MacBook e Mac Mini, via a mesma Apple ID.

Alternativas:

- **UserDefaults / JSON local** — sem sync
- **Core Data + CloudKit** — maduro, mais boilerplate
- **SwiftData + `cloudKitDatabase: .automatic`** — integração moderna com SwiftUI

## Decisão

Usar **SwiftData** com:

```swift
ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
```

Modelos:

- `SkillRepository`
- `SnippetProject` (relação many-to-many com skills)
- `SSHConnection`

### Regras CloudKit (obrigatórias)

Conforme [swiftdata-pro — cloudkit.md](https://github.com/twostraws/SwiftData-Agent-Skill):

1. **Sem** `@Attribute(.unique)` nem `#Unique`
2. Todas as propriedades persistidas com **valor padrão** na declaração (`var name: String = ""`)
3. Relacionamentos **opcionais**

### Bookmarks de arquivos

- `outputPathBookmark` (projetos) e `privateKeyBookmark` (SSH) usam security-scoped bookmarks
- `BookmarkStore` com métodos **`nonisolated`** — uso a partir de `@Model` e serviços fora do MainActor
- Caminhos `.pem` sincronizam como string; bookmark pode exigir re-seleção em outro Mac

### Recuperação de schema

Se o container falhar após mudança de modelo, `MLTerminalSnippetsApp` remove o store local e tenta recriar (uma vez).

## Consequências

### Positivas

- Sync automático entre dispositivos com iCloud
- `@Query` nas Views para listas reactivas
- Modelo único para as três áreas do produto

### Negativas

- Conflitos de sync eventual (CloudKit) — UI mostra estado genérico de iCloud
- Migrações complexas exigem planeamento (MVP: reset local aceitável em dev)
- Simulador com limitações para CloudKit
