//: [Previous](@previous)

/*:
 # Day 10: Balance Bots

 You come upon a factory in which many robots are [zooming around](https://www.youtube.com/watch?v=JnkMyfQ5YfY&t=40) handing small microchips to each other.

 Upon closer examination, you notice that each bot only proceeds when it has **two** microchips, and once it does, it gives each one to a different bot or puts it in a marked "output" bin. Sometimes, bots take microchips from "input" bins, too.

 Inspecting one of the microchips, it seems like they each contain a single number; the bots must use some logic to decide what to do with each chip. You access the local control computer and download the bots' instructions (your puzzle input).

 Some of the instructions specify that a specific-valued microchip should be given to a specific bot; the rest of the instructions indicate what a given bot should do with its **lower-value** or **higher-value** chip.

 For example, consider the following instructions:
 ````
value 5 goes to bot 2
bot 2 gives low to bot 1 and high to bot 0
value 3 goes to bot 1
bot 1 gives low to output 1 and high to bot 0
bot 0 gives low to output 2 and high to output 0
value 2 goes to bot 2
 ````
 Initially, bot `1` starts with a value-`3` chip, and bot `2` starts with a value-`2` chip and a value-`5` chip.
 Because bot `2` has two microchips, it gives its lower one (`2`) to bot `1` and its higher one (`5`) to bot `0`.
 Then, bot `1` has two microchips; it puts the value-`2` chip in output `1` and gives the value-`3` chip to bot `0`.
 Finally, bot `0` has two microchips; it puts the `3` in output `2` and the `5` in output `0`.
 In the end, output bin `0` contains a value-`5` microchip, output bin `1` contains a value-`2` microchip, and output bin `2` contains a value-`3` microchip. In this configuration, bot number `2` is responsible for comparing value-`5` microchips with value-`2` microchips.

 Based on your instructions, **what is the number of the bot** that is responsible for comparing value-`61` microchips with value-`17` microchips?
 */
import Foundation

enum Destination {
    case Bot(Int)
    case Output(Int)
    case None // Don't know if this is possible, it shouldn't be

    init?(_ string: String) {
        if string.hasPrefix("bot ") {
            guard let botNum = Int(string.replacingOccurrences(of: "bot ", with: ""), radix: 10) else { return nil }
            self = .Bot(botNum)
        } else if string.hasPrefix("output ") {
            guard let outputNum = Int(string.replacingOccurrences(of: "output ", with: ""), radix: 10) else { return nil }
            self = .Output(outputNum)
        } else {
            return nil
        }
    }
}

typealias Value = Int
enum Instruction {
    case InitialValue(Value, Destination)
    case DistributionRule(bot: Destination, low: Destination, high: Destination)

    init(_ string: String) {
        if string.hasPrefix("value ") {
            let valueAndDestination = string.replacingOccurrences(of: "value ", with: "").components(separatedBy: " goes to ")
            guard let value = Int(valueAndDestination[0], radix: 10),
                let destination = Destination(valueAndDestination[1]) else {
                    fatalError("malformed instruction: \(string)")
            }

            self = .InitialValue(value, destination)
        } else if string.contains("gives low to") {
            let sourceAndRest = string.components(separatedBy: " gives low to ")
            let lowAndHigh = sourceAndRest[1].components(separatedBy: " and high to ")
            guard let source = Destination(sourceAndRest[0]),
                let low = Destination(lowAndHigh[0]),
                let high = Destination(lowAndHigh[1]) else {
                    fatalError("malformed instruction: \(string)")
            }

            self = .DistributionRule(bot: source, low: low, high: high)
        } else {
            fatalError("malformed instruction: \(string)")
        }
    }
}

struct Bot {
    var currentValue: Value?

    var lowDestination: Destination
    var highDestination: Destination
}

struct BotNetwork {
    var bots: [Bot]
    var outputs: [Value?]

    let instructions: [Instruction]
    let initialValueSteps: [(Value, Destination)]

    init(_ instructions: [Instruction]) {
        self.instructions = instructions

        self.initialValueSteps = instructions.flatMap { instruction in
            if case let .InitialValue(value, destination) = instruction {
                return (value, destination)
            } else {
                return nil
            }
        }

        let allDestinations = instructions.flatMap { instruction -> [Destination] in
            switch instruction {
            case let .InitialValue(_, destination):
                return [destination]
            case let .DistributionRule(bot, low, high):
                return [bot, low, high]
            }
        }

        let (maxBot, maxOutput) = allDestinations.reduce((-1, -1)) { (maxes: (Int, Int), destination: Destination) -> (Int, Int) in
            switch (maxes, destination) {
            case let ((maxBot, maxOutput), .Bot(next)) where next > maxBot:
                return (next, maxOutput)
            case let ((maxBot, maxOutput), .Output(next)) where next > maxOutput:
                return (maxBot, next)
            default:
                return maxes
            }
        }

        self.outputs = Array(repeating: nil, count: maxOutput + 1)

        self.bots = Array(repeating: Bot(currentValue: nil, lowDestination: .None, highDestination: .None), count: maxBot + 1)
        instructions.forEach { instruction in
            if case let .DistributionRule(bot: .Bot(botNumber), low: lowDestination, high: highDestination) = instruction {
                self.bots[botNumber] = Bot(currentValue: nil, lowDestination: lowDestination, highDestination: highDestination)
            }
        }
    }

    mutating func processValues() {
        for (value, destination) in initialValueSteps {
            self.put(value: value, destination: destination)
        }
    }

    mutating func put(value: Value, destination: Destination) {
        switch destination {
        case let .Bot(botNumber):
            if let existingValue = bots[botNumber].currentValue {
                // clear it in case we have cycles
                bots[botNumber].currentValue = nil

                let values = [value, existingValue].sorted()
                // print("\(botNumber): comparing \(values)")
                self.put(value: values[0], destination: bots[botNumber].lowDestination)
                self.put(value: values[1], destination: bots[botNumber].highDestination)
            } else {
                bots[botNumber].currentValue = value
            }
        case let .Output(outputNumber):
            if outputs[outputNumber] != nil {
                print("warning: non-empty output \(outputNumber) contained \(outputs[outputNumber])")
            }
            outputs[outputNumber] = value
        case .None:
            print("error: putting \(value) into None")
        }
    }
}

let exampleInput = "value 5 goes to bot 2\nbot 2 gives low to bot 1 and high to bot 0\nvalue 3 goes to bot 1\nbot 1 gives low to output 1 and high to bot 0\nbot 0 gives low to output 2 and high to output 0\nvalue 2 goes to bot 2".components(separatedBy: .newlines).flatMap { Instruction($0) }
var exampleNetwork = BotNetwork(exampleInput)
print(exampleNetwork)

exampleNetwork.processValues()
print(exampleNetwork)


let input = try readResourceFile("input.txt").components(separatedBy: .newlines).flatMap { Instruction($0) }
var network = BotNetwork(input)
network.processValues()
// printed output said bot 181 compared [17, 61]

/*:
 # Part Two ---

 What do you get if you multiply together the values of one chip in each of outputs 0, 1, and 2?
 */

let part2Answer = network.outputs[0...2].reduce(1) { $0 * ($1 ?? 1) }
assert(part2Answer == 12567)


//: [Next](@next)
