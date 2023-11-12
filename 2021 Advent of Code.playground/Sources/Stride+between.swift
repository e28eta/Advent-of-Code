import Foundation

public func stride<T>(between a: T, and b: T, by strideAmt: T.Stride) -> StrideThrough<T> where T: Strideable {
    // error if stride won't ever reach upper from lower
    let lower = min(a, b)
    let upper = max(a, b)

    return stride(from: lower, through: upper, by: strideAmt)
}

