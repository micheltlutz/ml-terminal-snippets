//
//  SSHConnectionFormDraft.swift
//  MLTerminalSnippets
//

import Foundation

struct SSHConnectionFormDraft: Equatable {
    var name: String = ""
    var host: String = ""
    var port: Int = 22
    var username: String = ""
    var authMode: SSHAuthMode = .standard
    var privateKeyPathDisplay: String = ""
    var privateKeyBookmark: Data?
    var customCommand: String = ""
    var notes: String = ""

    init() {}

    init(from connection: SSHConnection) {
        name = connection.name
        host = connection.host
        port = connection.port
        username = connection.username
        authMode = connection.authMode
        privateKeyPathDisplay = connection.privateKeyPathDisplay
        privateKeyBookmark = connection.privateKeyBookmark
        customCommand = connection.customCommand
        notes = connection.notes
    }

    var resolvedPrivateKeyPath: String? {
        if let bookmark = privateKeyBookmark,
           let url = BookmarkStore.resolveURL(from: bookmark) {
            return url.path
        }
        let trimmed = privateKeyPathDisplay.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if FileManager.default.fileExists(atPath: trimmed) { return trimmed }
        return nil
    }

    var nameError: String? {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nome obrigatório" : nil
    }

    var hostError: String? {
        host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Host obrigatório" : nil
    }

    var usernameError: String? {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Usuário obrigatório" : nil
    }

    var portError: String? {
        (1...65535).contains(port) ? nil : "Porta inválida (1–65535)"
    }

    var customCommandError: String? {
        guard authMode == .customCommand else { return nil }
        return customCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Comando obrigatório no modo personalizado"
            : nil
    }

    var isValid: Bool {
        nameError == nil
            && hostError == nil
            && usernameError == nil
            && portError == nil
            && customCommandError == nil
    }

    var commandPreview: String {
        SSHCommandBuilder.preview(from: self)
    }
}
