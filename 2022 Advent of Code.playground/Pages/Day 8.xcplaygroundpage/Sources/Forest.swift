import Foundation

public class Forest {
    let MIN_HEIGHT = 0
    let MAX_HEIGHT = 9


    struct Tree {
        let height: Int
        var visible: Bool
    }

    var trees: [[Tree]]

    public init?(_ input: String) {
        trees = input.lines()
            .map { line in
                line.compactMap { treeChar in
                    Int(String(treeChar)).map { height in
                        Tree(height: height, visible: false)
                    }
                }
            }

        guard let forestWidth = trees.first?.count,
              trees.firstIndex(where: { $0.count != forestWidth }) == nil else {
            // empty forest, or different sized rows
            return nil
        }
    }

    public func updateVisibility() {
        for rowIdx in trees.indices {
            for indices in [trees[rowIdx].indices.reversed().reversed(), trees[rowIdx].indices.reversed()] {
                var previousMax = MIN_HEIGHT - 1

                for colIdx in indices where trees[rowIdx][colIdx].height > previousMax {
                    trees[rowIdx][colIdx].visible = true
                    previousMax = trees[rowIdx][colIdx].height

                    if previousMax == MAX_HEIGHT { break }
                }
            }
        }

        for colIdx in trees[0].indices {
            for indices in [trees.indices.reversed().reversed(), trees.indices.reversed()] {
                var previousMax = MIN_HEIGHT - 1

                for rowIdx in indices where trees[rowIdx][colIdx].height > previousMax {
                    trees[rowIdx][colIdx].visible = true
                    previousMax = trees[rowIdx][colIdx].height

                    if previousMax == MAX_HEIGHT { break }
                }
            }
        }
    }

    public func visibleTrees() -> Int {
        return trees.reduce(0) { (sum, row) in
            sum + row.filter(\.visible).count
        }
    }

    public func treeHeights() -> String {
        trees.map { row in
            row.map { tree in tree.height.description }.joined(separator: "")
        }.joined(separator: "\n")
    }

    public func treeVisibilities() -> String {
        trees.map { row in
            row.map { tree in tree.visible ? "t" : "f" }.joined(separator: "")
        }.joined(separator: "\n")
    }
}
