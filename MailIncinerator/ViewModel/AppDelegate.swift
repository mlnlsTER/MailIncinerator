//
//  AppDelegate.swift
//  MailCleaner
//
//  Created by mlnlsTER on 06.11.2025.
//

import Foundation

#if APPSTORE
let dependencies = ProdDependencies(mode: .appstore)
#else
let dependencies = ProdDependencies(mode: .public, baseURL: URL(string: CacheConstants.mailPath))
#endif

let viewModel = MailCleanerViewModel(dependencies: dependencies)
