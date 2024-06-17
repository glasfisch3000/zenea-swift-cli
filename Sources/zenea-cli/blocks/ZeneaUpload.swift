import Foundation
import ArgumentParser
import AsyncHTTPClient
import NIOFileSystem
import Valya

public struct ZeneaUpload: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "upload", abstract: "Upload Valya block files.", usage: nil, discussion: "", version: "1.0.0", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @ArgumentParser.Flag(name: [.long]) public var debug: Bool = false
    @ArgumentParser.Argument(completion: .file()) public var file: String
    
    public mutating func run() async throws {
        let time0 = Date()
        
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        let source = try await loadStores(client: client).get()
        
        let filePath = FilePath(file)
        do {
            guard let info = try await FileSystem.shared.info(forFileAt: filePath) else { throw UploadError.fileNotFound }
            guard info.type == .regular else { throw UploadError.invalidFileType(info.type) }
            
            let handle = try await FileSystem.shared.openFile(forReadingAt: filePath)
            defer { Task { try? await handle.close() } }
            
            var data = Data()
            for try await chunk in handle.readChunks() {
                guard let chunkData = chunk.getData(at: chunk.readerIndex, length: chunk.readableBytes) else { continue }
                data += chunkData
            }
            
            let valyaSource = ValyaBlockWrapper(source: source)
            
            let time1 = Date()
            
            let result = await valyaSource.putBlock(content: data)
            let time2 = Date()
            
            let outputString: String = switch result {
            case .success(let block): block.id.description
            case .failure(.overflow): "Error: too large."
            case .failure(.exists(let block)): "Error: block \(block.id.description) exists."
            case .failure(.notPermitted): "Error: not permitted."
            case .failure(.unavailable): "Error: unavailable."
            case .failure(.unable): "Error: unable."
            }
            
            if debug {
                print("\(outputString); \(data.count); \(time2.timeIntervalSince(time1)); \(time2.timeIntervalSince(time0))")
            } else {
                print(outputString)
            }
        } catch let error as FileSystemError where error.code == .notFound {
            throw UploadError.fileNotFound
        } catch {
            throw UploadError.unableToRead
        }
    }
}
