import zenea_http

public enum BlockSource {
    case file(path: String)
    case http(scheme: ZeneaHTTPClient.Scheme, domain: String, port: Int)
}

extension BlockSource: Hashable {}
extension BlockSource: Codable {}

extension BlockSource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .file(let path): path
        case .http(let scheme, let domain, let port): "\(scheme)://\(domain):\(port)"
        }
    }
}
