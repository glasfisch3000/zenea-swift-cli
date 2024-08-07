import ArgumentParser

public struct ZeneaSourcesReset: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "reset",
        abstract: "Reset the Zenea block sources.",
        usage: nil,
        discussion: "",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
    
    public func run() async throws {
        let sources: [BlockSource] = [BlockSource(name: "home", location: .file(path: zeneaFiles.path.string))]
        try await writeSources(sources, replace: true).get()
    }
}
