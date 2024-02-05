import ArgumentParser

import Foundation
import AsyncHTTPClient

import zenea
import zenea_fs
import zenea_http

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "fetch", abstract: "A Tool for fetching Zenea Project Data Layer blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Argument var blockID: Block.ID
    
    @Option(name: .shortAndLong) var format: BlockDataFormat = .raw
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        
        let stores = try await loadSources(client: client).get()
        for store in stores {
            guard let block = try? await store.fetchBlock(id: blockID).get() else { continue }
            
            switch format {
            case .raw:
                guard let string = String(data: block.content, encoding: .utf8) else { throw FetchError.unableToDecode }
                print(string, terminator: "")
            case .hex:
                print(block.content.toHexString(), terminator: "")
            case .base64:
                print(block.content.base64EncodedString(), terminator: "")
            }
        }
    }
}

extension ZeneaFetch {
    public enum FetchError: Error, CustomStringConvertible {
        case unableToDecode
        
        public var description: String {
            switch self {
            case .unableToDecode: "Unable to decode block data."
            }
        }
    }
    
    public enum BlockDataFormat: String, ExpressibleByArgument {
        case raw
        case hex
        case base64
    }
}

extension Block.ID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
