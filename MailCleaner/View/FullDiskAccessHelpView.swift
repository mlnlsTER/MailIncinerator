import SwiftUI

struct FullDiskAccessHelpView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Требуется доступ к полному диску")
                .font(.headline)
            Text("""
                Для работы с почтой требуется разрешение “Полный доступ к диску”.

                1. Откройте “Системные настройки” > “Конфиденциальность и безопасность” > “Полный доступ к диску”.
                2. Добавьте это приложение в список.
                3. Перезапустите приложение.
                """)
            Button("Открыть настройки") {
                openFullDiskAccessPane()
            }
        }
        .padding()
    }

    private func openFullDiskAccessPane() {
        // Откроет настройки macOS с нужной вкладкой
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}
