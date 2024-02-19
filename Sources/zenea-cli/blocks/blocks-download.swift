import NIOFileSystem
import Foundation

import zenea
import valya

public func blocksDownload(id: Block.ID) async throws -> Data {
    let block = try await blocksGet(id)
    
    switch Valya(.v1_1).decode(block.content) {
    case .error, .corrupted: throw DownloadError.decodeError
    case .empty, .regularBlock: return block.content
    case .success(let contents):
        var data = Data()
        for subblock in contents {
            try await data.append(blocksDownload(id: subblock))
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
