import ArgumentParser
import AsyncHTTPClient
import ConsoleKit
import Zenea

public struct ZeneaCheck: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "check",
        abstract: "Check availability of Zenea blocks.",
        usage: nil,
        discussion: "",
        version: "2.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: [] 
    )
    
    @ArgumentParser.Option(name: [.customShort("S"), .long]) public var source: String?
    @ArgumentParser.Flag(exclusivity: .chooseLast) public var debugOutputMode: DebugOutputMode = .normal
    
    @ArgumentParser.Argument public var blockID: Block.ID
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.syncShutdown() }
        
        if let source = source {
            try await checkSingleSource(source, client: client)
        } else {
            try await checkAllSources(client: client)
        }
    }
    
    public func checkSingleSource(_ source: String, client: HTTPClient) async throws {
        let silent = debugOutputMode == .silent
        let verbose = debugOutputMode == .verbose
        
        let terminal = Terminal()
        var bar = !silent ? terminal.loadingBar(title: "loading sources", targetQueue: .main) : nil
        bar?.start()
        
        do {
            let (source, storage) = switch await loadSources() {
            case .success(let sources):
                if let source = sources.first(where: { $0.name == source }) {
                    (source, source.makeStorage(client: client))
                } else {
                    throw CheckError.sourceNotFound(source)
                }
            case .failure(let error): throw CheckError.unableToLoadSources(error)
            }
            
            if verbose {
                bar?.succeed()
                
                bar = !silent ? terminal.loadingBar(title: "checking source \(source.name)", targetQueue: .main) : nil
                bar?.start()
            } else {
                bar?.activity.title = "checking source \(source.name)"
            }
            
            let result = await storage.checkBlock(id: blockID)
            bar?.stop()
            
            switch result {
            case .success(true):
                if verbose { bar?.succeed() }
                terminal.print("available")
            case .success(false):
                if verbose { bar?.succeed() }
                terminal.print("not available")
            case .failure(let error):
                throw switch error {
                case .unable: CheckError.unable
                }
            }
        } catch {
            bar?.fail()
            
            if silent {
                terminal.print("failed to check block at \(source): \((error as CustomStringConvertible).description)")
            } else {
                terminal.error("failed to check block at \(source): \((error as CustomStringConvertible).description)")
            }
            throw error
        }
    }
    
    public func checkAllSources(client: HTTPClient) async throws {
        let silent = debugOutputMode == .silent
        let verbose = debugOutputMode == .verbose
        let blockID = blockID
        
        let terminal = Terminal()
        let loadingBar = !silent ? terminal.loadingBar(title: "loading sources", targetQueue: .main) : nil
        loadingBar?.start()
        
        let sources = switch await loadSources() {
        case .success(let sources): sources.filter(\.isEnabled).map { ($0.name, $0.makeStorage(client: client)) }
        case .failure(let error): 
            let error = CheckError.unableToLoadSources(error)
            loadingBar?.fail()
            
            if silent {
                terminal.print("failed to check block: \(error.description)")
            } else {
                terminal.error("failed to check block: \(error.description)")
            }
            throw error
        }
        
        if verbose {
            loadingBar?.succeed()
        } else {
            loadingBar?.stop()
        }
        
        var progressBar = !silent ? terminal.progressBar(title: "checking sources", targetQueue: .main) : nil
        progressBar?.start()
        
        try await withThrowingTaskGroup(of: (String, Result<Bool, Block.CheckError>).self) { group in
            for (source, storage) in sources {
                group.addTask { await (source, storage.checkBlock(id: blockID)) }
            }
            
            var sourcesLoaded: [String] = []
            var errors = false
            
            func progressBarTitle() -> String {
                switch sourcesLoaded.count {
                case sources.count: "checking sources"
                case sources.count-1: "checking source \(sources.map(\.0).filter { !sourcesLoaded.contains($0) }.joined(separator: ", "))"
                default: "checking \(sources.count - sourcesLoaded.count) sources"
                }
            }
            
            do {
                for try await (source, result) in group {
                    progressBar?.stop()
                    sourcesLoaded.append(source)
                    
                    switch result {
                    case .success(true): terminal.print("\(source) -> available")
                    case .success(false): terminal.print("\(source) -> not available")
                    case .failure(let error):
                        let message = switch error {
                        case .unable: "unknown error (unable)"
                        }
                        
                        if verbose {
                            terminal.print("\(source) -> failed to check block: \(message)")
                        } else {
                            terminal.error("\(source) -> failed to check block: \(message)")
                        }
                        errors = true
                    }
                    
                    progressBar = !silent ? terminal.progressBar(title: progressBarTitle(), targetQueue: .main) : nil
                    progressBar?.activity.currentProgress = Double(sourcesLoaded.count) / Double(sources.count)
                    progressBar?.start()
                }
                
                if errors {
                    progressBar?.fail()
                } else if verbose {
                    progressBar?.succeed()
                } else {
                    progressBar?.stop()
                }
            } catch {
                let error = CheckError.internalError
                progressBar?.fail()
                
                if silent {
                    terminal.print("failed to check block: \(error.description)")
                } else {
                    terminal.error("failed to check block: \(error.description)")
                }
                throw error
            }
        }
    }
}

extension ZeneaCheck {
    public enum CheckError: Error, CustomStringConvertible {
        case unableToLoadSources(LoadSourcesError)
        case sourceNotFound(String)
        case unable
        case internalError
        
        public var description: String {
            switch self {
            case .unableToLoadSources(let error): "unable to load sources (\(error.description))"
            case .sourceNotFound(let string): "no source with name \"\(string)\""
            case .unable: "unknown error (unable)"
            case .internalError: "unknown error (internal error)"
            }
        }
    }
}
