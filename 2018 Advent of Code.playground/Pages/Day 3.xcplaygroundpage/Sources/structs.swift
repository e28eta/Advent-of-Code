public struct Point: CustomStringConvertible { 
    public var x: Int, y: Int
    
    public init(x: Int, y: Int) { self.x = x; self.y = y }
    public init(_ s: String) {
        let components = s.split(separator: ",")
        x = Int(components[0])!
        y = Int(components[1])!
    }
    public var description: String { return "\(x), \(y)" }
}

public struct Size: CustomStringConvertible {
    public let width: Int, height: Int
    public init(width: Int, height: Int) { self.width = width; self.height = height }
    public init(_ s: String) {
        let components = s.split(separator: "x")
        width = Int(components[0])!
        height = Int(components[1])!
    }
    public var description: String { return "\(width) x \(height)" }
}

public struct Claim {
    public let id: String
    public let origin: Point
    public let size: Size
    
    public init(_ s: String) {
        var s = s.replacingOccurrences(of: "#", with: "")
        var components = s.components(separatedBy: " @ ")
        id = components[0]
        components = components[1].components(separatedBy: ": ")
        origin = Point(components[0])
        size = Size(components[1])
    }
}

public struct Fabric { 
    var area: [[Int]]
    
    public init(_ size: Size) {
        let column = Array(repeating: 0, count: size.height)
        area = Array(repeating: column, count: size.width)
    }
    
    public subscript(x: Int, y: Int) -> Int {
        get {
            return area[x][y]
        }
        set(newValue) {
            area[x][y] = newValue
        }
    }
    
    public mutating func add(claims: [Claim]) {
        for claim in claims {
            self.add(claim: claim)
        }
    }
    
    public mutating func add(claim: Claim) {
        for x in (claim.origin.x ..< claim.origin.x + claim.size.width) {
            for y in (claim.origin.y ..< claim.origin.y + claim.size.height) {
                self[x, y] += 1
            }
        }
    }
    
    public var contendedFabric: Int {
        return area.reduce(0) { result, column in
            column.reduce(result) { r, v in
                r + (v > 1 ? 1 : 0)
            }
        }
    }
}
