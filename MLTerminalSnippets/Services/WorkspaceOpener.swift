//
//  WorkspaceOpener.swift
//  MLTerminalSnippets
//

import AppKit
import Foundation

enum WorkspaceOpener {
    static func openInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    static func openInCursor(_ url: URL) {
        let cursorPaths = [
            "/Applications/Cursor.app",
            NSHomeDirectory() + "/Applications/Cursor.app",
        ]
        for path in cursorPaths {
            let appURL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.open(
                    [url],
                    withApplicationAt: appURL,
                    configuration: NSWorkspace.OpenConfiguration()
                )
                return
            }
        }
        NSWorkspace.shared.open(url)
    }
}
