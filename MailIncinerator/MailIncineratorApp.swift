//
//  MailIncineratorApp.swift
//  MailIncinerator
//
//  Created by mlnlsTER on 19.10.2025.
//

import SwiftUI
import Foundation

@main
struct MailCleanerApp: App {
    var body: some Scene {
        WindowGroup {
#if APPSTORE
            let dependencies = ProdDependencies(mode: .appstore)
#else
            let dependencies = ProdDependencies(mode: .public, baseURL: URL(string: CacheConstants.mailPath))
#endif
            ContentView(dependencies: dependencies)
        }
    }
}
