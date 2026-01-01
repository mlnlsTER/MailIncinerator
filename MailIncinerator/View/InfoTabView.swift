//
//  InfoTabView.swift
//  MailIncinerator
//
//  Created by mlnlsTER on 06.11.2025.
//

import SwiftUI

struct InfoTabView: View {
    @ObservedObject var vm: MailIncineratorViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Instructions for granting full disk access")
                        .font(.headline)
                    switch vm.dependencies.mode {
                    case .public:
                    Text(CacheConstants.fullDiskAccessInstruction)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .top)
                    case .appstore:
                    Text(CacheConstants.chooseFolderInstruction)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .top)
}
                    HStack(spacing: 8) {
                        if vm.fullDiskAccessRequired {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("No access to the Mail folder")
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Access to the Mail folder has been granted.")
                                .foregroundColor(.green)
                        }
                    }
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
    InfoTabView(vm: MailIncineratorViewModel(
            dependencies: MockDependencies(
                mode: .public,
                baseURL: nil,
                scanner: MockScanner(),
                deleter: MockDeleter()
            )
        )
    )
}
