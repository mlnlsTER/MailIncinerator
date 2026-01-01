import Foundation

public enum CacheConstants {
    public static let mailPath = NSString(string: "~/Library/Mail").expandingTildeInPath
    public static let githubLink = "https://github.com/mlnlsTER/MailCleaner"
    public static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    
    public static let fullDiskAccessInstruction = String(localized: "fullDiskAccessInstruction", table: nil)
    public static let chooseFolderInstruction = String(localized: "chooseFolderInstruction", table: nil)
    public static let mailRunning = String(localized: "mailIsRunning", table: nil)
    public static let mailRunningBlockingMessage = String(localized: "mailRunningBlockingMessage", table: nil)
    
    public static let mailBundleIdentifier = "com.apple.mail"
}
