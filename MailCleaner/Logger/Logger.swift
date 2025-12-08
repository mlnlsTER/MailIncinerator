//
//  Logger.swift
//  MailCleaner
//
//  Created by Zhdan Baliuk on 15.11.2025.
//

import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "MailCleaner"
    
    static let scanner = Logger(subsystem: subsystem, category: "scanner")
    static let deleter = Logger(subsystem: subsystem, category: "deleter")
    static let access = Logger(subsystem: subsystem, category: "access")
}
