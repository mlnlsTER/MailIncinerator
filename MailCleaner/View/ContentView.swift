import SwiftUI

struct ContentView: View {

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
                Toggle(" Delete permanently", isOn: $deletePermanently)

                    .disabled(vm.isScanning)
                    .padding(.top, 20)
                Button("Clear") { Task { await vm.clear(deletePermanently: deletePermanently) } }
                    .disabled(vm.emptyCache)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
    //FullDiskAccessHelpView()
}
