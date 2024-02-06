import ArgumentParser

import Foundation
import AsyncHTTPClient

import zenea
import zenea_fs
import zenea_http

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "fetch", abstract: "A Tool for fetching Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Option(name: .shortAndLong) public var format: Block.DataFormat = .raw
    @Flag(name: [.customShort("s"), .customLong("source")]) public var printSource = false
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        guard let (block, source) = try await ZeneaFetch.fetch(id: blockID) else { throw FetchError.notFound }
        guard let output = block.decode(as: format) else { throw FetchError.unableToDecode }
        
        if printSource {
            print(source.description)
        }
        print(output, terminator: "")
    }
    
    public static func fetch(id: Block.ID) async throws -> (block: Block, source: BlockStorage)? {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        
        let stores = try await loadSources(client: client).get()
        for store in stores {
            guard let block = try? await store.fetchBlock(id: id).get() else { continue }
            
            return (block: block, source: store)
        }
        
        return nil
    }
}

extension ZeneaFetch {
    public enum FetchError: Error, CustomStringConvertible {
        case unableToDecode
        case notFound
        
        public var description: String {
            switch self {
            case .unableToDecode: "Unable to decode block data."
            case .notFound: "Unable to get block with specified ID."
            }
        }
    }
}

extension Block {
    public enum DataFormat: String, ExpressibleByArgument {
        case raw
        case hex
        case base64
    }
    
    public func decode(as format: Block.DataFormat) -> String? {
        switch format {
        case .raw:
            guard let string = String(data: self.content, encoding: .utf8) else { return nil }
            return string
        case .hex:
            return self.content.toHexString()
        case .base64:
            return self.content.base64EncodedString()
        }
    }
}

extension Block.ID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
