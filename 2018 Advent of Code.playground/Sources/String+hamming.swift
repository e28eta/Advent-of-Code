
public func hammingDistance(_ s1: String, _ s2: String) -> Int {
    assertEqual(s1.count, s2.count)
    return zip(s1, s2).reduce(0) { $0 + ($1.0 == $1.1 ? 0 : 1) }
}
