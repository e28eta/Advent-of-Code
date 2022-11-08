//: [Previous](@previous)

import Foundation

var l = LinkedList([1, 2, 3])

print(l)

for v in l {
    print(v)
}

l.removeFirst()
l.append(contentsOf: [-1, -2, -3])
l.insert(22, at: l.startIndex.advanced(by: 2))

l.replaceSubrange(l.startIndex ..< l.startIndex.advanced(by: 1), with: [1])
l.replaceSubrange(l.startIndex ..< l.startIndex.advanced(by: 1), with: [0, 1])

print(l)

l.removeLast(2)
print(l)

l.insert(4, at: l.endIndex)
print(l)

l.removeAll { $0 % 2 != 0 }
print(l)

let x = l.popLast()!
l.insert(x, at: l.startIndex)
print(l)

l.removeSubrange(l.startIndex ..< l.startIndex)

print(l)

l.removeSubrange(l.startIndex ..< l.startIndex.advanced(by: 1))
print(l)

//: [Next](@next)
