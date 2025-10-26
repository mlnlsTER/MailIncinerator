public struct MailCacheScanner: CacheScannerProtocol {
    public enum Error: Swift.Error, Equatable {
        case baseNotFound
        case invalidCandidate(URL)

        public static func == (lhs: Error, rhs: Error) -> Bool {
            switch (lhs, rhs) {
            case (.baseNotFound, .baseNotFound): return true
            case (.invalidCandidate(let l), .invalidCandidate(let r)): return l == r
            default: return false
            }
        }
    }
    // ... остальной код ...
}
