//
//  MD5.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 06/08/14.
//  Copyright (c) 2014 Marcin Krzyzanowski. All rights reserved.
//
// And a bunch of other things pulled in from https://github.com/krzyzanowskim/CryptoSwift

import Darwin

internal protocol DigestType {
    func calculate(for bytes: Array<UInt8>) -> Array<UInt8>
}

func rotateLeft(_ value: UInt32, by: UInt32) -> UInt32 {
    return ((value << by) & 0xFFFFFFFF) | (value >> (32 - by))
}


extension Collection where Self.Iterator.Element == UInt8, Self.Index == Int {

    func toUInt32Array() -> Array<UInt32> {
        var result = Array<UInt32>()
        result.reserveCapacity(16)
        for idx in stride(from: self.startIndex, to: self.endIndex, by: MemoryLayout<UInt32>.size) {
            var val: UInt32 = 0
            val |= self.count > 3 ? UInt32(self[idx.advanced(by: 3)]) << 24 : 0
            val |= self.count > 2 ? UInt32(self[idx.advanced(by: 2)]) << 16 : 0
            val |= self.count > 1 ? UInt32(self[idx.advanced(by: 1)]) << 8 : 0
            val |= self.count > 0 ? UInt32(self[idx]) : 0
            result.append(val)
        }

        return result
    }
}

public final class MD5: DigestType {
    static let blockSize: Int = 64
    static let digestLength: Int = 16 // 128 / 8
    fileprivate static let hashInitialValue: Array<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]

    fileprivate var accumulated = Array<UInt8>()
    fileprivate var processedBytesTotalCount: Int = 0
    fileprivate var accumulatedHash: Array<UInt32> = MD5.hashInitialValue

    /** specifies the per-round shift amounts */
    private let s: Array<UInt32> = [7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
                                    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
                                    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
                                    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21]

    /** binary integer part of the sines of integers (Radians) */
    private let k: Array<UInt32> = [0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
                                    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
                                    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
                                    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
                                    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
                                    0xd62f105d, 0x2441453, 0xd8a1e681, 0xe7d3fbc8,
                                    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
                                    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
                                    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
                                    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
                                    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x4881d05,
                                    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
                                    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
                                    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
                                    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
                                    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391]

    public init() {
    }

    public func calculate(for bytes: Array<UInt8>) -> Array<UInt8> {
        do {
            return try self.update(withBytes: bytes, isLast: true)
        } catch {
            fatalError()
        }
    }

    // mutating currentHash in place is way faster than returning new result
    fileprivate func process(block chunk: ArraySlice<UInt8>, currentHash: inout Array<UInt32>) {

        // break chunk into sixteen 32-bit words M[j], 0 ≤ j ≤ 15
        var M = chunk.toUInt32Array()
        assert(M.count == 16, "Invalid array")

        // Initialize hash value for this chunk:
        var A: UInt32 = currentHash[0]
        var B: UInt32 = currentHash[1]
        var C: UInt32 = currentHash[2]
        var D: UInt32 = currentHash[3]

        var dTemp: UInt32 = 0

        // Main loop
        for j in 0 ..< k.count {
            var g = 0
            var F: UInt32 = 0

            switch (j) {
            case 0 ... 15:
                F = (B & C) | ((~B) & D)
                g = j
                break
            case 16 ... 31:
                F = (D & B) | (~D & C)
                g = (5 * j + 1) % 16
                break
            case 32 ... 47:
                F = B ^ C ^ D
                g = (3 * j + 5) % 16
                break
            case 48 ... 63:
                F = C ^ (B | (~D))
                g = (7 * j) % 16
                break
            default:
                break
            }
            dTemp = D
            D = C
            C = B
            B = B &+ rotateLeft(A &+ F &+ k[j] &+ M[g], by: s[j])
            A = dTemp
        }

        currentHash[0] = currentHash[0] &+ A
        currentHash[1] = currentHash[1] &+ B
        currentHash[2] = currentHash[2] &+ C
        currentHash[3] = currentHash[3] &+ D
    }
}

/// A type that supports incremental updates. For example Digest or Cipher may be updatable
/// and calculate result incerementally.
public protocol Updatable {
    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process
    /// - parameter isLast: (Optional) Given chunk is the last one. No more updates after this call.
    /// - returns: Processed data or empty array.
    mutating func update<T: Collection>(withBytes bytes: T, isLast: Bool) throws -> Array<UInt8> where T.Iterator.Element == UInt8

    /// Update given bytes in chunks.
    ///
    /// - parameter bytes: Bytes to process
    /// - parameter isLast: (Optional) Given chunk is the last one. No more updates after this call.
    /// - parameter output: Resulting data
    /// - returns: Processed data or empty array.
    mutating func update<T: Collection>(withBytes bytes: T, isLast: Bool, output: (Array<UInt8>) -> Void) throws where T.Iterator.Element == UInt8

    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - returns: Processed data.
    mutating func finish<T: Collection>(withBytes bytes: T) throws -> Array<UInt8> where T.Iterator.Element == UInt8

    /// Finish updates. This may apply padding.
    /// - parameter bytes: Bytes to process
    /// - parameter output: Resulting data
    /// - returns: Processed data.
    mutating func finish<T: Collection>(withBytes bytes: T, output: (Array<UInt8>) -> Void) throws where T.Iterator.Element == UInt8
}

extension Updatable {

    mutating public func update<T: Collection>(withBytes bytes: T, isLast: Bool = false, output: (Array<UInt8>) -> Void) throws where T.Iterator.Element == UInt8 {
        let processed = try self.update(withBytes: bytes, isLast: isLast)
        if (!processed.isEmpty) {
            output(processed)
        }
    }

    mutating public func finish<T: Collection>(withBytes bytes: T) throws -> Array<UInt8> where T.Iterator.Element == UInt8 {
        return try self.update(withBytes: bytes, isLast: true)
    }

    mutating public func finish() throws -> Array<UInt8> {
        return try self.update(withBytes: [], isLast: true)
    }

    mutating public func finish<T: Collection>(withBytes bytes: T, output: (Array<UInt8>) -> Void) throws where T.Iterator.Element == UInt8 {
        let processed = try self.update(withBytes: bytes, isLast: true)
        if (!processed.isEmpty) {
            output(processed)
        }
    }

    mutating public func finish(output: (Array<UInt8>) -> Void) throws {
        try self.finish(withBytes: [], output: output)
    }
}

struct BytesSequence: Sequence {
    let chunkSize: Array<UInt8>.IndexDistance
    let data: Array<UInt8>

    func makeIterator() -> AnyIterator<ArraySlice<UInt8>> {
        var offset = data.startIndex
        return AnyIterator {
            let end = Swift.min(self.chunkSize, self.data.count &- offset)
            let result = self.data[offset ..< offset &+ end]
            offset = offset.advanced(by: result.count)
            if !result.isEmpty {
                return result
            }
            return nil
        }
    }
}

enum Bit: Int {
    case zero
    case one
}

extension Bit {
    func inverted() -> Bit {
        return self == .zero ? .one : .zero
    }
}

/** Protocol and extensions for integerFrom(bits:). Bit hakish for me, but I can't do it in any other way */
protocol Initiable {
    init(_ v: Int)
    init(_ v: UInt)
}

extension Int: Initiable {}
extension UInt: Initiable {}
extension UInt8: Initiable {}
extension UInt16: Initiable {}
extension UInt32: Initiable {}
extension UInt64: Initiable {}

/** build bit pattern from array of bits */
@_specialize(UInt8)
func integerFrom<T: UnsignedInteger>(_ bits: Array<Bit>) -> T {
    var bitPattern: T = 0
    for idx in bits.indices {
        if bits[idx] == Bit.one {
            let bit = T(UIntMax(1) << UIntMax(idx))
            bitPattern = bitPattern | bit
        }
    }
    return bitPattern
}

/* array of bits */
extension Int {

    init(bits: [Bit]) {
        self.init(bitPattern: integerFrom(bits) as UInt)
    }
}

/// Array of bytes. Caution: don't use directly because generic is slow.
///
/// - parameter value: integer value
/// - parameter length: length of output array. By default size of value type
///
/// - returns: Array of bytes
func arrayOfBytes<T: Integer>(value: T, length totalBytes: Int = MemoryLayout<T>.size) -> Array<UInt8> {
    let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
    valuePointer.pointee = value

    let bytesPointer = UnsafeMutablePointer<UInt8>(OpaquePointer(valuePointer))
    var bytes = Array<UInt8>(repeating: 0, count: totalBytes)
    for j in 0 ..< min(MemoryLayout<T>.size, totalBytes) {
        bytes[totalBytes - 1 - j] = (bytesPointer + j).pointee
    }

    valuePointer.deinitialize()
    valuePointer.deallocate(capacity: 1)

    return bytes
}

/* array of bytes */
extension Int {

    /** Int with collection of bytes (little-endian) */
    // init<T: Collection>(bytes: T) where T.Iterator.Element == UInt8, T.Index == Int {
    //    self = bytes.toInteger()
    // }

    /** Array of bytes with optional padding */
    func bytes(totalBytes: Int = MemoryLayout<Int>.size) -> Array<UInt8> {
        return arrayOfBytes(value: self, length: totalBytes)
    }
}

/**
 ISO/IEC 9797-1 Padding method 2.
 Add a single bit with value 1 to the end of the data.
 If necessary add bits with value 0 to the end of the data until the padded data is a multiple of blockSize.
 - parameters:
 - blockSize: Padding size in bytes.
 - allowance: Excluded trailing number of bytes.
 */
@inline(__always)
func bitPadding(to data: inout Array<UInt8>, blockSize: Int, allowance: Int = 0) {
    let msgLength = data.count
    // Step 1. Append Padding Bits
    // append one bit (UInt8 with one bit) to message
    data.append(0x80)

    // Step 2. append "0" bit until message length in bits ≡ 448 (mod 512)
    let max = blockSize - allowance // 448, 986
    if msgLength % blockSize < max { // 448
        data += Array<UInt8>(repeating: 0, count: max - 1 - (msgLength % blockSize))
    } else {
        data += Array<UInt8>(repeating: 0, count: blockSize + max - 1 - (msgLength % blockSize))
    }
}

extension MD5: Updatable {

    public func update<T: Collection>(withBytes bytes: T, isLast: Bool = false) throws -> Array<UInt8> where T.Iterator.Element == UInt8 {
        self.accumulated += bytes

        if isLast {
            let lengthInBits = (self.processedBytesTotalCount + self.accumulated.count) * 8
            let lengthBytes = lengthInBits.bytes(totalBytes: 64 / 8) // A 64-bit representation of b

            // Step 1. Append padding
            bitPadding(to: &self.accumulated, blockSize: MD5.blockSize, allowance: 64 / 8)

            // Step 2. Append Length a 64-bit representation of lengthInBits
            self.accumulated += lengthBytes.reversed()
        }

        var processedBytes = 0
        for chunk in BytesSequence(chunkSize: MD5.blockSize, data: self.accumulated) {
            if (isLast || (self.accumulated.count - processedBytes) >= MD5.blockSize) {
                self.process(block: chunk, currentHash: &self.accumulatedHash)
                processedBytes += chunk.count
            }
        }
        self.accumulated.removeFirst(processedBytes)
        self.processedBytesTotalCount += processedBytes

        // output current hash
        var result = Array<UInt8>()
        result.reserveCapacity(MD5.digestLength)

        for hElement in self.accumulatedHash {
            let hLE = hElement.littleEndian
            result += [UInt8(hLE & 0xff), UInt8((hLE >> 8) & 0xff), UInt8((hLE >> 16) & 0xff), UInt8((hLE >> 24) & 0xff)]
        }

        // reset hash value for instance
        if isLast {
            self.accumulatedHash = MD5.hashInitialValue
        }

        return result
    }
}


public protocol CSArrayType: Collection, RangeReplaceableCollection {
    func cs_arrayValue() -> [Iterator.Element]
}

extension Array: CSArrayType {

    public func cs_arrayValue() -> [Iterator.Element] {
        return self
    }
}

extension ArraySlice: CSArrayType {
    public func cs_arrayValue() -> [Iterator.Element] {
        return Array(self)
    }
}

public extension CSArrayType where Iterator.Element == UInt8 {

    public func toHexString() -> String {
        return self.lazy.reduce("") {
            var s = String($1, radix: 16)
            if s.characters.count == 1 {
                s = "0" + s
            }
            return $0 + s
        }
    }
}

public extension CSArrayType where Iterator.Element == UInt8 {
    public func md5() -> [Iterator.Element] {
        return MD5().calculate(for: cs_arrayValue())
    }
}

extension String {
    public func md5() -> String {
        return self.utf8.lazy.map({ $0 as UInt8 }).md5().toHexString()
    }
}
