import zenea

public enum UploadError: Error, CustomStringConvertible {
    case fileNotFound
    case unableToRead
    case unknown
    
    public var description: String {
        switch self {
        case .fileNotFound: "Input file not found."
        case .unableToRead: "Unable to read input file."
        case .unknown: "Unknown error."
        }
    }
}
