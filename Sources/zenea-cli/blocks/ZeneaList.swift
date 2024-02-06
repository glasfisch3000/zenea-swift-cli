import ArgumentParser
import AsyncHTTPClient

import zenea

public struct ZeneaList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "A Tool for listing available Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public mutating func run() async throws {
        let blocks = try await ZeneaList.list()
        
        for block in blocks.sorted(by: { $0.description < $1.description }) {
            print(block.description)
        }
    }
    
    public static func list() async throws -> Set<Block.ID> {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        
        var results: Set<Block.ID> = []
        
        let stores = try await loadSources(client: client).get()
        for store in stores {
            guard let blocks = try? await store.listBlocks().get() else { continue }
            results.formUnion(blocks)
        }
        
        return results
    }
}
