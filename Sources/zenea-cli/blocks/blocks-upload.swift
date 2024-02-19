import NIOFileSystem

public enum UploadError: Error, CustomStringConvertible {
    case fileNotFound
    case unableToRead
    case invalidFileType(_ type: FileType)
    case unknown
    
    public var description: String {
        switch self {
        case .fileNotFound: "Input file not found."
        case .unableToRead: "Unable to read input file."
        case .invalidFileType(.directory): "Cannot upload directories."
        case .invalidFileType(let type): "Invalid file type (\(type.description))."
        case .unknown: "Unknown error."
        }
    }
}
