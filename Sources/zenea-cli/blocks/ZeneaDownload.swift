import ArgumentParser
import NIOFileSystem
import Zenea

public struct ZeneaDownload: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "download", abstract: "Download Valya block files.", usage: nil, discussion: "", version: "1.0.0", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Argument public var blockID: Block.ID
    @ArgumentParser.Argument(completion: .file()) public var file: String
    
    public mutating func run() async throws {
        let content = try await blocksDownload(id: blockID)
        let file = FilePath(self.file)
        
        do {
            try await FileSystem.shared.createDirectory(at: file.removingLastComponent(), withIntermediateDirectories: true)
        } catch {}
        
        do {
            let handle = try await FileSystem.shared.openFile(forWritingAt: file, options: .newFile(replaceExisting: true))
            defer { Task { try? await handle.close(makeChangesVisible: true) } }
            
            try await handle.write(contentsOf: content, toAbsoluteOffset: 0)
            try await handle.close(makeChangesVisible: true)
        } catch _ as FileSystemError {
            throw DownloadError.unableToWrite
        } catch {
            throw DownloadError.unknown
        }
    }
}
