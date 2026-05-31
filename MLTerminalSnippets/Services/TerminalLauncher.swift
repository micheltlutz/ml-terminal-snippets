//
//  TerminalLauncher.swift
//  MLTerminalSnippets
//

import AppKit
import Foundation

enum TerminalLauncherError: LocalizedError {
    case terminalNotAvailable
    case launchFailed(String)
    case automationDenied(commandCopied: Bool)

    var errorDescription: String? {
        switch self {
        case .terminalNotAvailable:
            "Terminal.app não encontrado no sistema."
        case .launchFailed(let detail):
            "Não foi possível abrir o Terminal: \(detail)"
        case .automationDenied(let copied):
            if copied {
                """
                Automação não autorizada. O Terminal foi aberto e o comando SSH foi copiado para a área de transferência — cole com ⌘V e pressione Enter.

                Para habilitar execução automática: execute o app pelo Finder (Product → Show Build Folder → abra MLTerminalSnippets.app) e aceite o diálogo, ou em Ajustes → Privacidade e Segurança → Automação marque MLTerminalSnippets → Terminal.
                """
            } else {
                "Automação não autorizada para controlar o Terminal."
            }
        }
    }
}

/// `NSWorkspace` e AppleScript exigem MainActor no Swift 6.
@MainActor
enum TerminalLauncher {
    private static let terminalPaths = [
        "/System/Applications/Utilities/Terminal.app",
        "/Applications/Utilities/Terminal.app",
    ]

    static var isTerminalAvailable: Bool {
        terminalAppURL() != nil
    }

    static func open(command: String) throws {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard isTerminalAvailable else { throw TerminalLauncherError.terminalNotAvailable }

        if (try? openViaOsascriptProcess(trimmed)) == true { return }
        if (try? openViaAppleScript(trimmed)) == true { return }

        // Sem permissão de Automação (comum ao rodar só pelo Xcode): fallback manual
        let copied = copyCommandToPasteboard(trimmed)
        openTerminalApplicationOnly()
        throw TerminalLauncherError.automationDenied(commandCopied: copied)
    }

    /// Executa AppleScript via `/usr/bin/osascript`.
    private static func openViaOsascriptProcess(_ command: String) throws -> Bool {
        launchTerminalIfNeeded()

        let source = appleScriptSource(for: command)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return false
        }

        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let message, !message.isEmpty {
                throw TerminalLauncherError.launchFailed(message)
            }
            return false
        }

        return true
    }

    private static func openViaAppleScript(_ command: String) throws -> Bool {
        launchTerminalIfNeeded()

        let source = appleScriptSource(for: command)
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: source) else {
            return false
        }
        appleScript.executeAndReturnError(&error)
        if error != nil {
            return false
        }
        return true
    }

    private static func appleScriptSource(for command: String) -> String {
        let escaped = escapeForAppleScript(command)
        return """
        tell application "Terminal"
            launch
            activate
            delay 0.5
            do script "\(escaped)"
        end tell
        """
    }

    private static func launchTerminalIfNeeded() {
        openTerminalApplicationOnly()
        Thread.sleep(forTimeInterval: 0.35)
    }

    /// Abre o Terminal sem Apple Events (não exige Automação).
    static func openTerminalApplicationOnly() {
        guard let appURL = terminalAppURL() else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, _ in }
    }

    @discardableResult
    static func copyCommandToPasteboard(_ command: String) -> Bool {
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(command, forType: .string)
    }

    private static func terminalAppURL() -> URL? {
        for path in terminalPaths where FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    /// Escapa o comando para uso dentro de aspas duplas em AppleScript.
    static func escapeForAppleScript(_ command: String) -> String {
        command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
