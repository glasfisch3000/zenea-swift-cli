import ArgumentParser
import Zenea

public struct ZeneaCheck: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "check", abstract: "Check availability of Zenea blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        for await (source, result) in try await blocksCheck(id: blockID) {
            print(source.name, terminator: " -> ")
            switch result {
            case .success(true): print("Available.")
            case .success(false): print("Not available.")
            case .failure(.unable): print("Error.")
            }
        }
    }
}
