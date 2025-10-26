import SwiftUI

struct ContentView: View {

    @State private var isTrash: Bool = true
    @StateObject var vm = MailCleanerViewModel()
    
    var body: some View {
        if vm.fullDiskAccessRequired {
            FullDiskAccessHelpView()
        } else {
            VStack {
                if vm.isScanning {
                    ProgressView(value: vm.progress) {
                        Text("Scanning cache...")
                    }
                    .padding()
                } else {
                    Text("Cache: \(ByteCountFormatter.string(fromByteCount: vm.totalSize, countStyle: .file))")
                        .font(.headline)
                        .foregroundStyle(Color(.systemGray))
                }

                Toggle(" Delete permanently", isOn: $isTrash)

                Button("Rescan") { Task { await vm.scan() } }
                    .disabled(vm.isScanning)
                    .padding(.top, 20)
                Button("Clear") { Task { await vm.clear(deletePermanently: isTrash) } }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
