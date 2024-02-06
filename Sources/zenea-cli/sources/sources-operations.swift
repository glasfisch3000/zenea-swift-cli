import Foundation
import NIOFileSystem
import AsyncHTTPClient

import zenea
import zenea_fs
import zenea_http

public func listSources() async -> Result<[BlockSource], LoadSourcesError> {
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

public func loadSources(client: HTTPClient) async -> Result<[BlockStorage], LoadSourcesError> {
    switch await listSources() {
    case .success(let sources):
        return .success(sources.map { source in
            switch source {
            case .file(path: let path):
                BlockFS(path)
            case .http(scheme: let scheme, domain: let domain, port: let port):
                ZeneaHTTPClient(scheme: scheme, address: domain, port: port, client: client)
            }
        })
    case .failure(let error): return .failure(error)
    }
}

func writeSources(_ stores: [BlockStorage], replace: Bool = true) async -> Result<Void, WriteSourcesError> {
    let sources = stores.compactMap { storage -> BlockSource? in
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
