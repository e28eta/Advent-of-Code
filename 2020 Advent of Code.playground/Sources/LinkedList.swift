import Foundation

public final class LinkedList<Element> {

    fileprivate class Node {
        /// element stored in the list at this node
        let value: Element
        /// next node in the list, or nil
        var next: Node? = nil
        /// previous node in the list, or nil
        ///
        /// weak reference to avoid retain cycles
        weak var previous: Node? = nil

        init(_ value: Element) {
            self.value = value
        }
    }

    /// First element of the list. nil if empty
    private var head: Node? = nil
    /// Last element of the list. nil if empty
    private var tail: Node? = nil
    /// O(1) access to number of elements in the list
    private var storedCount: Int = 0

    public init() { }

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        // custom implementation because used by replaceSubrange(:with:)
        let nodes = elements.map(Node.init)

        for (l, r) in zip(nodes, nodes.dropFirst()) {
            l.next = r
            r.previous = l
        }

        head = nodes.first
        tail = nodes.last
        storedCount = nodes.count
    }

    // need to implement `count` separately from default implementation to avoid infinite loop in endIndex creation
    public var count: Int {
        return storedCount
    }
}

extension LinkedList: CustomStringConvertible where Element: CustomStringConvertible {
    public var description: String {
        return "[" + map(\.description).joined(separator: ", ") + "]"
    }
}

extension LinkedList: Collection {
    /// Index into the LinkedList. Indices are invalid after collection mutation
    public struct Index {
        public typealias Stride = Int

        /// reference to the Node in the LinkedList, direct access to value, next & previous. Nil if this is endIndex
        fileprivate let node: Node?
        /// integer index into the list, in the range [0, count). Invalid as soon as collection is mutated
        fileprivate let tag: Int // used for Comparable and Strideable

        /// helper for Index after the current one
        fileprivate func next() -> Self {
            precondition(node != nil, "cannot get index(after: endIndex)")

            return Index(node: node!.next, tag: tag + 1)
        }

        // can't implement previous() because endIndex can't get to tail of list

        /// simple check if this is the startIndex of the LinkedList
        fileprivate var isStartIndex: Bool { return tag == 0 }
        /// simple check if this is the endIndex of the LinkedList
        fileprivate var isEndIndex: Bool { return node == nil }
    }

    public var startIndex: Index {
        // if empty LinkedList, this will be the same as endIndex
        return Index(node: head, tag: 0)
    }

    public var endIndex: Index {
        return Index(node: nil, tag: count)
    }

    public func index(after i: Index) -> Index {
        return i.next()
    }

    public subscript(position: Index) -> Element {
        return position.node!.value
    }
}

extension LinkedList.Index: Comparable {
    public static func < (lhs: LinkedList<Element>.Index, rhs: LinkedList<Element>.Index) -> Bool {
        return lhs.tag < rhs.tag
    }

    public static func == (lhs: LinkedList<Element>.Index, rhs: LinkedList<Element>.Index) -> Bool {
        return lhs.tag == rhs.tag
    }
}

extension LinkedList.Index: Strideable {
    public func advanced(by n: Stride) -> LinkedList<Element>.Index {
        precondition(n >= 0, "cannot stride backwards") // fixable if Index can go from endIndex to tail

        var i = self
        for _ in (0 ..< n) {
            i = i.next()
        }
        return i
    }

    public func distance(to other: LinkedList<Element>.Index) -> Int {
        return other.tag - tag
    }
}

extension LinkedList: BidirectionalCollection {
    public func index(before i: Index) -> Index {
        precondition(i.tag > 0, "cannot get index(before: startIndex)")

        return Index(node: i.node?.previous ?? tail,
                     tag: i.tag - 1)
    }
}

extension LinkedList: RangeReplaceableCollection {
    public func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, Element == C.Element {
        // find nodes in this collection to be updated
        let beforeSubrange = subrange.startIndex.isStartIndex ? nil : index(before: subrange.startIndex).node
        let afterSubrange = subrange.endIndex.isEndIndex ? nil : subrange.endIndex.node

        if newElements.isEmpty {
            // no new elements, just delete nodes in the sub range
            switch (beforeSubrange, afterSubrange) {
            case (nil, nil):
                // replace entire range with nothing
                head = nil
                tail = nil
            case let (nil, afterSubrange?):
                // delete up until afterSubrange
                head = afterSubrange
                afterSubrange.previous = nil
            case let (beforeSubrange?, nil):
                // delete everything after beforeSubrange
                tail = beforeSubrange
                beforeSubrange.next = nil
            case let (beforeSubrange?, afterSubrange?):
                // snip out everything between before/after
                beforeSubrange.next = afterSubrange
                afterSubrange.previous = beforeSubrange
            }
        } else {
            // use constructor to create Nodes and link them, and then just
            // need to update head.previous and tail.next
            let newNodes = LinkedList(newElements)

            if let beforeSubrange {
                // something before the new elements
                beforeSubrange.next = newNodes.head
                newNodes.head?.previous = beforeSubrange
            } else {
                // new elements are at the beginning
                head = newNodes.head
            }

            if let afterSubrange {
                // something after the new elements
                newNodes.tail?.next = afterSubrange
                afterSubrange.previous = newNodes.tail
            } else {
                // new elements are at the end
                tail = newNodes.tail
            }
        }

        storedCount = storedCount - subrange.count + newElements.count
    }
}

