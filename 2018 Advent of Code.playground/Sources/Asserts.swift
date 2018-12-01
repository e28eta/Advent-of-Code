import Foundation

public func assertEqual<T>(_ expression1: @autoclosure () throws -> T?,
                           _ expression2: @autoclosure () throws -> T?,
                           _ message: @autoclosure () -> String = "",
                           file: StaticString = #file,
                           line: UInt = #line) -> Bool where T: Equatable {
    do {
        let (value1, value2) = (try expression1(), try expression2())

        if value1 != value2 {
            print("assertEqual failed: \(value1 as T?) != \(value2 as T?)")
            // Can't use assertionFailure, those are elided in the playground
            preconditionFailure(message,
                file: file,
                line: line)
            return false
        }
        return true
    } catch {
        print("assertEqual failed: Error thrown while calculating expression \(error)")
        preconditionFailure("Error thrown while calculating expression \(error)",
            file: file,
            line: line)
        return false
    }
}

public func verify<T, U>(_ testData: [(T, U)], _ closure: (T) -> U) -> Bool where U: Equatable {
    var succeeded = true
    for (input, expected) in testData {
        let actual = closure(input)
        print(".", terminator: "")
        succeeded = succeeded && assertEqual(actual, expected)
    }
    print()
    return succeeded
}
