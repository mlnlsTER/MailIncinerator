import SwiftUI

struct FullDiskAccessHelpView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Full disk access required")
                    .font(.headline)
                Text(CacheConstants.fullDiskAccessInstruction)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .top)
                Button("Open settings") {
                    openFullDiskAccessPanel()
                }
            }
            .padding()
        }
    }

    private func openFullDiskAccessPanel() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    FullDiskAccessHelpView()
}
