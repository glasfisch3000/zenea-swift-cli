import ArgumentParser
import AsyncHTTPClient
import NIOFileSystem
import Zenea
import ZeneaCache
import ZeneaFiles
import ZeneaHTTP

public struct BlockSource {
    public enum SourceLocation {
        case file(path: String)
        case http(scheme: ZeneaHTTPClient.Scheme, domain: String, port: Int)
    }
    
    var name: String
    var isEnabled: Bool = true
    var location: SourceLocation
}

extension BlockSource: Hashable {}
extension BlockSource: Codable {}

extension BlockSource.SourceLocation: Hashable {}
extension BlockSource.SourceLocation: Codable {}

extension BlockSource.SourceLocation: CustomStringConvertible {
    public init?(parsing string: String) {
        if let http = ZeneaHTTPClient.Server(parsing: string) {
            self = .http(scheme: http.scheme, domain: http.address, port: http.port)
        } else {
            let path = FilePath(string)
            if path.isEmpty { return nil }
            if !path.isAbsolute { return nil }
            
            self = .file(path: path.string)
        }
    }
    
    public var description: String {
        switch self {
        case .file(let path): path
        case .http(let scheme, let domain, let port): "\(scheme)://\(domain):\(port)"
        }
    }
}

extension BlockSource.SourceLocation: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}

extension BlockSource {
    @BlockStorageBuilder func makeStorage(client: HTTPClient) -> some BlockStorage {
        switch self.location {
        case .file(path: let path):
            BlockFS(path)
        case .http(scheme: let scheme, domain: let domain, port: let port):
            ZeneaHTTPClient(scheme: scheme, address: domain, port: port, client: client)
        }
    }
}

extension [BlockSource] {
    @BlockStorageBuilder func makeStorage(client: HTTPClient) -> some BlockStorage {
        BlockStorageList(sources: self.map { $0.makeStorage(client: client) })
    }
}
