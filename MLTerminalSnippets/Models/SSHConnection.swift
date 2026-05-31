//
//  SSHConnection.swift
//  MLTerminalSnippets
//

import Foundation
import SwiftData

/// CloudKit: propriedades com valor padrão; sem `@Attribute(.unique)`.
@Model
final class SSHConnection {
    var id: UUID = UUID()
    var name: String = ""
    var host: String = ""
    var port: Int = 22
    var username: String = ""
    var authModeRaw: String = SSHAuthMode.standard.rawValue
    var privateKeyPathDisplay: String = ""
    var privateKeyBookmark: Data?
    var customCommand: String = ""
    var notes: String = ""
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 22,
        username: String,
        authMode: SSHAuthMode = .standard,
        privateKeyPathDisplay: String = "",
        privateKeyBookmark: Data? = nil,
        customCommand: String = "",
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.authModeRaw = authMode.rawValue
        self.privateKeyPathDisplay = privateKeyPathDisplay
        self.privateKeyBookmark = privateKeyBookmark
        self.customCommand = customCommand
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var authMode: SSHAuthMode {
        get { SSHAuthMode(rawValue: authModeRaw) ?? .standard }
        set { authModeRaw = newValue.rawValue }
    }

    func touch() {
        updatedAt = .now
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
}
