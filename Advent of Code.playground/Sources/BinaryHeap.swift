import Foundation

public class BinaryHeap<Element: Comparable & AnyObject & CustomStringConvertible> {
    typealias CompareElementFunction = (UnsafeRawPointer, UnsafeRawPointer) -> CFComparisonResult

    static func _compare(p1: UnsafeRawPointer, p2: UnsafeRawPointer) -> CFComparisonResult {
//        print("_compare", o1, o2)
        let o1 = Unmanaged<Element>.fromOpaque(p1).takeUnretainedValue()
        let o2 = Unmanaged<Element>.fromOpaque(p2).takeUnretainedValue()

//        print("_compare", o1, o2)
        if o1 == o2 {
            return .compareEqualTo
        } else if o1 < o2 {
            return .compareLessThan
        } else if o1 > o2 {
            return .compareGreaterThan
        } else {
            print("ERROR: NOT totally ordered")
            return p1 < p2 ? .compareLessThan : .compareGreaterThan
        }
    }

    var heap: CFBinaryHeap

    public init() {
        var callbacks = CFBinaryHeapCallBacks(
            version: 0,
            retain: { _, obj in
//                print("retaining", obj as Any)
                guard let obj = obj else { return nil }
                return UnsafeRawPointer(Unmanaged<AnyObject>.fromOpaque(obj).retain().toOpaque())
        },
            release: { _, obj in
//                print("releasing", obj as Any)
                guard let obj = obj else { return }
                Unmanaged<AnyObject>.fromOpaque(obj).release()
        },
            copyDescription: { obj in
//                print("describing", obj as Any)
                guard let obj = obj else { return nil }
                let o = Unmanaged<AnyObject>.fromOpaque(obj).takeUnretainedValue()
                return Unmanaged.passRetained(String(describing: o) as CFString)
        },
            compare: { obj1, obj2, contextPtr in
//                print("compare", obj1 as Any, obj2 as Any)
                guard let obj1 = obj1, let obj2 = obj2, let contextPtr = contextPtr else {
                    fatalError("CFBinaryHeap asked us to compare with a nil parameter")
                }

                let contextCompare = Unmanaged<AnyObject>.fromOpaque(contextPtr).takeUnretainedValue() as! CompareElementFunction
                return contextCompare(obj1, obj2)
        }
        )
        var context = CFBinaryHeapCompareContext(
            version: 0,
            info: Unmanaged.passRetained(BinaryHeap<Element>._compare as AnyObject).toOpaque(),
            retain: {
                UnsafeRawPointer(Unmanaged<AnyObject>.fromOpaque($0!).retain().toOpaque())
        }, release: {
            Unmanaged<AnyObject>.fromOpaque($0!).release()
        }, copyDescription: nil)


        heap = CFBinaryHeapCreate(nil, 0, &callbacks, &context)
    }

    public func push(_ e: Element) {
        let pointer = Unmanaged<Element>.passRetained(e).toOpaque()
//        print("pushing", e, pointer)
        CFBinaryHeapAddValue(heap, pointer)
    }

    public func pop() -> Element? {
        guard let result = CFBinaryHeapGetMinimum(heap) else {
            return nil
        }

        CFBinaryHeapRemoveMinimumValue(heap)

        return Unmanaged<Element>.fromOpaque(result).takeUnretainedValue()
    }

    public func contains(_ e: Element) -> Bool {
        let pointer = Unmanaged<Element>.passRetained(e).toOpaque()
        return CFBinaryHeapContainsValue(heap, pointer)
    }
}

//class Foo: Comparable, CustomStringConvertible {
//    let bar: Int
//
//    init(_ bar: Int) {
//        self.bar = bar
//    }
//
//    static func <(_ lhs: Foo, _ rhs: Foo) -> Bool {
//        let left = lhs.bar / 2, right = rhs.bar / 2
//
//        if left == right {
//            return lhs.bar < rhs.bar
//        } else {
//            return left < right
//        }
//    }
//
//    static func ==(_ lhs: Foo, _ rhs: Foo) -> Bool {
//        return lhs.bar == rhs.bar
//    }
//
//    var description: String {
//        return String(bar)
//    }
//}
//
//let h = BinaryHeap<Foo>()
//let foos = [Foo(1), Foo(2), Foo(4), Foo(5)]
//for foo in foos {
//    h.push(foo)
//}
//
//print("contains 3?", h.contains(Foo(3)))
//h.push(Foo(3))
//print("contains 3 after pushing?", h.contains(Foo(3)))
//
//for _ in 0...5 {
//    print(h.pop() ?? "nil")
//}

