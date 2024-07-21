import ArgumentParser
import AsyncHTTPClient
import ConsoleKit
import Zenea

public struct ZeneaFetch: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "fetch",
        abstract: "Fetch Zenea blocks.",
        usage: nil,
        discussion: "",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
    
    @ArgumentParser.Option(name: .shortAndLong, help: "The output format for the block's contents. One of raw|hex|base64, default is raw.") public var format: Block.DataFormat = .raw
    
    @ArgumentParser.Flag(name: [.customShort("s"), .customLong("print-source")], help: "Show which source the block was fetched from.") public var printSource = false
    @ArgumentParser.Option(name: [.customShort("S"), .long]) public var source: String?
    
    @ArgumentParser.Flag(exclusivity: .chooseLast) public var debugOutputMode: DebugOutputMode = .normal
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.syncShutdown() }
        
        let terminal = Terminal()
        
        if let source = source {
            do {
                try await fetchSingleSource(source, client: client, terminal: terminal)
            } catch {
                let text = "failed to fetch block from \(source): \((error as CustomStringConvertible).description)"
                if debugOutputMode == .silent {
                    terminal.print(text)
                } else {
                    terminal.error(text)
                }
                throw error
            }
        } else {
            do {
                try await fetchAllSources(client: client, terminal: terminal)
            } catch {
                let text = "failed to fetch block: \((error as CustomStringConvertible).description)"
                if debugOutputMode == .silent {
                    terminal.print(text)
                } else {
                    terminal.error(text)
                }
                throw error
            }
        }
    }
    
    public func fetchSingleSource<Terminal: Console>(_ source: String, client: HTTPClient, terminal: Terminal) async throws {
        let silent = debugOutputMode == .silent
        let verbose = debugOutputMode == .verbose
        
        var bar = !silent ? terminal.loadingBar(title: "loading sources", targetQueue: .main) : nil
        bar?.start()
        
        do {
            let (source, storage) = switch await loadSources() {
            case .success(let sources):
                if let source = sources.first(where: { $0.name == source }) {
                    (source, source.makeStorage(client: client))
                } else {
                    throw FetchError.sourceNotFound(source)
                }
            case .failure(let error): throw FetchError.unableToLoadSources(error)
            }
            
            if verbose {
                bar?.succeed()
                
                bar = !silent ? terminal.loadingBar(title: "fetching source \(source.name)", targetQueue: .main) : nil
                bar?.start()
            } else {
                bar?.activity.title = "fetching source \(source.name)"
            }
            
            let result = await storage.fetchBlock(id: blockID)
            bar?.stop()
            
            
            switch result {
            case .success(let block):
                guard let output = block.encode(as: format) else { throw FetchError.unableToEncode }
                if verbose { bar?.succeed() }
                
                terminal.print((printSource ? "\(source.name) -> " : "") + output)
            case .failure(let error):
                throw switch error {
                case .notFound: FetchError.blockNotFound(blockID)
                case .invalidContent: FetchError.contentCorrupted
                case .unable: FetchError.unable
                }
            }
        } catch {
            bar?.fail()
            throw error
        }
    }
    
    public func fetchAllSources(client: HTTPClient, terminal: Terminal) async throws {
        let silent = debugOutputMode == .silent
        let verbose = debugOutputMode == .verbose
        let blockID = blockID
        
        let terminal = Terminal()
        let loadingBar = !silent ? terminal.loadingBar(title: "loading sources", targetQueue: .main) : nil
        loadingBar?.start()
        
        let sources = switch await loadSources() {
        case .success(let sources): sources.filter(\.isEnabled).map { ($0.name, $0.makeStorage(client: client)) }
        case .failure(let error):
            loadingBar?.fail()
            throw FetchError.unableToLoadSources(error)
        }
        
        if verbose {
            loadingBar?.succeed()
        } else {
            loadingBar?.stop()
        }
        
        var progressBar = !silent ? terminal.progressBar(title: "fetching sources", targetQueue: .main) : nil
        progressBar?.start()
        
        try await withThrowingTaskGroup(of: (String, Result<Block, Block.FetchError>).self) { group in
            for (source, storage) in sources {
                group.addTask { await (source, storage.fetchBlock(id: blockID)) }
            }
            
            var sourcesLoaded: [String] = []
            
            func progressBarTitle() -> String {
                switch sourcesLoaded.count {
                case sources.count: "fetching sources"
                case sources.count-1: "fetching source \(sources.map(\.0).filter { !sourcesLoaded.contains($0) }.joined(separator: ", "))"
                default: "fetching \(sources.count - sourcesLoaded.count) sources"
                }
            }
            
            do {
                for try await (source, result) in group {
                    progressBar?.stop()
                    sourcesLoaded.append(source)
                    
                    switch result {
                    case .success(let block):
                        guard let output = block.encode(as: format) else { throw FetchError.unableToEncode }
                        if verbose { progressBar?.succeed() }
                        
                        terminal.print((printSource ? "\(source) -> " : "") + output)
                        return
                    case .failure(.notFound):
                        if silent { continue }
                        guard verbose || printSource else { continue }
                        
                        terminal.error("\(source) -> not found")
                        
                        progressBar = terminal.progressBar(title: progressBarTitle(), targetQueue: .main)
                        progressBar?.activity.currentProgress = Double(sourcesLoaded.count) / Double(sources.count)
                        progressBar?.start()
                        
                        continue
                    case .failure(.invalidContent): throw FetchError.contentCorrupted
                    case .failure(.unable): throw FetchError.unable
                    }
                }
            } catch {
                throw (error as? FetchError) ?? FetchError.internalError
            }
        }
    }
}

extension ZeneaFetch {
    public enum FetchError: Error, CustomStringConvertible {
        case unableToLoadSources(LoadSourcesError)
        case sourceNotFound(String)
        case blockNotFound(Block.ID)
        case unableToEncode
        case contentCorrupted
        case unable
        case internalError
        
        public var description: String {
            switch self {
            case .unableToLoadSources(let error): "unable to load sources (\(error.description))"
            case .sourceNotFound(let source): "no source with name \"\(source)\""
            case .blockNotFound(let id): "no block with ID \(id.description)"
            case .unableToEncode: "unable to encode block data"
            case .contentCorrupted: "content is corrupted"
            case .unable: "unknown error (unable)"
            case .internalError: "unknown error (internal error)"
            }
        }
    }
}
