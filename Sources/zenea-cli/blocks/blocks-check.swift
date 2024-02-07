import AsyncHTTPClient

import zenea

public func blocksCheck(id: Block.ID) async throws -> BlockCheckOperation {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    
    let sources = try await loadSources().get()
    return BlockCheckOperation(block: id, sources: sources, client: client)
}

public class BlockCheckOperation: AsyncSequence {
    public struct AsyncIterator: AsyncIteratorProtocol {
        public typealias Element = BlockCheckOperation.Element
        
        public var operation: BlockCheckOperation
        public var index: BlockCheckOperation.Index = 0
        
        public mutating func next() async -> BlockCheckOperation.Element? {
            defer { index += 1 }
            return await operation.check(index)
        }
    }
    
    public typealias Element = (BlockSource, Result<Bool, BlockCheckError>)
    public typealias Index = Int
    
    let block: Block.ID
    let sources: [BlockSource]
    let client: HTTPClient
    
    init(block: Block.ID, sources: [BlockSource], client: HTTPClient) {
        self.block = block
        self.sources = sources
        self.client = client
    }
    
    private func check(_ index: Index) async -> Element? {
        guard index < sources.count else { return nil }
        let source = sources[index]
        let store = source.makeStorage(client: client)
        
        return (source, await store.checkBlock(id: block))
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(operation: self)
    }
    
    deinit {
        try? client.shutdown().wait()
    }
}
