//
//  SyncStatusView.swift
//  MLTerminalSnippets
//

import SwiftUI

struct SyncStatusView: View {
    let message: String
    var isError: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isError ? "icloud.slash" : "icloud")
                .foregroundStyle(isError ? .red : .secondary)
                .symbolEffect(.pulse, isActive: !isError && message.contains("Sincronizando"))
            Text(message)
                .font(.caption)
                .foregroundStyle(isError ? .red : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Status iCloud: \(message)")
    }
}
