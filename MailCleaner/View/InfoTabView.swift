//
//  InfoTabView.swift
//  MailCleaner
//
//  Created by Zhdan Baliuk on 06.11.2025.
//

import SwiftUI

struct InfoTabView: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Instructions for granting full disk access")
                        .font(.headline)
#if PUBLIC
                    Text(CacheConstants.fullDiskAccessInstruction)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .top)
#elseif APPSTORE
                    Text(CacheConstants.chooseFolderInstruction)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .top)
#endif
                }
                .padding()
            }
            
            
            HStack(alignment: .center, spacing: 15) {
                Spacer()
                Button("GitHub", systemImage: "exclamationmark.bubble") {
                    openURLInDefaultBrowser(urlString: CacheConstants.githubLink)
                }
                Spacer()
                Text("Version: \(CacheConstants.appVersion)")
                    .font(.callout)
                Spacer()
            }
            .padding()
        }} 
    
    func openURLInDefaultBrowser(urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {

        }
    }
}

#Preview {
    InfoTabView()
}
