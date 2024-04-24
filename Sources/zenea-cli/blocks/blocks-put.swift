import Foundation
import AsyncHTTPClient
import Zenea

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
    
    public typealias Element = (BlockSource, Result<Block, Block.PutError>)
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

public enum PutError: Error, CustomStringConvertible {
    case unableToDecode
    
    public var description: String {
        switch self {
        case .unableToDecode: "Unable to decode block data."
        }
    }
}
