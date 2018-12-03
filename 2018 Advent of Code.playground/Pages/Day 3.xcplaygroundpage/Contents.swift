/**
 Day 3: No Matter How You Slice It
 
 The Elves managed to locate the chimney-squeeze prototype fabric for Santa's suit (thanks to someone who helpfully wrote its box IDs on the wall of the warehouse in the middle of the night). Unfortunately, anomalies are still affecting them - nobody can even agree on how to cut the fabric.
 
 The whole piece of fabric they're working on is a very large square - at least 1000 inches on each side.
 
 Each Elf has made a claim about which area of fabric would be ideal for Santa's suit. All claims have an ID and consist of a single rectangle with edges parallel to the edges of the fabric. Each claim's rectangle is defined as follows:
 
 The number of inches between the left edge of the fabric and the left edge of the rectangle.
 The number of inches between the top edge of the fabric and the top edge of the rectangle.
 The width of the rectangle in inches.
 The height of the rectangle in inches.
 A claim like #123 @ 3,2: 5x4 means that claim ID 123 specifies a rectangle 3 inches from the left edge, 2 inches from the top edge, 5 inches wide, and 4 inches tall. Visually, it claims the square inches of fabric represented by # (and ignores the square inches of fabric represented by .) in the diagram below:
 
 ...........
 ...........
 ...#####...
 ...#####...
 ...#####...
 ...#####...
 ...........
 ...........
 ...........
 The problem is that many of the claims overlap, causing two or more claims to cover part of the same areas. For example, consider the following claims:
 
 #1 @ 1,3: 4x4
 #2 @ 3,1: 4x4
 #3 @ 5,5: 2x2
 Visually, these claim the following areas:
 
 ........
 ...2222.
 ...2222.
 .11XX22.
 .11XX22.
 .111133.
 .111133.
 ........
 The four square inches marked with X are claimed by both 1 and 2. (Claim 3, while adjacent to the others, does not overlap either of them.)
 
 If the Elves all proceed with their own plans, none of them will have enough fabric. How many square inches of fabric are within two or more claims?
 */

let testData = [
    ("#1 @ 1,3: 4x4\n#2 @ 3,1: 4x4\n#3 @ 5,5: 2x2".lines().map(Claim.init), 4),
]
let input = try readResourceFile("input.txt").lines().map(Claim.init)

func contendedArea(_ claims: [Claim]) -> (min: Point, max: Point) {
    var minPoint = Point(x: Int.max, y: Int.max)
    var maxPoint = Point(x: Int.min, y: Int.min)
    var contendedMin = minPoint, contendedMax = maxPoint
    
    for claim in claims {
        if claim.origin.x < minPoint.x {
            contendedMin.x = minPoint.x
            minPoint.x = claim.origin.x
        } else if claim.origin.x < contendedMin.x {
            contendedMin.x = claim.origin.x
        }
        if claim.origin.y < minPoint.y {
            contendedMin.y = minPoint.y
            minPoint.y = claim.origin.y
        } else if claim.origin.y < contendedMin.y {
            contendedMin.y = claim.origin.y
        }
        
        if claim.origin.x + claim.size.width > maxPoint.x {
            contendedMax.x = maxPoint.x
            maxPoint.x = claim.origin.x + claim.size.width
        } else if claim.origin.x + claim.size.width > contendedMax.x {
            contendedMax.x = claim.origin.x + claim.size.width
        }
        if claim.origin.y + claim.size.height > maxPoint.y {
            contendedMax.y = maxPoint.y
            maxPoint.y = claim.origin.y + claim.size.height
        } else if claim.origin.y + claim.size.height > contendedMax.y {
            contendedMax.y = claim.origin.y + claim.size.height
        }
    }
    
    return (min: contendedMin, max: contendedMax)
}

func partOne(_ claims: [Claim]) -> Int {
    let contention = contendedArea(claims)
    
    var fabric = Fabric(Size(width: contention.max.x + 1, height: contention.max.y + 1))
    fabric.add(claims: claims)

    return fabric.contendedFabric
}

verify(testData, partOne)

assertEqual(partOne(input), 116489)


