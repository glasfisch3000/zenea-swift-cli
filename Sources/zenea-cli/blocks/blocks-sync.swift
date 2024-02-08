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

public enum SyncError: Error, CustomStringConvertible {
    case sourceNotFound
    case destinationNotFound
    
    case fetchError(_ error: BlockFetchError)
    case putError(_ error: BlockPutError)
    
    public var description: String {
        switch self {
        case .sourceNotFound: "Unable to locate specified block source."
        case .destinationNotFound: "Unable to locate specified block destination."
        case .fetchError(.invalidContent), .fetchError(.unable): "Internal error at source."
        case .fetchError(.notFound): "Specified block not found at source."
        case .putError(.exists): "Block already exists at destination."
        case .putError(.notPermitted): "Not permitted to put block at destination."
        case .putError(.unavailable): "Destination not available."
        case .putError(.unable): "Destination unable to put block."
        }
    }
}
