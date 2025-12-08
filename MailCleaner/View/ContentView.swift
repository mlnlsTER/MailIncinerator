import SwiftUI

struct ContentView: View {
    
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MailCleanerView()
                .tabItem {
                    VStack {
                        Image(systemName: "wand.and.rays")
                        Text("Mail")
                            .font(.system(size: 10))
                    }
                }
                .tag(0)
            InfoTabView()
                .tabItem {
                    VStack {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Info")
                    }
                }
                .tag(1)
        }
    }
}

#Preview {
    ContentView()
}
