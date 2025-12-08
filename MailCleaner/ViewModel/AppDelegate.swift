// Режимы работы

import Foundation

#if APPSTORE
let dependencies = ProdDependencies(mode: .appstore)
#else
let dependencies = ProdDependencies(mode: .public, baseURL: URL(string: CacheConstants.mailPath))
#endif

let viewModel = MailCleanerViewModel(dependencies: dependencies)
