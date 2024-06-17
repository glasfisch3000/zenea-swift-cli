import ArgumentParser
import AsyncHTTPClient
import Zenea

public struct ZeneaList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "List available Zenea blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Flag(name: [.customShort("s"), .customLong("print-sources")], help: "Show the lists for each block source.") public var printSources = false
    @Flag(name: [.customShort("S"), .customLong("sort")], help: "List the blocks in a sorted order.") public var sortBlocks: Bool = false
    
    public mutating func run() async throws {
        let client = HTTPClient(eventLoopGroupProvider: .singleton)
        defer { try? client.shutdown().wait() }
        
        if printSources {
            if sortBlocks { try await printSortedBySource(client: client) }
            else { try await printUnsortedBySource(client: client) }
        } else {
            if sortBlocks { try await printSorted(client: client) }
            else { try await printUnsorted(client: client) }
        }
    }
    
    func printSorted(client: HTTPClient) async throws {
        let sources = try await loadSources().get()
        let storages = sources.filter(\.isEnabled).map { $0.makeStorage(client: client) }
        
        var results: Set<Block.ID> = []
        
        for storage in storages {
            do {
                let list = try await storage.listBlocks().get()
                results.formUnion(list)
            } catch {
                print("Error: \(error)")
                continue
            }
        }
        
        for block in results.sorted(by: { $0.description < $1.description }) {
            print(block.description)
        }
    }
    
    func printUnsorted(client: HTTPClient) async throws {
        let sources = try await loadSources().get()
        let storages = sources.filter(\.isEnabled).map { $0.makeStorage(client: client) }
        
        var errors: [Error] = []
        
        for storage in storages {
            do {
                for blockID in try await storage.listBlocks().get() {
                    print(blockID.description)
                }
            } catch {
                errors += [error]
                continue
            }
        }
        
        for error in errors {
            print(error)
        }
    }
    
    func printSortedBySource(client: HTTPClient) async throws {
        let sources = try await loadSources().get()
        for source in sources.filter(\.isEnabled) {
            print(source.name, terminator: " ->")
            
            do {
                let storage = source.makeStorage(client: client)
                let list = try await storage.listBlocks().get()
                
                if list.isEmpty {
                    print(" None")
                } else {
                    print()
                    for block in list {
                        print("    " + block.description)
                    }
                }
            } catch {
                print(" Error: \(error)")
            }
        }
    }
    
    func printUnsortedBySource(client: HTTPClient) async throws {
        let sources = try await loadSources().get()
        for source in sources.filter(\.isEnabled) {
            print(source.name, terminator: " ->")
            
            do {
                let storage = source.makeStorage(client: client)
                let list = try await storage.listBlocks().get()
                
                if list.isEmpty {
                    print(" None")
                } else {
                    print()
                    for block in list.sorted(by: { $0.description < $1.description }) {
                        print("    " + block.description)
                    }
                }
            } catch {
                print(" Error: \(error)")
            }
        }
    }
}

enum CustomError: String, Error, CustomStringConvertible {
    case lol = "custom error message"
    
    var description: String {
        self.rawValue
    }
}
