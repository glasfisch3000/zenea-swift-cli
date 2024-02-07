import ArgumentParser

import zenea

public struct ZeneaList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "List available Zenea blocks.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Flag(name: [.customShort("s"), .customLong("print-sources")], help: "Show the lists for each block source.") public var printSources = false
    
    public mutating func run() async throws {
        if printSources {
            for await (source, result) in try await blocksList() {
                print(source.name, terminator: " -> ")
                
                switch result {
                case .success(let blocks):
                    print()
                    for block in blocks.sorted(by: { $0.description < $1.description }) {
                        print("    " + block.description)
                    }
                case .failure(.unable): print("Error.")
                }
            }
        } else {
            var results: Set<Block.ID> = []
            
            for await (_, result) in try await blocksList() {
                guard let blocks = try? result.get() else { continue }
                results.formUnion(blocks)
            }
            
            for block in results.sorted(by: { $0.description < $1.description }) {
                print(block.description)
            }
        }
    }
}
