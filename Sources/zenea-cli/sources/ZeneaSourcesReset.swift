import ArgumentParser
import Foundation

public struct ZeneaSourcesReset: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "reset", abstract: "Reset the Zenea block sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public func run() async throws {
        let sources: [BlockSource] = [.file(path: zeneaFiles.path.string)]
        try await writeSources(sources, replace: true).get()
    }
}
