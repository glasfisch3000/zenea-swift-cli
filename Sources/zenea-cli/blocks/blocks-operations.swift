import Foundation
import zenea_http
import AsyncHTTPClient

import zenea

public func blocksList() async throws -> BlockListOperation {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    
    let sources = try await loadSources().get()
    return BlockListOperation(sources: sources, client: client)
}

public class BlockListOperation: AsyncSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = BlockListOperation.Element
        
        public var operation: BlockListOperation
        public var index: BlockListOperation.Index = 0
        
        public mutating func next() async -> BlockListOperation.Element? {
            defer { index += 1 }
            return await operation.list(index)
        }
    }
    
    public typealias Element = (BlockSource, Result<Set<Block.ID>, BlockListError>)
    public typealias Index = Int
    
    let sources: [BlockSource]
    let client: HTTPClient
    
    init(sources: [BlockSource], client: HTTPClient) {
        self.sources = sources
        self.client = client
    }
    
    private func list(_ index: Index) async -> Element? {
        guard index < sources.count else { return nil }
        let source = sources[index]
        let store = source.makeStorage(client: client)
        
        return (source, await store.listBlocks())
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(operation: self)
    }
    
    deinit {
        try? client.shutdown().wait()
    }
}

public func blocksFetch(id: Block.ID) async throws -> BlockFetchOperation {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    
    let sources = try await loadSources().get()
    return BlockFetchOperation(block: id, sources: sources, client: client)
}

public class BlockFetchOperation: AsyncSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = BlockFetchOperation.Element
        
        public var operation: BlockFetchOperation
        public var index: BlockFetchOperation.Index = 0
        
        public mutating func next() async -> BlockFetchOperation.Element? {
            defer { index += 1 }
            return await operation.fetch(index)
        }
    }
    
    public typealias Element = (BlockSource, Result<Block, BlockFetchError>)
    public typealias Index = Int
    
    let block: Block.ID
    let sources: [BlockSource]
    let client: HTTPClient
    
    init(block: Block.ID, sources: [BlockSource], client: HTTPClient) {
        self.block = block
        self.sources = sources
        self.client = client
    }
    
    private func fetch(_ index: Index) async -> Element? {
        guard index < sources.count else { return nil }
        let source = sources[index]
        let store = source.makeStorage(client: client)
        
        return (source, await store.fetchBlock(id: block))
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(operation: self)
    }
    
    deinit {
        try? client.shutdown().wait()
    }
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
