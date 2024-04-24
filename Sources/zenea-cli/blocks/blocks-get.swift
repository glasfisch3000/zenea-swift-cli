import AsyncHTTPClient
import Zenea

public func blocksGet(_ blockID: Block.ID) async throws -> Block {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { Task { try? await client.shutdown().get() } }
    
    let source = try await loadStores(client: client).get()
    return try await source.fetchBlock(id: blockID).get()
}
