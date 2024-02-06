import ArgumentParser

public struct ZeneaSourcesRemove: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "remove", abstract: "Remove a Zenea block source.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument var source: BlockSource
    
    public func run() async throws {
        var sources = try await loadSources().get()
        
        guard sources.contains(where: { $0 == source }) else { throw RemoveSourcesError.notFound }
        sources.removeAll { $0 == source }
        
        try await writeSources(sources, replace: true).get()
    }
}
