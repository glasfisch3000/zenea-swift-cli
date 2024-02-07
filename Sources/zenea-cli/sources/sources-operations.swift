import Foundation
import NIOFileSystem
import AsyncHTTPClient

import zenea
import zenea_fs
import zenea_http

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

public func loadStores(client: HTTPClient) async -> Result<[BlockStorage], LoadSourcesError> {
    switch await loadSources() {
    case .success(let sources):
        return .success(sources.map { $0.makeStorage(client: client) })
    case .failure(let error): return .failure(error)
    }
}

func writeSources(_ sources: [BlockSource], replace: Bool = true) async -> Result<Void, WriteSourcesError> {
    do {
        let data = try JSONEncoder().encode(sources)
        
        try? await FileSystem.shared.createDirectory(at: zeneaFiles.config.sources.removingLastComponent(), withIntermediateDirectories: true)
        
        let handle = try await FileSystem.shared.openFile(forWritingAt: zeneaFiles.config.sources, options: .newFile(replaceExisting: replace))
        defer { Task { try? await handle.close(makeChangesVisible: true) } }
        
        try await handle.write(contentsOf: data, toAbsoluteOffset: 0)
        try await handle.close(makeChangesVisible: true)
        
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

func writeStores(_ stores: [BlockStorage], replace: Bool = true) async -> Result<Void, WriteSourcesError> {
    let sources = stores.compactMap { storage -> BlockSource? in
        switch storage {
        case let fs as BlockFS: return .file(path: fs.zeneaURL.string)
        case let http as ZeneaHTTPClient: return .http(scheme: http.server.scheme, domain: http.server.address, port: http.server.port)
        default: return nil
        }
    }
    
    return await writeSources(sources, replace: replace)
}
