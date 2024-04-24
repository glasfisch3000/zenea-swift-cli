import AsyncHTTPClient
import Zenea

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
    
    public typealias Element = (BlockSource, Result<Set<Block.ID>, Block.ListError>)
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
