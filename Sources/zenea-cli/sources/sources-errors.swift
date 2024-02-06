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

public enum RemoveSourcesError: Error, CustomStringConvertible {
    case notFound
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        }
    }
}
