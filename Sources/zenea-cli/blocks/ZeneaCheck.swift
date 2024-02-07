import ArgumentParser

import zenea

public struct ZeneaCheck: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "check", abstract: "Check availability of Zenea blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        for await (source, result) in try await blocksFetch(id: blockID) {
            print(source.description, terminator: " -> ")
            switch result {
            case .success(_): print("Available.")
            case .failure(.notFound): print("Not available.")
            case .failure(.invalidContent): print("Error: Invalid Content.")
            case .failure(.unable): print("Error.")
            }
        }
    }
}
