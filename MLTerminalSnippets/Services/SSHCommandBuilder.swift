//
//  SSHCommandBuilder.swift
//  MLTerminalSnippets
//

import Foundation

enum SSHCommandBuilderError: LocalizedError, Sendable {
    case missingHost
    case missingUsername
    case missingCustomCommand

    nonisolated var errorDescription: String? {
        switch self {
        case .missingHost: "Informe o host."
        case .missingUsername: "Informe o usuário."
        case .missingCustomCommand: "Informe o comando personalizado."
        }
    }
}

enum SSHCommandBuilder: Sendable {
    @MainActor
    static func build(from connection: SSHConnection) throws -> String {
        try build(
            authMode: connection.authMode,
            host: connection.host,
            port: connection.port,
            username: connection.username,
            privateKeyPath: connection.resolvedPrivateKeyPath,
            customCommand: connection.customCommand
        )
    }

    nonisolated static func build(
        authMode: SSHAuthMode,
        host: String,
        port: Int,
        username: String,
        privateKeyPath: String?,
        customCommand: String
    ) throws -> String {
        switch authMode {
        case .customCommand:
            let trimmed = customCommand.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { throw SSHCommandBuilderError.missingCustomCommand }
            return trimmed
        case .standard:
            return try buildStandardSSH(
                host: host,
                port: port,
                username: username,
                privateKeyPath: privateKeyPath
            )
        }
    }

    nonisolated static func buildStandardSSH(
        host: String,
        port: Int,
        username: String,
        privateKeyPath: String?
    ) throws -> String {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedHost.isEmpty else { throw SSHCommandBuilderError.missingHost }
        guard !trimmedUser.isEmpty else { throw SSHCommandBuilderError.missingUsername }

        var parts = ["ssh"]
        if let key = privateKeyPath?.trimmingCharacters(in: .whitespacesAndNewlines), !key.isEmpty {
            parts += ["-i", shellQuote(key)]
        }
        if port != 22 {
            parts += ["-p", String(port)]
        }
        parts.append("\(trimmedUser)@\(trimmedHost)")
        return parts.joined(separator: " ")
    }

    nonisolated static func shellQuote(_ path: String) -> String {
        if path.contains(" ") || path.contains("'") || path.contains("\"") {
            let escaped = path.replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        }
        return path
    }

    @MainActor
    static func preview(from draft: SSHConnectionFormDraft) -> String {
        (try? build(
            authMode: draft.authMode,
            host: draft.host,
            port: draft.port,
            username: draft.username,
            privateKeyPath: draft.resolvedPrivateKeyPath,
            customCommand: draft.customCommand
        )) ?? "—"
    }

    enum CommandTemplate: Sendable {
        case standardSSH
        case sshCopyId
        case addUserExample

        nonisolated func text(
            host: String,
            port: Int,
            username: String,
            privateKeyPath: String?
        ) -> String {
            switch self {
            case .standardSSH:
                return (try? buildStandardSSH(
                    host: host,
                    port: port,
                    username: username,
                    privateKeyPath: privateKeyPath
                )) ?? "ssh user@host"
            case .sshCopyId:
                let keyPart: String
                if let path = privateKeyPath, !path.isEmpty {
                    keyPart = " -i \(shellQuote(path))"
                } else {
                    keyPart = ""
                }
                let portPart = port != 22 ? " -p \(port)" : ""
                return "ssh-copy-id\(keyPart)\(portPart) \(username)@\(host)"
            case .addUserExample:
                let ssh = (try? buildStandardSSH(
                    host: host,
                    port: port,
                    username: username,
                    privateKeyPath: privateKeyPath
                )) ?? "ssh user@host"
                return """
                \(ssh) 'sudo useradd -m -s /bin/bash novo_usuario && sudo passwd novo_usuario'
                """
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
}
