import Foundation

public func zip<A: Sequence, B: Sequence, C: Sequence>(_ a: A, _ b: B, _ c: C) -> some Sequence<(A.Element, B.Element, C.Element)> {
    return sequence(state: (a.makeIterator(),
                            b.makeIterator(),
                            c.makeIterator())) { iterators in
        guard let nextA = iterators.0.next(),
              let nextB = iterators.1.next(),
              let nextC = iterators.2.next() else {
            return nil
        }
        return (nextA, nextB, nextC)
    }
}

// thought 5.9 was supposed to make it possible to implement zipn(..)
// this is crashing lldb-rpc-server 🤷‍♂️
// https://forums.swift.org/t/is-there-a-way-to-implement-zipsequence-iterator-s-next-method-from-se-0398/66680/2

//public func zipN<each S: Sequence>(_ sequence: repeat each S) -> some Sequence<(repeat (each S).Element)> {
//    let iter = ZipIterator(repeat (each sequence).makeIterator())
//
//    return sequence(state: iter) { $0.next() }
//}

enum Stop: Error {
    case stop
}

public struct ZipIterator<each T: IteratorProtocol>: IteratorProtocol {
    var iter: (repeat each T)

    public init(_ iter: repeat each T) {
        self.iter = (repeat each iter)
    }

    mutating public func next() -> (repeat (each T).Element)? {
        func step<I: IteratorProtocol>(_ iter: I) throws -> (I, I.Element) {
            var iter2 = iter
            guard let next = iter2.next() else { throw Stop.stop }
            return (iter2, next)
        }

        do {
            let result: (repeat (each T, (each T).Element)) = (repeat try step(each iter))
            iter = (repeat (each result).0)
            return (repeat (each result).1)
        } catch {
            return nil
        }
    }
}

