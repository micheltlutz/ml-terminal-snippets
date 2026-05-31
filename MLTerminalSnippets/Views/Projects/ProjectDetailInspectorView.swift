//
//  ProjectDetailInspectorView.swift
//  MLTerminalSnippets
//

import SwiftData
import SwiftUI

struct ProjectDetailInspectorView: View {
    @Bindable var appState: AppState
    let project: SnippetProject?

    var body: some View {
        Group {
            if let project {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(project.name)
                            .font(.title2.weight(.semibold))

                        LabeledContent("IDE", value: project.ideTool.displayName)
                        LabeledContent("Tipo", value: project.swiftProjectKind.displayName)
                        LabeledContent("Criado", value: project.createdAt.formatted())
                        if !project.outputPathDisplay.isEmpty {
                            LabeledContent("Pasta") {
                                Text(project.outputPathDisplay)
                                    .font(.caption.monospaced())
                                    .textSelection(.enabled)
                            }
                        }

                        if let skills = project.selectedSkills, !skills.isEmpty {
                            Text("Skills")
                                .font(.headline)
                            FlowLayout(spacing: 8) {
                                ForEach(skills, id: \.id) { skill in
                                    Text(skill.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.quaternary, in: Capsule())
                                }
                            }
                        }

                        if !project.contextMarkdown.isEmpty {
                            Text("Contexto")
                                .font(.headline)
                            Text(project.contextMarkdown)
                                .font(.body)
                                .textSelection(.enabled)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                        }

                        HStack {
                            Button("Abrir no Finder") { openFinder(project) }
                            Button("Abrir no Cursor") { openCursor(project) }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                EmptyStateView(
                    systemImage: "doc.text",
                    title: "Selecione um projeto",
                    message: "Escolha um projeto na lista ou crie um novo.",
                    actionTitle: "Novo projeto",
                    action: { appState.startNewProject() }
                )
            }
        }
        .navigationTitle(project?.name ?? "Projeto")
    }

    private func openFinder(_ project: SnippetProject) {
        guard let bookmark = project.outputPathBookmark,
              let url = BookmarkStore.resolveURL(from: bookmark)
        else { return }
        WorkspaceOpener.openInFinder(url)
    }

    private func openCursor(_ project: SnippetProject) {
        guard let bookmark = project.outputPathBookmark,
              let url = BookmarkStore.resolveURL(from: bookmark)
        else { return }
        WorkspaceOpener.openInCursor(url)
    }
}

/// Simple flow layout for skill tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
