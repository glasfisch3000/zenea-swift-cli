import Foundation
import AsyncHTTPClient
import NIOFileSystem

import zenea
import zenea_fs
import zenea_http

fileprivate enum Source: Codable {
    case file(path: String)
    case http(scheme: ZeneaHTTPClient.Scheme, domain: String, port: Int)
}

public enum LoadSourcesError: Error, CustomStringConvertible {
    case missing
    case unableToRead
    case corrupt
    case unknown
    
    public var description: String {
        switch self {
        case .missing: "Unable to locate sources config file."
        case .unableToRead: "Unable to open sources config file."
        case .corrupt: "Unable to parse sources config file."
        case .unknown: "Unknown error while reading sources config file."
        }
    }
}

public func loadSources(client: HTTPClient) async -> Result<[BlockStorage], LoadSourcesError> {
    var results: [BlockStorage] = []
    
    do {
        let handle = try await FileSystem.shared.openFile(forReadingAt: zeneaFiles.config.sources)
        defer { Task { try? await handle.close() } }
        
        let buffer = try await handle.readToEnd(maximumSizeAllowed: .megabytes(42))
        let sources = try? JSONDecoder().decode([Source].self, from: buffer)
        
        guard let sources = sources else { return .failure(.corrupt) }
        
        for source in sources {
            switch source {
            case .file(path: let path):
                results.append(BlockFS(path))
            case .http(scheme: let scheme, domain: let domain, port: let port):
                results.append(ZeneaHTTPClient(scheme: scheme, address: domain, port: port, client: client))
            }
        }
        
        return .success(results)
    } catch let error as FileSystemError {
        switch error.code {
        case .notFound: return .failure(.missing)
        default: return .failure(.unableToRead)
        }
    } catch _ as DecodingError {
        return .failure(.corrupt)
    } catch {
        return .failure(.unknown)
    }
}

public enum WriteSourcesError: Error, CustomStringConvertible {
    case exists
    case corrupt
    case unableToWrite
    case unknown
    
    public var description: String {
        switch self {
        case .exists: "Unable to write sources config file: File exists."
        case .corrupt: "Unable to write sources config file: Corrupt data."
        case .unableToWrite: "Unable to open sources config file."
        case .unknown: "Unknown error while writing sources config file."
        }
    }
}

func writeSources(_ stores: [BlockStorage], replace: Bool = true) async -> Result<Void, WriteSourcesError> {
    let sources = stores.compactMap { storage -> Source? in
        switch storage {
        case let fs as BlockFS: return .file(path: fs.zeneaURL.string)
        case let http as ZeneaHTTPClient: return .http(scheme: http.server.scheme, domain: http.server.address, port: http.server.port)
        default: return nil
        }
    }
    
    do {
        let data = try JSONEncoder().encode(sources)
        
        let handle = try await FileSystem.shared.openFile(forWritingAt: zeneaFiles.config.sources, options: .newFile(replaceExisting: replace))
        defer { Task { try? await handle.close() } }
        
        try await handle.write(contentsOf: data, toAbsoluteOffset: 0)
        
        return .success(())
    } catch let error as FileSystemError {
        switch error.code {
        case .fileAlreadyExists: return .failure(.exists)
        default: return .failure(.unableToWrite)
        }
    } catch _ as EncodingError {
        return .failure(.corrupt)
    } catch {
        return .failure(.unknown)
    }
}
