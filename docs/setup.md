# Configuração e execução

## Requisitos

- macOS 15.7+
- Xcode 16+ (Swift 6)
- Apple ID com iCloud (sync entre Macs)
- Git (`/usr/bin/git` ou Homebrew)
- Node (opcional, para `npx skills add` no repo de desenvolvimento)

## Abrir o projeto

- Workspace: `MLTerminalSnippets.xcworkspace`
- Projeto: `MLTerminalSnippets.xcodeproj`

## Signing & Capabilities (Xcode)

Target **MLTerminalSnippets**:

| Capability | Detalhe |
|------------|---------|
| **iCloud** | CloudKit, container `iCloud.me.micheltlutz.MLTerminalSnippets` |
| **Hardened Runtime** | Ativo; marcar **Apple Events (Outgoing)** |
| **App Sandbox** | Via entitlements |

## Entitlements

Arquivo: [`MLTerminalSnippets/MLTerminalSnippets.entitlements`](../MLTerminalSnippets/MLTerminalSnippets.entitlements)

| Chave | Função |
|-------|--------|
| `com.apple.security.app-sandbox` | Sandbox |
| `com.apple.security.files.user-selected.read-write` | Escolher pasta de projeto e `.pem` |
| `com.apple.security.network.client` | `git clone` de skills |
| `com.apple.security.automation.apple-events` | Controlar Terminal.app |
| `com.apple.security.temporary-exception.apple-events` | Destino `com.apple.Terminal` (Hardened Runtime) |
| iCloud / CloudKit | Sync SwiftData |

`NSAppleEventsUsageDescription` está no Info.plist (gerado pelo Xcode).

## iCloud

1. Mesma Apple ID no MacBook e Mac Mini.
2. iCloud Drive ativo.
3. Primeiro sync pode exigir app fora do simulador.

Se o schema SwiftData mudar e o container falhar ao abrir, o app tenta remover o store local uma vez e recriar (perda de dados locais não sincronizados).

Reset manual do store:

```bash
rm -rf ~/Library/Containers/me.micheltlutz.MLTerminalSnippets/Data/Library/Application\ Support/default.store*
```

## Terminal e Automação (SSH)

### Por que Automação não aparece no Xcode

O macOS só lista o app em **Ajustes → Privacidade → Automação** após o primeiro pedido de controle do Terminal. Depuração só com **Run** no Xcode frequentemente não dispara o diálogo.

### Habilitar execução automática

1. **Product → Show Build Folder in Finder**
2. Abra `Products/Debug/MLTerminalSnippets.app` (duplo clique)
3. **Acessos SSH** → **Abrir no Terminal** → aceite o diálogo
4. Confirme em **Privacidade → Automação**

### Fallback

Sem permissão: o app abre o Terminal, **copia o comando** para a área de transferência — cole com **⌘V**.

### Reset de permissões

```bash
tccutil reset AppleEvents me.micheltlutz.MLTerminalSnippets
```

## Skills para desenvolvimento (Cursor)

```bash
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro
npx skills add https://github.com/twostraws/swiftdata-agent-skill --skill swiftdata-pro
npx skills add https://github.com/twostraws/swift-concurrency-agent-skill --skill swift-concurrency-pro
npx skills add https://github.com/twostraws/swift-testing-agent-skill --skill swift-testing-pro
npx skills add https://github.com/efremidze/swift-architecture-skill --skill swift-architecture-skill
```

Ou use as cópias em [`.cursor/skills/`](../.cursor/skills/).

## Build

```bash
# Requer Xcode (xcodebuild), não apenas Command Line Tools
xcodebuild -scheme MLTerminalSnippets -destination 'platform=macOS' build
```
