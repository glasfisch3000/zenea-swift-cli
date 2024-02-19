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
        do {
            guard let info = try await FileSystem.shared.info(forFileAt: filePath) else { throw UploadError.fileNotFound }
            guard info.type == .regular else { throw UploadError.invalidFileType(info.type) }
            
            let handle = try await FileSystem.shared.openFile(forReadingAt: filePath)
            defer { Task { try? await handle.close() } }
            
            let fileContents = handle.readChunks()
            let data = fileContents.map { $0.getData(at: $0.readerIndex, length: $0.readableBytes) ?? Data() }
            
            let valyaSource = ValyaBlockWrapper(source: BlockStorageList(sources: sources))
            
            switch await valyaSource.putBlock(content: data) {
            case .success(let block): print(block.id.description)
            case .failure(.overflow): print("Error: too large.")
            case .failure(.exists(let block)): print("Error: block \(block.id.description) exists.")
            case .failure(.notPermitted): print("Error: not permitted.")
            case .failure(.unavailable): print("Error: unavailable.")
            case .failure(.unable): print("Error: unable.")
            }
        } catch let error as FileSystemError where error.code == .notFound {
            throw UploadError.fileNotFound
        } catch {
            throw UploadError.unableToRead
        }
    }
}
