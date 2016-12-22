import Foundation

extension AnyCollection {

    // Calculate the unique combinations of elements in an array
    // taken some number at a time when no element is allowed to repeat
    public func combinations(takenBy: IndexDistance) -> [[Element]] {
        if self.count == 0 || takenBy == 0 || self.count < takenBy {
            return []
        }

        if self.count == takenBy {
            return [Array(self)]
        }

        if takenBy == 1 {
            return self.map { [$0] }
        }


        let head = self.prefix(1)
        let tail = self.suffix(from: self.index(after: self.startIndex))
        let subCombos = tail.combinations(takenBy: takenBy - 1)

        var result: [[Element]] = subCombos.map { head + $0 }
        
        result += tail.combinations(takenBy: takenBy)
        
        return result
    }
}
