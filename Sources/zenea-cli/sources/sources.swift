import ArgumentParser
import NIOFileSystem
import AsyncHTTPClient

import zenea
import zenea_fs
import zenea_http

public struct BlockSource {
    public enum SourceLocation {
        case file(path: String)
        case http(scheme: ZeneaHTTPClient.Scheme, domain: String, port: Int)
    }
    
    var name: String
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
    func makeStorage(client: HTTPClient) -> BlockStorage {
        switch self.location {
        case .file(path: let path):
            return BlockFS(path)
        case .http(scheme: let scheme, domain: let domain, port: let port):
            return ZeneaHTTPClient(scheme: scheme, address: domain, port: port, client: client)
        }
    }
}
