import ArgumentParser

public struct ZeneaList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "A Tool for listing available Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public mutating func run() async throws {
        let blocks = try await blocksList()
        
        for block in blocks.sorted(by: { $0.description < $1.description }) {
            print(block.description)
        }
    }
}
