# ADR 0006: Acessos SSH e integração com Terminal.app

## Status

Aceito

## Contexto

Usuário pediu cadastro de **acessos SSH** com:

- Host, porta, usuário
- Chave `.pem` opcional (login sem senha)
- Comando personalizado (ex.: provisionar usuário, `ssh-copy-id`)
- **Abrir no Terminal** com o comando salvo

IDE alvo: **Terminal.app** (não iTerm no MVP).

## Decisão

### Modelo `SSHConnection`

- `SSHAuthMode.standard` — `SSHCommandBuilder` gera `ssh [-i key] [-p port] user@host`
- `SSHAuthMode.customCommand` — string verbatim
- `privateKeyBookmark` + `privateKeyPathDisplay` para arquivo `.pem`

Sync iCloud dos metadados; bookmark pode precisar re-seleção em outro Mac.

### UI

Mesmo padrão Repositórios: lista (coluna 2) + inspector (coluna 3). Templates de comando no modo personalizado.

### `TerminalLauncher` (@MainActor)

Ordem de tentativas:

1. `/usr/bin/osascript` com AppleScript (`tell application "Terminal" … do script`)
2. `NSAppleScript` embutido
3. **Fallback:** abre Terminal via `NSWorkspace`, **copia comando** para pasteboard, erro `automationDenied`

### Abordagens rejeitadas para abrir Terminal

| Abordagem | Motivo da rejeição |
|-----------|-------------------|
| Arquivo `.command` + `NSWorkspace.open` | Gatekeeper: “arquivo danificado” (quarentena) |
| Apenas AppleScript sem `launch` | Erro “Application isn’t running” |

### Segurança e Hardened Runtime

Entitlements:

- `com.apple.security.automation.apple-events`
- `com.apple.security.temporary-exception.apple-events` → `com.apple.Terminal`
- `NSAppleEventsUsageDescription` no Info.plist

**TCC Automação** é permissão do usuário, separada do Hardened Runtime. Debug só pelo Xcode muitas vezes não mostra o diálogo — documentado em [setup.md](../setup.md): executar `.app` pelo Finder uma vez.

## Consequências

### Positivas

- Fluxo SSH integrado na sidebar “Terminal & Servidores”
- Funciona sem Automação (fallback clipboard)
- Testes unitários em `SSHCommandBuilder`

### Negativas

- Apple Events frágil em sandbox/dev
- Sem armazenamento de senha (Keychain) no MVP
- Sem teste de conectividade SSH em background
- `Thread.sleep` / semáforo em `launchTerminalIfNeeded` — aceitável no MVP, melhorar com async depois

## Referências

- [setup.md](../setup.md) — Automação e Xcode
- `MLTerminalSnippets/Services/TerminalLauncher.swift`
- `MLTerminalSnippets/Services/SSHCommandBuilder.swift`
