import NIOFileSystem
import Foundation

import zenea
import valya

public func blocksDownload(id: Block.ID) async throws -> Data {
    let block = try await blocksGet(id)
    
    switch block.decode() {
    case .error, .corrupted: throw DownloadError.decodeError
    case .empty, .regularBlock: return block.content
    case .valyaBlock(let valya):
        var data = Data()
        for block in valya.content {
            try await data.append(blocksDownload(id: block))
        }
        
        return data
    }
}

public enum DownloadError: Error, CustomStringConvertible {
    case decodeError
    case unableToWrite
    case unknown
    
    public var description: String {
        switch self {
        case .decodeError: "Unable to decode blocks."
        case .unableToWrite: "Unable to write to destination file."
        case .unknown: "Unknown error."
        }
    }
}
