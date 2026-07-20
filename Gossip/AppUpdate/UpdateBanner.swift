//
//  UpdateBanner.swift
//  Gossip
//
//

import SwiftUI

struct UpdateBanner: View {
    let onDismiss: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(.pink)

            VStack(alignment: .leading, spacing: 2) {
                Text("Uus versioon on saadaval")
                    .font(.subheadline.weight(.semibold))
                Text("Uuenda rakendust App Stores.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button("Uuenda") {
                openURL(Constants.appStoreURL)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.pink)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Peida")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

#Preview {
    VStack {
        UpdateBanner(onDismiss: {})
        Spacer()
    }
}
