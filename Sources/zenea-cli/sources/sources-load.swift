import Foundation
import AsyncHTTPClient
import NIOFileSystem
import Zenea

public func loadSources() async -> Result<[BlockSource], LoadSourcesError> {
    do {
        let handle = try await FileSystem.shared.openFile(forReadingAt: zeneaFiles.config.sources)
        defer { Task { try? await handle.close() } }
        
        let buffer = try await handle.readToEnd(maximumSizeAllowed: .megabytes(42))
        let sources = try? JSONDecoder().decode([BlockSource].self, from: buffer)
        
        guard let sources = sources else { return .failure(.corrupt) }
        
        return .success(sources)
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

public func loadStores(client: HTTPClient) async -> Result<some BlockStorage, LoadSourcesError> {
    switch await loadSources() {
    case .success(let sources):
        .success(sources.makeStorage(client: client))
    case .failure(let error):
        .failure(error)
    }
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
