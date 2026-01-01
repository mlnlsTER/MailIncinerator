//
//  MailIncineratorView.swift
//  MailIncinerator
//
//  Created by mlnlsTER on 06.11.2025.
//

import SwiftUI
import AppKit

@MainActor
struct MailIncineratorView: View {
    
    @State private var showDeleteAlert: Bool = false
    @State private var deletePermanently: Bool = false
    @StateObject var vm: MailIncineratorViewModel
    
    var body: some View {
        if vm.fullDiskAccessRequired {
            switch vm.dependencies.mode {
            case .public:
                FullDiskAccessHelpView()
            case .appstore:
                MailFolderAccessView()
            }

        } else {
            VStack {
                Button("Scan") { Task { await vm.scan() } }
                    .disabled(vm.isProcessing)
                
                if vm.isProcessing {
                    ProgressView() {
                        Text("Scanning cache...")
                    }
                    .padding()
                } else if !vm.cacheFolders.isEmpty {
                    List(vm.cacheFolders, id: \.url) { item in
                        HStack {
                            HStack(alignment: .center) {
                                Text(item.url.lastPathComponent)
                                    .font(.headline)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Show in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([item.url])
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxHeight: 250)
                }
                
                Group {
                    if let result = vm.lastOperationResult {
                        switch result {
                        case .success(let summary):
                            Text(summary)
                                .font(.headline)
                                .foregroundStyle(.green)
                                .opacity(0.7)
                        case .empty:
                            Text("Nothing to clean")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        case .failure(let message):
                            Text(message)
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                    }
                }.padding()
                
                Toggle("Delete permanently", isOn: $deletePermanently)
                    .onChange(of: deletePermanently) { _, newValue in
                        if newValue {
                            showDeleteAlert = true
                        }
                    }
                    .alert("Delete permanently", isPresented: $showDeleteAlert, actions: {
                        Button("Cancel", role: .cancel) { deletePermanently = false }
                        Button("OK", role: .destructive) { }
                    }, message: { Text("You are about to permanently delete the mail cache. This action cannot be undone.")
                        Text("Caches: \(ByteCountFormatter.string(fromByteCount: vm.totalSize, countStyle: .file))")
                    })
                    .disabled(vm.isProcessing)
                    .padding(.top, 20)
                Button("Clear") { Task { await vm.clear(deletePermanently: deletePermanently) } }
                    .disabled(vm.emptyCache || vm.isProcessing)
            }
            .padding()
        }
    }
}

#Preview {
    MailIncineratorView(
        vm: MailIncineratorViewModel(
            dependencies: MockDependencies(
                mode: .public,
                baseURL: nil,
                scanner: MockScanner(),
                deleter: MockDeleter()
            )
        )
    )
}
