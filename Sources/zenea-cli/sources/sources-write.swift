import Foundation
import NIOFileSystem

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
