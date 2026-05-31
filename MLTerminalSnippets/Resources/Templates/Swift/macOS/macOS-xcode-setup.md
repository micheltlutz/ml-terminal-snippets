# Configurar projeto no Xcode (macOS)

Este diretório foi gerado sem `.xcodeproj`. Siga um dos caminhos:

## Opção A — Novo projeto na pasta existente

1. Abra o Xcode → **File → New → Project…**
2. Escolha **macOS → App**, SwiftUI, Swift.
3. Product Name: `{{PROJECT_NAME}}`, Bundle ID: `{{BUNDLE_ID}}`.
4. Salve **dentro** desta pasta (a raiz que contém `{{PROJECT_NAME}}/`, `docs/`, etc.).
5. Apague os arquivos duplicados que o Xcode criar se já existirem (`{{PROJECT_NAME}}App.swift`, `ContentView.swift`).
6. **File → Add Files to "{{PROJECT_NAME}}"…** e adicione a pasta `{{PROJECT_NAME}}/`.

## Opção B — Adicionar ao projeto existente

1. Crie um App macOS no Xcode em outro local.
2. **Add Files…** apontando para `{{PROJECT_NAME}}/`.
3. Marque **Copy items if needed** apenas se quiser copiar (geralmente não).

## Depois

- Abra o projeto no [Cursor](https://cursor.com) para usar `AGENTS.md` e `.cursor/skills/`.
- Rode **Product → Build** (⌘B).
