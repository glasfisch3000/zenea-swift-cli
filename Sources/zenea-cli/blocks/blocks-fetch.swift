import AsyncHTTPClient
import Zenea

public func blocksFetch(id: Block.ID) async throws -> BlockFetchOperation {
    let client = HTTPClient(eventLoopGroupProvider: .singleton)
    
    let sources = try await loadSources().get()
    return BlockFetchOperation(block: id, sources: sources.filter(\.isEnabled), client: client)
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
    
    public typealias Element = (BlockSource, Result<Block, Block.FetchError>)
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
