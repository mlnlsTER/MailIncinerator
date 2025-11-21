// Например, в AppDelegate.swift или ContentView.swift

#if APPSTORE
let dependencies = ProdDependencies(mode: .appStore)
#else
let dependencies = ProdDependencies(mode: .public)
#endif

let viewModel = MailCleanerViewModel(dependencies: dependencies)
