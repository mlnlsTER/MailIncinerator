//
//  MailFolderAccessView.swift
//  MailIncinerator
//
//  Created by Zhdan Baliuk on 17.12.2025.
//

import SwiftUI

struct MailFolderAccessView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Folder Access")
                    .font(.headline)
                Text(CacheConstants.chooseFolderInstruction)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                Button("Back") { dismiss() }
            }
        }
    }
}

#Preview {
    MailFolderAccessView()
}
