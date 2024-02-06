import ArgumentParser
import AsyncHTTPClient

import zenea

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "fetch", abstract: "A Tool for fetching Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    @Flag(name: [.customShort("s"), .customLong("print-source")]) public var printSource = false
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        guard let (block, source) = try await ZeneaFetch.fetch(id: blockID) else { throw FetchError.notFound }
        guard let output = block.encode(as: format) else { throw FetchError.unableToEncode }
        
        if printSource {
            print(source.description)
        }
        print(output, terminator: "")
    }
    
    public static func fetch(id: Block.ID) async throws -> (block: Block, source: BlockStorage)? {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        
        let stores = try await loadSources(client: client).get()
        for store in stores {
            guard let block = try? await store.fetchBlock(id: id).get() else { continue }
            
            return (block: block, source: store)
        }
        
        return nil
    }
}

extension ZeneaFetch {
    public enum FetchError: Error, CustomStringConvertible {
        case unableToEncode
        case notFound
        
        public var description: String {
            switch self {
            case .unableToEncode: "Unable to encode block data."
            case .notFound: "Unable to get block with specified ID."
            }
        }
    }
}
