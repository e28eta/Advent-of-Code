import Foundation


extension Sequence {
    /**
     Iterate the sequence, returning items two at a time. If there's an odd element at the end, it is
     dropped
     */
    public func pairs() -> some Sequence<(Element, Element)> {
        sequence(state: makeIterator()) { iterator in
            guard let left = iterator.next(),
                  let right = iterator.next() else {
                return nil
            }
            return (left, right)
        }
    }
}
