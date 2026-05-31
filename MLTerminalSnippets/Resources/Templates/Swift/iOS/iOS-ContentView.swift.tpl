//
//  ContentView.swift
//  {{PROJECT_NAME}}
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ContentUnavailableView(
            "{{PROJECT_NAME}}",
            systemImage: "swift",
            description: Text("Substitua esta view pelo fluxo principal do app.")
        )
    }
}

#Preview {
    ContentView()
}
