//: [Previous](@previous)

import Foundation

/**
 --- Day 21: Allergen Assessment ---

 You reach the train's last stop and the closest you can get to your vacation island without getting wet. There aren't even any boats here, but nothing can stop you now: you build a raft. You just need a few days' worth of food for your journey.

 You don't speak the local language, so you can't read any ingredients lists. However, sometimes, allergens are listed in a language you **do** understand. You should be able to use this information to determine which ingredient contains which allergen and work out which foods are safe to take with you on your trip.

 You start by compiling a list of foods (your puzzle input), one food per line. Each line includes that food's **ingredients list** followed by some or all of the allergens the food contains.

 Each allergen is found in exactly one ingredient. Each ingredient contains zero or one allergen. **Allergens aren't always marked;** when they're listed (as in `(contains nuts, shellfish)` after an ingredients list), the ingredient that contains each listed allergen will be **somewhere in the corresponding ingredients list**. However, even if an allergen isn't listed, the ingredient that contains that allergen could still be present: maybe they forgot to label it, or maybe it was labeled in a language you don't know.

 For example, consider the following list of foods:

 ```
 mxmxvkd kfcds sqjhc nhms (contains dairy, fish)
 trh fvjkl sbzzf mxmxvkd (contains dairy)
 sqjhc fvjkl (contains soy)
 sqjhc mxmxvkd sbzzf (contains fish)
 ```

 The first food in the list has four ingredients (written in a language you don't understand): `mxmxvkd`, `kfcds`, `sqjhc`, and `nhms`. While the food might contain other allergens, a few allergens the food definitely contains are listed afterward: `dairy` and `fish`.

 The first step is to determine which ingredients **can't possibly** contain any of the allergens in any food in your list. In the above example, none of the ingredients `kfcds`, `nhms`, `sbzzf`, or `trh` can contain an allergen. Counting the number of times any of these ingredients appear in any ingredients list produces `5`: they all appear once each except `sbzzf`, which appears twice.

 Determine which ingredients cannot possibly contain any of the allergens in your list. **How many times do any of those ingredients appear?**
 */

struct Food {
    let ingredients: Set<String>
    let allergens: Set<String>

    init?(_ string: String) {
        if let split = string.splitOnce(separator: " (contains ") {
            ingredients = Set(split.0.split(separator: " ").map(String.init))
            allergens = Set(split.1.replacingOccurrences(of: ")", with: "").components(separatedBy: ", "))
        } else {
            ingredients = Set(string.split(separator: " ").map(String.init))
            allergens = []
        }
    }
}

struct Choices {
    let foods: [Food]

    let allIngredients: Set<String>
    // map between allergen name and ingredients that might contain it
    let allergenIngredients: [String: Set<String>]

    let potentiallyUnsafeIngredients: Set<String>
    let safeIngredients: Set<String>

    init(_ string: String) {
        foods = string.lines().compactMap(Food.init)

        allIngredients = foods.reduce(into: [], { (set, food) in
            set.formUnion(food.ingredients)
        })

        allergenIngredients = foods.reduce(into: [:]) { (map, food) in
            for allergen in food.allergens {
                if let existing = map[allergen] {
                    map[allergen] = existing.intersection(food.ingredients)
                } else {
                    map[allergen] = food.ingredients
                }
            }
        }

        safeIngredients = allergenIngredients.reduce(into: allIngredients) { (set, entry) in
            set.subtract(entry.value)
        }

        potentiallyUnsafeIngredients = allIngredients.subtracting(safeIngredients)
    }

    func safeIngredientUsageCount() -> Int {
        // part one, how many times does a safe ingredient occur in all the foods?
        return foods.reduce(0) { sum, food in
            sum + food.ingredients.filter({ safeIngredients.contains($0) }).count
        }
    }
}

let exampleInput = """
mxmxvkd kfcds sqjhc nhms (contains dairy, fish)
trh fvjkl sbzzf mxmxvkd (contains dairy)
sqjhc fvjkl (contains soy)
sqjhc mxmxvkd sbzzf (contains fish)
"""
let input = try readResourceFile("input.txt")

verify([
    (exampleInput, 5),
    (input, 2265),
]) {
    Choices($0).safeIngredientUsageCount()
}


//: [Next](@next)
