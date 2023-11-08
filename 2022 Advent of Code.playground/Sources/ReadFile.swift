import Foundation

public func readResourceFile(_ fileName: String, trimming trimCharSet: CharacterSet? = .whitespacesAndNewlines) throws -> String {
    guard let path = Bundle.main.url(forResource: fileName, withExtension: nil) else {
        throw NSError(domain: NSCocoaErrorDomain,
                      code: NSFileNoSuchFileError,
                      userInfo: nil)
    }
    let result = try String(contentsOf: path, encoding: .utf8)

    if let trimCharSet {
        return result.trimmingCharacters(in: trimCharSet)
    } else {
        return result
    }
}

