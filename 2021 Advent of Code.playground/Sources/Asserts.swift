import Foundation

@discardableResult
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
            preconditionFailure(message(),
                file: file,
                line: line)
        }
        return true
    } catch {
        print("assertEqual failed: Error thrown while calculating expression \(error)")
        preconditionFailure("Error thrown while calculating expression \(error)",
            file: file,
            line: line)
    }
}

public func verify<T, U>(_ testData: some Sequence<(T, U)>,
                         measure: Bool = false,
                         _ closure: (T) -> U) -> Bool where U: Equatable {
    let clock = ContinuousClock()
    var succeeded = true
    for (input, expected) in testData {
        let elapsed = clock.measure {
            let actual = closure(input)
            print(".", terminator: "")
            succeeded = succeeded && assertEqual(actual, expected)
        }
        if measure {
            print(" in \(elapsed)")
        }
    }
    print()
    return succeeded
}
