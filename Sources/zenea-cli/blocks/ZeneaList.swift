import Foundation
import ArgumentParser
import AsyncHTTPClient
import ConsoleKit
import Zenea

public struct ZeneaList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "list",
        abstract: "List available Zenea blocks.",
        usage: nil,
        discussion: "", 
        version: "2.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: ["ls"]
    )
    
    @ArgumentParser.Flag(name: [.customShort("s"), .customLong("print-sources")], help: "Show the lists for each block source.") public var printSources = false
    
    @ArgumentParser.Flag(exclusivity: .chooseLast) public var debugOutputMode: DebugOutputMode = .normal
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.syncShutdown() }
        
        try await printBlocks(client: client)
    }
    
    public func printBlocks(client: HTTPClient) async throws {
        let silent = debugOutputMode == .silent
        let verbose = debugOutputMode == .verbose
        
        let terminal = Terminal()
        var progressBar = !silent ? terminal.progressBar(title: "loading block sources", targetQueue: .main) : nil
        progressBar?.start()
        
        do {
            let sources = try await loadSources().get().filter { $0.isEnabled }.map { ($0, $0.makeStorage(client: client)) }
            
            try await withThrowingTaskGroup(of: (String, Result<Set<Block.ID>, Block.ListError>).self) { group in
                for (source, storage) in sources {
                    group.addTask { (source.name, await storage.listBlocks()) }
                }
                
                var sourcesLoaded: [String] = []
                var errors: [(String, Block.ListError)] = []
                
                func progressBarTitle() -> String {
                    switch sourcesLoaded.count {
                    case sources.count: "loading blocks"
                    case sources.count-1: "loading blocks from \(sources.filter { !sourcesLoaded.contains($0.0.name) }.map(\.0.name).joined(separator: ", "))"
                    default: "loading blocks from \(sources.count - sourcesLoaded.count) sources"
                    }
                }
                
                if printSources {
                    for try await (source, result) in group {
                        sourcesLoaded.append(source)
                        progressBar?.activity.title = progressBarTitle()
                        progressBar?.activity.currentProgress = Double(sourcesLoaded.count) / Double(sources.count)
                        
                        progressBar?.stop()
                        
                        switch result {
                        case .success(let set):
                            terminal.print("\(source):")
                            for block in set.sorted(by: { $0.description < $1.description }) {
                                terminal.print("    " + block.description)
                            }
                        case .failure(let error):
                            errors.append((source, error))
                            
                            let message = switch error {
                            case .unable: "unknown error (unable)"
                            }
                            
                            terminal.print("\(source):")
                            
                            if silent {
                                terminal.print("     failed to load blocks from \(source): \(message)")
                            } else {
                                terminal.error("     failed to load blocks from \(source): \(message)")
                            }
                        }
                        
                        progressBar = !silent ? terminal.progressBar(title: progressBarTitle(), targetQueue: .main) : nil
                        progressBar?.activity.currentProgress = Double(sourcesLoaded.count) / Double(sources.count)
                        progressBar?.start()
                    }
                    
                    if !errors.isEmpty {
                        progressBar?.fail()
                    } else if verbose {
                        progressBar?.succeed()
                    } else {
                        progressBar?.stop()
                    }
                } else {
                    var list: [String] = []
                    
                    for try await (source, result) in group {
                        sourcesLoaded.append(source)
                        progressBar?.activity.title = progressBarTitle()
                        progressBar?.activity.currentProgress = Double(sourcesLoaded.count) / Double(sources.count)
                        
                        switch result {
                        case .success(let set): list += set.map(\.description)
                        case .failure(let error): errors.append((source, error))
                        }
                    }
                    
                    progressBar?.stop()
                    var last: String? = nil
                    for blockID in list.sorted() {
                        guard blockID != last else { continue }
                        terminal.print(blockID)
                        last = blockID
                    }
                    
                    if errors.isEmpty {
                        if verbose { progressBar?.succeed() }
                    } else {
                        for (source, error) in errors {
                            let message = switch error {
                            case .unable: "unknown error (unable)"
                            }
                            
                            if silent {
                                terminal.print("failed to load blocks from \(source): \(message)")
                            } else {
                                terminal.error("failed to load blocks from \(source): \(message)")
                            }
                        }
                        progressBar?.fail()
                    }
                }
            }
        } catch {
            progressBar?.fail()
            throw error
        }
    }
}
