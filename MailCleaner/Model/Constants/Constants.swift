import Foundation

public enum CacheConstants {
    public static let mailPath = NSString(string: "~/Library/Mail").expandingTildeInPath
    public static let fullDiskAccessInstruction = String(localized: "FullDiskAccessInstruction", table: nil)
    public static let chooseFolderInstruction = String(localized: "ChooseFolderInstruction", table: nil)
    public static let githubLink = "https://github.com/mlnlsTER/MailCleaner"
    public static let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
}
