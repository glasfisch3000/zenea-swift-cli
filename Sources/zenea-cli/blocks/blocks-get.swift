import AsyncHTTPClient

import zenea

public func blocksGet(_ blockID: Block.ID) async throws -> Block {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { Task { try? await client.shutdown().get() } }
    
    let sources = try await loadStores(client: client).get()
    
    for source in sources {
        switch await source.fetchBlock(id: blockID) {
        case .success(let block): return block
        case .failure(_): break
        }
    }
    
    throw GetError.notFound(blockID)
}

public enum GetError: Error, CustomStringConvertible {
    case notFound(_ id: Block.ID)
    
    public var description: String {
        switch self {
        case .notFound(let id): "Unable to get block with ID \(id.description)."
        }
    }
}
