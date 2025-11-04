import SwiftUI

struct FullDiskAccessHelpView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Full disk access required")
                    .font(.headline)
                Text("""
                    To work with Mail, you need “Full Disk Access” permission.

                    1. Open “System Preferences” > “Privacy & Security” > “Full Disk Access.”
                    2. Add this app to the list.
                    3. Restart the app.
                    """)
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
