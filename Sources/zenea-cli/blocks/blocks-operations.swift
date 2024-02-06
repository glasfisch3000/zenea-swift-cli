import Foundation
import AsyncHTTPClient

import zenea

public func blocksList() async throws -> Set<Block.ID> {
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

public func blocksFetch(id: Block.ID) async throws -> (block: Block, source: BlockStorage)? {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { try? client.shutdown().wait() }
    
    let stores = try await loadSources(client: client).get()
    for store in stores {
        guard let block = try? await store.fetchBlock(id: id).get() else { continue }
        
        return (block: block, source: store)
    }
    
    return nil
}

public func blocksPut(_ content: Data) async throws -> Block.ID? {
    let block = Block(content: content)
    
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { try? client.shutdown().wait() }
    
    var success = false
    
    let stores = try await loadSources(client: client).get()
    for store in stores {
        switch await store.putBlock(content: block.content) {
        case .success(_): success = true
        default: break
        }
    }
    
    return success ? block.id : nil
}
