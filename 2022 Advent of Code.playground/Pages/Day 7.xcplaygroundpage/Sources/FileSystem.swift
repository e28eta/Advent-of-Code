import Foundation

enum ChangeDirDestination {
    case root, up, into(String)
}

enum DirectoryEntry {
    case file(any StringProtocol, Int)
    indirect case directory(Directory)

    init?( _ line: some StringProtocol) {
        if let name = try? /dir (\w+)/.wholeMatch(in: String(line))?.output.1 {
            self = .directory(Directory(name))
        } else if let matches = try? /(\d+) ([\w.]+)/.wholeMatch(in: String(line))?.output, let size = Int(matches.1) {
            self = .file(matches.2, size)
        } else {
            return nil
        }
    }

    func size() -> Int {
        switch self {
        case .file(_, let size):
            return size
        case .directory(let dir):
            return dir.size()
        }
    }
}

class Directory {
    let name: String
    var parent: Directory? = nil
    var contents: [DirectoryEntry]? = nil {
        didSet {
            for case .directory(let child) in (contents ?? []) {
                child.parent = self
            }
            calculatedSize = nil
        }
    }
    var calculatedSize: Int?

    public init(_ name: some StringProtocol) {
        self.name = String(name)
    }

    subscript(_ name: String) -> Directory? {
        for case .directory(let dir) in (contents ?? []) where dir.name == name {
            return dir
        }
        return nil
    }

    func size() -> Int {
        if let calculatedSize {
            return calculatedSize
        }
        calculatedSize = contents?.reduce(0, { $0 + $1.size() })
        return calculatedSize ?? 0
    }
}

enum InputLine {
    case cdCommand(ChangeDirDestination)
    case lsCommand
    case directoryEntry(DirectoryEntry)

    static func parseInput(_ string: String) -> [InputLine] {
        return string.split(separator: "\n").compactMap(InputLine.init)
    }

    init?(_ line: some StringProtocol) {
        if line == "$ cd /" {
            self = .cdCommand(.root)
        } else if line == "$ cd .." {
            self = .cdCommand(.up)
        } else if let destination = try? /\$ cd (\w+)/.wholeMatch(in: String(line))?.output.1 {
            self = .cdCommand(.into(String(destination)))
        } else if let entry = DirectoryEntry(line) {
            self = .directoryEntry(entry)
        } else {
            return nil
        }
    }
}

public struct FileSystem {
    let head: Directory
    var currentDirectory: Directory
    var allDirectories: [Directory] = []

    init() {
        head = Directory("/")
        currentDirectory = head
    }

    mutating func cd(_ direction: ChangeDirDestination) {
        switch direction {
        case .root:
            currentDirectory = head
        case .up:
            currentDirectory = currentDirectory.parent ?? head
        case .into(let name):
            guard let destination = currentDirectory[name] else {
                fatalError("missing destination")
            }
            currentDirectory = destination
        }
    }

    mutating func update(for inputLine: InputLine) {
        switch inputLine {
        case .lsCommand:
            // no-op, not bothering to check that directory entries occur after input lines
            break
        case .cdCommand(let direction):
            self.cd(direction)
        case .directoryEntry(let entry):
            self.add(entry: entry)
        }
    }

    mutating func add(entry: DirectoryEntry) {
        var contents = currentDirectory.contents ?? []
        contents.append(entry)
        currentDirectory.contents = contents

        if case .directory(let new) = entry {
            allDirectories.append(new)
        }
    }

    public static func filesystem(from input: String) -> FileSystem {
        return input.lines()
            .compactMap(InputLine.init)
            .reduce(into: FileSystem()) { $0.update(for: $1) }
    }

    public func part1() -> Int {
        return allDirectories
            .map { $0.size() }
            .filter { $0 <= 100_000 }
            .reduce(0, +)
    }
}



