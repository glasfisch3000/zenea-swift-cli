import ArgumentParser
import NIOFileSystem

import zenea_http

public enum BlockSource {
    case file(path: String)
    case http(scheme: ZeneaHTTPClient.Scheme, domain: String, port: Int)
}

extension BlockSource: Hashable {}
extension BlockSource: Codable {}

extension BlockSource: CustomStringConvertible {
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

extension BlockSource: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
