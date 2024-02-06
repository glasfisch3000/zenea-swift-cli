public enum FetchError: Error, CustomStringConvertible {
    case unableToEncode
    case notFound
    
    public var description: String {
        switch self {
        case .unableToEncode: "Unable to encode block data."
        case .notFound: "Unable to get block with specified ID."
        }
    }
}

public enum PutError: Error, CustomStringConvertible {
    case unableToDecode
    case unableToUpload
    
    public var description: String {
        switch self {
        case .unableToDecode: "Unable to decode block data."
        case .unableToUpload: "Unable to put block with specified content."
        }
    }
}
