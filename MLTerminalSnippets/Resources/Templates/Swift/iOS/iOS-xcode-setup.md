# Configurar projeto no Xcode (iOS)

Este diretório foi gerado sem `.xcodeproj`. Siga um dos caminhos:

## Opção A — Novo projeto na pasta existente

1. Abra o Xcode → **File → New → Project…**
2. Escolha **iOS → App**, SwiftUI, Swift.
3. Product Name: `{{PROJECT_NAME}}`, Bundle ID: `{{BUNDLE_ID}}`.
4. Salve **dentro** desta pasta (a raiz que contém `{{PROJECT_NAME}}/`, `docs/`, etc.).
5. Apague arquivos duplicados se o Xcode recriar `{{PROJECT_NAME}}App.swift` / `ContentView.swift`.
6. **File → Add Files to "{{PROJECT_NAME}}"…** e adicione a pasta `{{PROJECT_NAME}}/`.

## Opção B — Adicionar ao projeto existente

1. Crie um App iOS no Xcode.
2. **Add Files…** apontando para `{{PROJECT_NAME}}/`.

## Depois

- Abra no Cursor para `AGENTS.md` e skills em `.cursor/skills/`.
- Selecione um simulador e **Product → Build** (⌘B).
