import ArgumentParser
import NIOFileSystem
import Vapor

import zenea
import valya

public struct ZeneaUpload: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "upload", abstract: "Upload Valya block files.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Argument(completion: .file()) public var file: String
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        let sources = try await loadStores(client: client).get()
        
        let filePath = FilePath(file)
        var buffer: ByteBuffer
        do {
            let handle = try await FileSystem.shared.openFile(forReadingAt: filePath)
            defer { Task { try? await handle.close() } }
            
            buffer = try await handle.readToEnd(maximumSizeAllowed: .megabytes(42))
        } catch let error as FileSystemError where error.code == .notFound {
            throw UploadError.fileNotFound
        } catch {
            throw UploadError.unableToRead
        }
        
        guard let bytes = buffer.readBytes(length: buffer.readableBytes) else { throw UploadError.unableToRead }
        let data = Data(bytes)
        
        let valyaSources = sources.map { ValyaBlockWrapper(source: $0) }
        
        for source in valyaSources {
            switch await source.putBlock(content: data) {
            case .success(let id): print("\(source.description) -> \(id.description)")
            case .failure(.exists): print("\(source.description) -> Error: exists")
            case .failure(.notPermitted): print("\(source.description) -> Error: not permitted")
            case .failure(.unavailable): print("\(source.description) -> Error: unavailable")
            case .failure(.unable): print("\(source.description) -> Error: unable")
            }
        }
    }
}
