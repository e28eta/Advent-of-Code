//: [Previous](@previous)

import Foundation

/**
 --- Day 20: Jurassic Jigsaw ---

 The high-speed train leaves the forest and quickly carries you south. You can even see a desert in the distance! Since you have some spare time, you might as well see if there was anything interesting in the image the Mythical Information Bureau satellite captured.

 After decoding the satellite messages, you discover that the data actually contains many small images created by the satellite's **camera array.** The camera array consists of many cameras; rather than produce a single square image, they produce many smaller square image **tiles** that need to be **reassembled back into a single image.**

 Each camera in the camera array returns a single monochrome **image tile** with a random unique **ID number.** The tiles (your puzzle input) arrived in a random order.

 Worse yet, the camera array appears to be malfunctioning: each image tile has been **rotated and flipped to a random orientation.** Your first task is to reassemble the original image by orienting the tiles so they fit together.

 To show how the tiles should be reassembled, each tile's image data includes a border that should line up exactly with its adjacent tiles. All tiles have this border, and the border lines up exactly when the tiles are both oriented correctly. Tiles at the edge of the image also have this border, but the outermost edges won't line up with any other tiles.

 For example, suppose you have the following nine tiles:

 ```
 Tile 2311:
 ..##.#..#.
 ##..#.....
 #...##..#.
 ####.#...#
 ##.##.###.
 ##...#.###
 .#.#.#..##
 ..#....#..
 ###...#.#.
 ..###..###

 Tile 1951:
 #.##...##.
 #.####...#
 .....#..##
 #...######
 .##.#....#
 .###.#####
 ###.##.##.
 .###....#.
 ..#.#..#.#
 #...##.#..

 Tile 1171:
 ####...##.
 #..##.#..#
 ##.#..#.#.
 .###.####.
 ..###.####
 .##....##.
 .#...####.
 #.##.####.
 ####..#...
 .....##...

 Tile 1427:
 ###.##.#..
 .#..#.##..
 .#.##.#..#
 #.#.#.##.#
 ....#...##
 ...##..##.
 ...#.#####
 .#.####.#.
 ..#..###.#
 ..##.#..#.

 Tile 1489:
 ##.#.#....
 ..##...#..
 .##..##...
 ..#...#...
 #####...#.
 #..#.#.#.#
 ...#.#.#..
 ##.#...##.
 ..##.##.##
 ###.##.#..

 Tile 2473:
 #....####.
 #..#.##...
 #.##..#...
 ######.#.#
 .#...#.#.#
 .#########
 .###.#..#.
 ########.#
 ##...##.#.
 ..###.#.#.

 Tile 2971:
 ..#.#....#
 #...###...
 #.#.###...
 ##.##..#..
 .#####..##
 .#..####.#
 #..#.#..#.
 ..####.###
 ..#.#.###.
 ...#.#.#.#

 Tile 2729:
 ...#.#.#.#
 ####.#....
 ..#.#.....
 ....#..#.#
 .##..##.#.
 .#.####...
 ####.#.#..
 ##.####...
 ##..#.##..
 #.##...##.

 Tile 3079:
 #.#.#####.
 .#..######
 ..#.......
 ######....
 ####.#..#.
 .#...#.##.
 #.#####.##
 ..#.###...
 ..#.......
 ..#.###...
 ```

 By rotating, flipping, and rearranging them, you can find a square arrangement that causes all adjacent borders to line up:

 ```
\#...##.#.. ..###..### #.#.#####.
 ..#.#..#.# ###...#.#. .#..######
 .###....#. ..#....#.. ..#.......
 ###.##.##. .#.#.#..## ######....
 .###.##### ##...#.### ####.#..#.
 .##.#....# ##.##.###. .#...#.##.
 #...###### ####.#...# #.#####.##
 .....#..## #...##..#. ..#.###...
 #.####...# ##..#..... ..#.......
 #.##...##. ..##.#..#. ..#.###...

 #.##...##. ..##.#..#. ..#.###...
 ##..#.##.. ..#..###.# ##.##....#
 ##.####... .#.####.#. ..#.###..#
 ####.#.#.. ...#.##### ###.#..###
 .#.####... ...##..##. .######.##
 .##..##.#. ....#...## #.#.#.#...
 ....#..#.# #.#.#.##.# #.###.###.
 ..#.#..... .#.##.#..# #.###.##..
 ####.#.... .#..#.##.. .######...
 ...#.#.#.# ###.##.#.. .##...####

 ...#.#.#.# ###.##.#.. .##...####
 ..#.#.###. ..##.##.## #..#.##..#
 ..####.### ##.#...##. .#.#..#.##
 #..#.#..#. ...#.#.#.. .####.###.
 .#..####.# #..#.#.#.# ####.###..
 .#####..## #####...#. .##....##.
 ##.##..#.. ..#...#... .####...#.
 #.#.###... .##..##... .####.##.#
 #...###... ..##...#.. ...#..####
 ..#.#....# ##.#.#.... ...##.....
 ```

 For reference, the IDs of the above tiles are:

 ```
 1951    2311    3079
 2729    1427    2473
 2971    1489    1171
 ```

 To check that you've assembled the image correctly, multiply the IDs of the four corner tiles together. If you do this with the assembled tiles from the example above, you get `1951 * 3079 * 2971 * 1171` = `20899048083289`.

 Assemble the tiles into an image. **What do you get if you multiply together the IDs of the four corner tiles?**
 */


extension Sequence where Element == Bool {
    func decimalValue() -> Int {
        return reduce(0) { value, bit in
            value * 10 + (bit ? 1 : 0)
        }
    }
}

struct Tile {
    let id: Int

    let imageData: [[Bool]]

    // map each edge to Int (for easier comparison), both regular & flipped
    let possibleEdgeValues: [Int]

    init(_ string: String) {
        let lines = string.lines()
        imageData = lines.dropFirst().map({ line in line.map({ $0 == "#" }) })

        guard let idString = lines.first?.splitOnce(separator: " ")?.1.dropLast(),
              let id = Int(idString)
        else {
            fatalError("could not parse id from \(string)")
        }

        self.id = id

        possibleEdgeValues = [
            imageData.first!.decimalValue(), // top, clockwise from top-left
            imageData.map({ $0.last!}).decimalValue(), // right
            imageData.last!.reversed().decimalValue(), // bottom
            imageData.map({ $0.first!}).reversed().decimalValue(), // left

            imageData.first!.reversed().decimalValue(), // top, ccw from top-right
            imageData.map({ $0.first!}).decimalValue(), // left
            imageData.last!.decimalValue(), // bottom
            imageData.map({ $0.last!}).reversed().decimalValue(), // right
        ]
    }
}

struct Image {
    let tiles: [Tile]

    init(_ string: String) {
        tiles = string.components(separatedBy: "\n\n").map(Tile.init)
    }

    func corners() -> [Tile] {
        let edgeFrequencies = tiles.flatMap(\.possibleEdgeValues)
            .reduce(into: [:]) { (frequencies, edge) in
                frequencies[edge, default: 0] += 1
            }

        return tiles.filter { tile in
            tile.possibleEdgeValues.filter { edge in
                edgeFrequencies[edge] == 1
            }.count == 4
        }
    }
}

let exampleInput = """
Tile 2311:
..##.#..#.
##..#.....
#...##..#.
####.#...#
##.##.###.
##...#.###
.#.#.#..##
..#....#..
###...#.#.
..###..###

Tile 1951:
#.##...##.
#.####...#
.....#..##
#...######
.##.#....#
.###.#####
###.##.##.
.###....#.
..#.#..#.#
#...##.#..

Tile 1171:
####...##.
#..##.#..#
##.#..#.#.
.###.####.
..###.####
.##....##.
.#...####.
#.##.####.
####..#...
.....##...

Tile 1427:
###.##.#..
.#..#.##..
.#.##.#..#
#.#.#.##.#
....#...##
...##..##.
...#.#####
.#.####.#.
..#..###.#
..##.#..#.

Tile 1489:
##.#.#....
..##...#..
.##..##...
..#...#...
#####...#.
#..#.#.#.#
...#.#.#..
##.#...##.
..##.##.##
###.##.#..

Tile 2473:
#....####.
#..#.##...
#.##..#...
######.#.#
.#...#.#.#
.#########
.###.#..#.
########.#
##...##.#.
..###.#.#.

Tile 2971:
..#.#....#
#...###...
#.#.###...
##.##..#..
.#####..##
.#..####.#
#..#.#..#.
..####.###
..#.#.###.
...#.#.#.#

Tile 2729:
...#.#.#.#
####.#....
..#.#.....
....#..#.#
.##..##.#.
.#.####...
####.#.#..
##.####...
##..#.##..
#.##...##.

Tile 3079:
#.#.#####.
.#..######
..#.......
######....
####.#..#.
.#...#.##.
#.#####.##
..#.###...
..#.......
..#.###...
"""

let exampleImage = Image(exampleInput)
let image = try Image(readResourceFile("input.txt"))

verify([
    (exampleImage, 20899048083289),
    (image, 29125888761511),
]) {
    $0.corners().map(\.id).reduce(1, *)
}

/**
 --- Part Two ---

 Now, you're ready to **check the image for sea monsters.**

 The borders of each tile are not part of the actual image; start by removing them.

 In the example above, the tiles become:

 ```
 .#.#..#. ##...#.# #..#####
 ###....# .#....#. .#......
 ##.##.## #.#.#..# #####...
 ###.#### #...#.## ###.#..#
 ##.#.... #.##.### #...#.##
 ...##### ###.#... .#####.#
 ....#..# ...##..# .#.###..
 .####... #..#.... .#......

 #..#.##. .#..###. #.##....
 #.####.. #.####.# .#.###..
 ###.#.#. ..#.#### ##.#..##
 #.####.. ..##..## ######.#
 ##..##.# ...#...# .#.#.#..
 ...#..#. .#.#.##. .###.###
 .#.#.... #.##.#.. .###.##.
 ###.#... #..#.##. ######..

 .#.#.### .##.##.# ..#.##..
 .####.## #.#...## #.#..#.#
 ..#.#..# ..#.#.#. ####.###
 #..####. ..#.#.#. ###.###.
 #####..# ####...# ##....##
 #.##..#. .#...#.. ####...#
 .#.###.. ##..##.. ####.##.
 ...###.. .##...#. ..#..###
 ```

 Remove the gaps to form the actual image:

 ```
 .#.#..#.##...#.##..#####
 ###....#.#....#..#......
 ##.##.###.#.#..######...
 ###.#####...#.#####.#..#
 ##.#....#.##.####...#.##
 ...########.#....#####.#
 ....#..#...##..#.#.###..
 .####...#..#.....#......
 #..#.##..#..###.#.##....
 #.####..#.####.#.#.###..
 ###.#.#...#.######.#..##
 #.####....##..########.#
 ##..##.#...#...#.#.#.#..
 ...#..#..#.#.##..###.###
 .#.#....#.##.#...###.##.
 ###.#...#..#.##.######..
 .#.#.###.##.##.#..#.##..
 .####.###.#...###.#..#.#
 ..#.#..#..#.#.#.####.###
 #..####...#.#.#.###.###.
 #####..#####...###....##
 #.##..#..#...#..####...#
 .#.###..##..##..####.##.
 ...###...##...#...#..###
 ```

 Now, you're ready to search for sea monsters! Because your image is monochrome, a sea monster will look like this:

 ```
                   #
 #    ##    ##    ###
  #  #  #  #  #  #
 ```

 When looking for this pattern in the image, the **spaces can be anything;** only the `#` need to match. Also, you might need to rotate or flip your image before it's oriented correctly to find sea monsters. In the above image, **after flipping and rotating it** to the appropriate orientation, there are two sea monsters (marked with `O`):

 ```
 .####...#####..#...###..
 #####..#..#.#.####..#.#.
 .#.#...#.###...#.##.O#..
 #.O.##.OO#.#.OO.##.OOO##
 ..#O.#O#.O##O..O.#O##.##
 ...#.#..##.##...#..#..##
 #.##.#..#.#..#..##.#.#..
 .###.##.....#...###.#...
 #.####.#.#....##.#..#.#.
 ##...#..#....#..#...####
 ..#.##...###..#.#####..#
 ....#.##.#.#####....#...
 ..##.##.###.....#.##..#.
 #...#...###..####....##.
 .#.##...#.##.#.#.###...#
 #.###.#..####...##..#...
 #.###...#.##...#.##O###.
 .O##.#OO.###OO##..OOO##.
 ..O#.O..O..O.#O##O##.###
 #.#..##.########..#..##.
 #.#####..#.#...##..#....
 #....##..#.#########..##
 #...#.....#..##...###.##
 #..###....##.#...##.##.#
 ```

 Determine how rough the waters are in the sea monsters' habitat by counting the number of `#` that are not part of a sea monster. In the above example, the habitat's water roughness is `273`.

 \**How many `#` are not part of a sea monster?**
 */

//: [Next](@next)
