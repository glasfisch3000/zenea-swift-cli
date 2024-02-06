import ArgumentParser

import zenea

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "fetch", abstract: "A Tool for fetching Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    @Flag(name: [.customShort("s"), .customLong("print-source")]) public var printSource = false
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        guard let (block, source) = try await blocksFetch(id: blockID) else { throw FetchError.notFound }
        guard let output = block.encode(as: format) else { throw FetchError.unableToEncode }
        
        if printSource {
            print(source.description)
        }
        print(output, terminator: "")
    }
}
