import ArgumentParser
import Foundation
import AsyncHTTPClient

import zenea

public struct ZeneaPut: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "put", abstract: "A Tool for storing Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    
    @ArgumentParser.Argument public var content: String
    
    public mutating func run() async throws {
        guard let block = Block(decoding: content, as: format) else { throw PutError.unableToDecode }
        guard let resultID = try await ZeneaPut.put(block.content) else { throw PutError.unableToUpload }
        
        print(resultID.description)
    }
    
    public static func put(_ content: Data) async throws -> Block.ID? {
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
}

extension ZeneaPut {
    public enum PutError: Error, CustomStringConvertible {
        case unableToDecode
        case unableToUpload
        
        public var description: String {
            switch self {
            case .unableToDecode: "Unable to decode block data."
            case .unableToUpload: "Unable to put block with specified content."
            }
        }
    }
}
