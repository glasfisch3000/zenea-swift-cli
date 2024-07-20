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
    
    @ArgumentParser.Option(name: [.customShort("S"), .long]) var source: String?
    @ArgumentParser.Flag(exclusivity: .chooseLast) var debugOutputMode: DebugOutputMode = .normal
    
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
        
        let storage = switch await loadSources() {
        case .success(let sources):
            if let storage = sources
                .first(where: { $0.name == source })?
                .makeStorage(client: client) {
                storage
            } else {
                bar?.fail()
                throw CheckError.sourceNotFound(source)
            }
        case .failure(let error):
            bar?.fail()
            throw error
        }
        
        if verbose {
            bar?.succeed()
            
            bar = !silent ? terminal.loadingBar(title: "checking source \(source)", targetQueue: .main) : nil
            bar?.start()
        } else {
            bar?.activity.title = "checking source \(source)"
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
            bar?.fail()
            
            let message = switch error {
            case .unable: "unknown error (unable)"
            }
            
            if silent {
                terminal.print("failed to check block at \(source): \(message)")
            } else {
                terminal.error("failed to check block at \(source): \(message)")
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
            loadingBar?.fail()
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
                progressBar?.fail()
                throw error
            }
        }
    }
}

extension ZeneaCheck {
    public enum CheckError: Error, CustomStringConvertible {
        case sourceNotFound(String)
        
        public var description: String {
            switch self {
            case .sourceNotFound(let string): "Unable to locate source with name \"\(string)\""
            }
        }
    }
}
