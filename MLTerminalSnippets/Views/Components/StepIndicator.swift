//
//  StepIndicator.swift
//  MLTerminalSnippets
//

import SwiftUI

struct StepIndicator: View {
    let currentStep: Int
    let stepCount: Int
    let stepTitle: (Int) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<stepCount, id: \.self) { step in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(width: 24, height: 24)
                        Text("\(step + 1)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(step <= currentStep ? .white : .secondary)
                    }
                    Text(stepTitle(step))
                        .font(.caption)
                        .foregroundStyle(step == currentStep ? .primary : .secondary)
                        .lineLimit(1)
                }
                if step < stepCount - 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 4)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Etapa \(currentStep + 1) de \(stepCount): \(stepTitle(currentStep))")
    }
}
