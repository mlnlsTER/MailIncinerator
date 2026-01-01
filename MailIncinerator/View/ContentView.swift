//
//  ContentView.swift
//  MailIncinerator
//
//  Created by mlnlsTER on 06.11.2025.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm: MailIncineratorViewModel
    @State private var selectedTab = 0
    
    init(dependencies: MailCleanerDependencies) {
        _vm = StateObject(wrappedValue: MailIncineratorViewModel(dependencies: dependencies))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MailIncineratorView(vm: vm)
                .tabItem {
                    VStack {
                        Image(systemName: "wand.and.rays")
                        Text("Mail")
                            .font(.system(size: 10))
                    }
                }
                .tag(0)
            InfoTabView(vm: vm)
                .tabItem {
                    VStack {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Info")
                    }
                }
                .tag(1)
        }
        .onAppear { Task { await vm.checkMailFolderAccess() } }
    }
}


#Preview {
    ContentView(
        dependencies: MockDependencies(
            mode: .public,
            baseURL: nil,
            scanner: MockScanner(),
            deleter: MockDeleter()
        )
    )
}

