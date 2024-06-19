import Foundation
import ArgumentParser
import AsyncHTTPClient
import NIOFileSystem
import Zenea
import Valya

public struct ZeneaUpload: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "upload", abstract: "Upload Valya block files.", usage: nil, discussion: "", version: "1.1.0", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Flag(name: [.long]) public var debug: Bool = false
    @ArgumentParser.Argument(help: .init(valueName: "file"), completion: .file()) public var files: [String]
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        let source = try await loadStores(client: client).get()
        
        let valyaSource = ValyaBlockWrapper(source: source)
        
        let time0 = Date()
        
        do {
            try await withThrowingTaskGroup(of: (String, Int, Result<Block, Block.PutError>, TimeInterval).self) { group in
                for file in files {
                    let filePath = FilePath(file)
                    
                    guard let info = try await FileSystem.shared.info(forFileAt: filePath) else { throw UploadError.fileNotFound }
                    guard info.type == .regular else { throw UploadError.invalidFileType(info.type) }
                    
                    let handle = try await FileSystem.shared.openFile(forReadingAt: filePath)
                    defer { Task { try? await handle.close() } }
                    
                    var data = Data()
                    for try await chunk in handle.readChunks() {
                        guard let chunkData = chunk.getData(at: chunk.readerIndex, length: chunk.readableBytes) else { continue }
                        data += chunkData
                    }
                    
                    let immutableData = data
                    
                    group.addTask {
                        let time1 = Date()
                        let result = await valyaSource.putBlock(content: immutableData)
                        
                        return (file, immutableData.count, result, Date().timeIntervalSince(time1))
                    }
                }
                
                for try await (file, size, result, time) in group {
                    let outputString: String = switch result {
                    case .success(let block): block.id.description
                    case .failure(.overflow): "Error: too large."
                    case .failure(.exists(let block)): "Error: block \(block.id.description) exists."
                    case .failure(.notPermitted): "Error: not permitted."
                    case .failure(.unavailable): "Error: unavailable."
                    case .failure(.unable): "Error: unable."
                    }
                    
                    if debug {
                        print("\"\(file)\"; \"\(outputString)\"; \(size); \(time); \(Date().timeIntervalSince(time0))")
                    } else if case .failure(let error) = result {
                        print("\(file) ->")
                        throw error
                    } else {
                        print("\(file) -> \(outputString)")
                    }
                }
            }
        } catch let error as FileSystemError {
            if error.code == .notFound { throw UploadError.fileNotFound }
            throw UploadError.unableToRead
        }
    }
}
