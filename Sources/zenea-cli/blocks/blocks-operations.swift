import Foundation
import zenea_http
import AsyncHTTPClient

import zenea

public func blocksList() async throws -> Set<Block.ID> {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { try? client.shutdown().wait() }
    
    var results: Set<Block.ID> = []
    
    let stores = try await loadStores(client: client).get()
    for store in stores {
        guard let blocks = try? await store.listBlocks().get() else { continue }
        results.formUnion(blocks)
    }
    
    return results
}

public func blocksFetch(id: Block.ID) async throws -> (block: Block, source: BlockStorage)? {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    defer { try? client.shutdown().wait() }
    
    let stores = try await loadStores(client: client).get()
    for store in stores {
        guard let block = try? await store.fetchBlock(id: id).get() else { continue }
        
        return (block: block, source: store)
    }
    
    return nil
}

public func blocksPut(_ content: Data) async throws -> BlockPutOperation {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    
    let sources = try await loadSources().get()
    return BlockPutOperation(block: content, sources: sources, client: client)
}

public class BlockPutOperation: AsyncSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = BlockPutOperation.Element
        
        public var operation: BlockPutOperation
        public var index: BlockPutOperation.Index = 0
        
        public mutating func next() async -> BlockPutOperation.Element? {
            defer { index += 1 }
            return await operation.put(index)
        }
    }
    
    public typealias Element = (BlockSource, Result<Block.ID, BlockPutError>)
    public typealias Index = Int
    
    let block: Data
    let sources: [BlockSource]
    let client: HTTPClient
    
    init(block: Data, sources: [BlockSource], client: HTTPClient) {
        self.block = block
        self.sources = sources
        self.client = client
    }
    
    private func put(_ index: Index) async -> Element? {
        guard index < sources.count else { return nil }
        let source = sources[index]
        let store = source.makeStorage(client: client)
        
        return (source, await store.putBlock(content: block))
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(operation: self)
    }
    
    deinit {
        try? client.shutdown().wait()
    }
}
