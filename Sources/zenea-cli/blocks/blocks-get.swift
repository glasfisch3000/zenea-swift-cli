import AsyncHTTPClient

import zenea

public func blocksGet(_ blockID: Block.ID) async throws -> Block {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { Task { try? await client.shutdown().get() } }
    
    let sources = try await loadStores(client: client).get()
    
    for source in sources {
        guard let block = try? await source.fetchBlock(id: blockID).get() else { continue }
        return block
    }
    
    throw FetchError.notFound
}
