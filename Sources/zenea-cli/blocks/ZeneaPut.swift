import ArgumentParser
import Zenea

public struct ZeneaPut: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "put", abstract: "Upload Zenea blocks.", usage: nil, discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    
    @ArgumentParser.Argument public var content: String
    
    public mutating func run() async throws {
        guard let block = Block(decoding: content, as: format) else { throw PutError.unableToDecode }
        
        for await (source, result) in try await blocksPut(block.content) {
            print(source.name, terminator: " -> ")
            switch result {
            case .success(let block): print(block.id.description)
            case .failure(.overflow): print("Error: Block is too large.")
            case .failure(.exists): print("Error: Block already exists.")
            case .failure(.notPermitted): print("Error: Not permitted.")
            case .failure(.unavailable): print("Error: Block source unavailable.")
            case .failure(.unable): print("Error.")
            }
        }
    }
}
