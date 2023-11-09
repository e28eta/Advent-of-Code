import Foundation

// https://github.com/apple/swift/blob/main/test/Prototypes/Algorithms.swift

//===--- Algorithms.swift -------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors

//===--- Concatenation ----------------------------------------------------===//
//===----------------------------------------------------------------------===//

// Concatenation improves on a flattened array or other collection by
// allowing random-access traversal if the underlying collections are
// random-access.

/// A concatenation of two sequences with the same element type.
public struct Concatenation<Base1: Sequence, Base2: Sequence>: Sequence
where Base1.Element == Base2.Element
{
    let _base1: Base1
    let _base2: Base2

    init(_base1: Base1, base2: Base2) {
        self._base1 = _base1
        self._base2 = base2
    }

    public struct Iterator: IteratorProtocol {
        var _iterator1: Base1.Iterator
        var _iterator2: Base2.Iterator

        init(_ concatenation: Concatenation) {
            _iterator1 = concatenation._base1.makeIterator()
            _iterator2 = concatenation._base2.makeIterator()
        }

        public mutating func next() -> Base1.Element? {
            return _iterator1.next() ?? _iterator2.next()
        }
    }

    public func makeIterator() -> Iterator {
        Iterator(self)
    }
}

extension Concatenation: Collection where Base1: Collection, Base2: Collection {
    /// A position in a `Concatenation`.
    public struct Index : Comparable {
        internal enum _Representation : Equatable {
            case first(Base1.Index)
            case second(Base2.Index)
        }

        /// Creates a new index into the first underlying collection.
        internal init(first i: Base1.Index) {
            _position = .first(i)
        }

        /// Creates a new index into the second underlying collection.
        internal init(second i: Base2.Index) {
            _position = .second(i)
        }

        internal let _position: _Representation

        public static func < (lhs: Index, rhs: Index) -> Bool {
            switch (lhs._position, rhs._position) {
            case (.first, .second):
                return true
            case (.second, .first):
                return false
            case let (.first(l), .first(r)):
                return l < r
            case let (.second(l), .second(r)):
                return l < r
            }
        }
    }

    public var startIndex: Index {
        // If `_base1` is empty, then `_base2.startIndex` is either a valid position
        // of an element or equal to `_base2.endIndex`.
        return _base1.isEmpty
        ? Index(second: _base2.startIndex)
        : Index(first: _base1.startIndex)
    }

    public var endIndex: Index {
        return Index(second: _base2.endIndex)
    }

    public subscript(i: Index) -> Base1.Element {
        switch i._position {
        case let .first(i):
            return _base1[i]
        case let .second(i):
            return _base2[i]
        }
    }

    public func index(after i: Index) -> Index {
        switch i._position {
        case let .first(i):
            assert(i != _base1.endIndex)
            let next = _base1.index(after: i)
            return next == _base1.endIndex
            ? Index(second: _base2.startIndex)
            : Index(first: next)
        case let .second(i):
            return Index(second: _base2.index(after: i))
        }
    }
}

extension Concatenation : BidirectionalCollection
where Base1: BidirectionalCollection, Base2: BidirectionalCollection
{
    public func index(before i: Index) -> Index {
        assert(i != startIndex, "Can't advance before startIndex")
        switch i._position {
        case let .first(i):
            return Index(first: _base1.index(before: i))
        case let .second(i):
            return i == _base2.startIndex
            ? Index(first: _base1.index(before: _base1.endIndex))
            : Index(second: _base2.index(before: i))
        }
    }
}

extension Concatenation : RandomAccessCollection
where Base1: RandomAccessCollection, Base2: RandomAccessCollection
{
    public func index(_ i: Index, offsetBy n: Int) -> Index {
        if n == 0 { return i }
        return n > 0 ? _offsetForward(i, by: n) : _offsetBackward(i, by: -n)
    }

    internal func _offsetForward(
        _ i: Index, by n: Int
    ) -> Index {
        switch i._position {
        case let .first(i):
            let d: Int = _base1.distance(from: i, to: _base1.endIndex)
            if n < d {
                return Index(first: _base1.index(i, offsetBy: n))
            } else {
                return Index(
                    second: _base2.index(_base2.startIndex, offsetBy: n - d))
            }
        case let .second(i):
            return Index(second: _base2.index(i, offsetBy: n))
        }
    }

    internal func _offsetBackward(
        _ i: Index, by n: Int
    ) -> Index {
        switch i._position {
        case let .first(i):
            return Index(first: _base1.index(i, offsetBy: -n))
        case let .second(i):
            let d: Int = _base2.distance(from: _base2.startIndex, to: i)
            if n <= d {
                return Index(second: _base2.index(i, offsetBy: -n))
            } else {
                return Index(
                    first: _base1.index(_base1.endIndex, offsetBy: -(n - d)))
            }
        }
    }
}

/// Returns a new collection that presents a view onto the elements of the
/// first collection and then the elements of the second collection.
func concatenate<S1: Sequence, S2: Sequence>(
    _ first: S1,
    _ second: S2)
-> Concatenation<S1, S2> where S1.Element == S2.Element
{
    return Concatenation(_base1: first, base2: second)
}

extension Sequence {
    func followed<S: Sequence>(by other: S) -> Concatenation<Self, S>
    where Element == S.Element
    {
        return concatenate(self, other)
    }
}


//===--- RotatedCollection ------------------------------------------------===//
//===----------------------------------------------------------------------===//

/// A rotated view onto a collection.
public struct RotatedCollection<Base : Collection> : Collection {
    let _base: Base
    let _indices: Concatenation<Base.Indices, Base.Indices>

    init(_base: Base, shiftingToStart i: Base.Index) {
        self._base = _base
        self._indices = concatenate(_base.indices[i...], _base.indices[..<i])
    }

    /// A position in a rotated collection.
    public struct Index : Comparable {
        internal let _index:
        Concatenation<Base.Indices, Base.Indices>.Index

        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs._index < rhs._index
        }
    }

    public var startIndex: Index {
        return Index(_index: _indices.startIndex)
    }

    public var endIndex: Index {
        return Index(_index: _indices.endIndex)
    }

    public subscript(i: Index) -> Base.SubSequence.Element {
        return _base[_indices[i._index]]
    }

    public func index(after i: Index) -> Index {
        return Index(_index: _indices.index(after: i._index))
    }

    public func index(_ i: Index, offsetBy n: Int) -> Index {
        return Index(_index: _indices.index(i._index, offsetBy: n))
    }

    public func distance(from start: Index, to end: Index) -> Int {
        return _indices.distance(from: start._index, to: end._index)
    }

    /// The shifted position of the base collection's `startIndex`.
    public var shiftedStartIndex: Index {
        return Index(
            _index: Concatenation<Base.Indices, Base.Indices>.Index(
                second: _indices._base2.startIndex)
        )
    }

    public func rotated(shiftingToStart i: Index) -> RotatedCollection<Base> {
        return RotatedCollection(_base: _base, shiftingToStart: _indices[i._index])
    }
}

extension RotatedCollection : BidirectionalCollection
where Base : BidirectionalCollection {
    public func index(before i: Index) -> Index {
        return Index(_index: _indices.index(before: i._index))
    }
}

extension RotatedCollection : RandomAccessCollection
where Base : RandomAccessCollection {}

extension Collection {
    /// Returns a view of this collection with the elements reordered such the
    /// element at the given position ends up first.
    ///
    /// The subsequence of the collection up to `i` is shifted to after the
    /// subsequence starting at `i`. The order of the elements within each
    /// partition is otherwise unchanged.
    ///
    ///     let a = [10, 20, 30, 40, 50, 60, 70]
    ///     let r = a.rotated(shiftingToStart: 3)
    ///     // r.elementsEqual([40, 50, 60, 70, 10, 20, 30])
    ///
    /// - Parameter i: The position in the collection that should be first in the
    ///   result. `i` must be a valid index of the collection.
    /// - Returns: A rotated view on the elements of this collection, such that
    ///   the element at `i` is first.
    public func rotated(shiftingToStart i: Index) -> RotatedCollection<Self> {
        return RotatedCollection(_base: self, shiftingToStart: i)
    }
}
