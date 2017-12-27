import Foundation

public func readResourceFile(_ fileName: String) throws -> String {
    guard let path = Bundle.main.url(forResource: fileName, withExtension: nil) else {
        throw NSError(domain: NSCocoaErrorDomain,
                      code: NSFileNoSuchFileError,
                      userInfo: nil)
    }
    return try String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
}

extension String {
    public func lines() -> [String] { return components(separatedBy: .newlines) }
}
