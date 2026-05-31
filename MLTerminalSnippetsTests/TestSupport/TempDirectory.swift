//
//  TempDirectory.swift
//  MLTerminalSnippetsTests
//

import Foundation

/// Diretório temporário removido automaticamente ao sair de escopo.
final class TempDirectory: @unchecked Sendable {
    let url: URL

    init(prefix: String = "mlts-test") throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
