import ArgumentParser
import AsyncHTTPClient
import Zenea

public struct ZeneaSync: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "sync", abstract: "Synchronise Zenea blocks between block sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: [.customShort("S"), .long]) public var source: String?
    
    @ArgumentParser.Argument public var blockID: Block.ID
    @ArgumentParser.Argument public var destination: String
    
    public mutating func run() async throws {
        let sources = try await loadSources().get()
        guard let destination = sources.first(where: { $0.name == self.destination }) else { throw SyncError.destinationNotFound }
        guard destination.isEnabled else { throw SyncError.destinationDisabled }
        
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { Task { try? await client.shutdown().get() } }
        
        let block: Block
        
        if let source = source {
            guard let source = sources.first(where: { $0.name == source }) else { throw SyncError.sourceNotFound }
            guard source.isEnabled else { throw SyncError.sourceDisabled }
            let store = source.makeStorage(client: client)
            
            switch await store.fetchBlock(id: self.blockID) {
            case .success(let result): block = result
            case .failure(let error): throw SyncError.fetchError(error)
            }
        } else {
            block = try await blocksGet(blockID)
        }
        
        let store = destination.makeStorage(client: client)
        switch await store.putBlock(block: block) {
        case .success(_): return
        case .failure(let error): throw SyncError.putError(error)
        }
    }
}
