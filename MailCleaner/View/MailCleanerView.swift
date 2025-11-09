//
//  MailCleanerView.swift
//  MailCleaner
//
//  Created by Zhdan Baliuk on 06.11.2025.
//

import SwiftUI

@MainActor
struct MailCleanerView: View {
    
    @State private var showDeleteAlert: Bool = false
    @State private var deletePermanently: Bool = false
    @StateObject var vm = MailCleanerViewModel()
    
    var body: some View {
        if vm.fullDiskAccessRequired {
            FullDiskAccessHelpView()
        } else {
            VStack {
                if vm.isScanning {
                    ProgressView() {
                        Text("Scanning cache...")
                    }
                    .padding()
                } else {
                    Text("Caches: \(ByteCountFormatter.string(fromByteCount: vm.totalSize, countStyle: .file))")
                        .font(.headline)
                        .foregroundStyle(Color(.systemGray))
                }

                Button("Scan") { Task { await vm.scan() } }
                    .disabled(vm.isScanning)
                Toggle(" Delete permanently", isOn: $deletePermanently)
                    .onChange(of: deletePermanently) { newValue in
                        if newValue {
                            showDeleteAlert = true
                        }
                    }
                    .alert("Delete permanently", isPresented: $showDeleteAlert, actions: {
                        Button("Cancel", role: .cancel) { deletePermanently = false }
                        Button("OK", role: .destructive) { }
                    }, message: { Text("You are about to permanently delete the mail cache. This action cannot be undone.")
                    })
                    .disabled(vm.isScanning)
                    .padding(.top, 20)
                Button("Clear") { Task { await vm.clear(deletePermanently: deletePermanently) } }
                    .disabled(vm.emptyCache || vm.isScanning)
            }
            .padding()
        }
    }
}

#Preview {
    MailCleanerView()
}
