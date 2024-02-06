import ArgumentParser

import zenea

public struct ZeneaPut: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "put", abstract: "Upload Zenea blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    
    @ArgumentParser.Argument public var content: String
    
    public mutating func run() async throws {
        guard let block = Block(decoding: content, as: format) else { throw PutError.unableToDecode }
        guard let resultID = try await blocksPut(block.content) else { throw PutError.unableToUpload }
        
        print(resultID.description)
    }
}
