import ArgumentParser
import Zenea

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "fetch",
        abstract: "Fetch Zenea blocks.",
        usage: nil,
        discussion: "",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
    
    @Option(name: .shortAndLong, help: "Specify formatting of the block's content. One of raw|hex|base64, default is raw.") public var format: Block.DataFormat = .raw
    @Flag(name: [.customShort("s"), .customLong("print-source")], help: "Show which source the block was fetched from.") public var printSource = false
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        for await (source, block) in try await blocksFetch(id: blockID) {
            guard let block = try? block.get() else { continue }
            guard let output = block.encode(as: format) else { throw FetchError.unableToEncode }
            
            if printSource {
                print(source.name)
            }
            print(output, terminator: "")
            
            return
        }
        
        throw FetchError.notFound(blockID)
    }
}
