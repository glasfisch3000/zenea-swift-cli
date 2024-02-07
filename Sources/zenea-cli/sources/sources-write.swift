import Foundation
import NIOFileSystem

import zenea
import zenea_fs
import zenea_http

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

public enum AddSourcesError: Error, CustomStringConvertible {
    case nameExists
    case exists
    
    public var description: String {
        switch self {
        case .nameExists: "A source with the specified identifier already exists."
        case .exists: "A source with the specified location already exists."
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

public enum RenameSourcesError: Error, CustomStringConvertible {
    case notFound
    case nameExists
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        case .nameExists: "A source with the specified identifier already exists."
        }
    }
}

public enum MoveSourcesError: Error, CustomStringConvertible {
    case notFound
    case indexOutOfBounds
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        case .indexOutOfBounds: "The specified index is not in the list."
        }
    }
}
