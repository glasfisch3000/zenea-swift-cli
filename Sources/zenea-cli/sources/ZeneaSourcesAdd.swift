import ArgumentParser

public struct ZeneaSourcesAdd: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "add", abstract: "Add a Zenea block source.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument(help: "The source's identifier.") var name: String
    @Argument(help: "The source's location.") var location: BlockSource.SourceLocation
    
    public func run() async throws {
        var sources: [BlockSource]
        do {
            sources = try await loadSources().get()
        } catch let error as LoadSourcesError where error == .missing {
            sources = []
        }
        
        if sources.contains(where: { $0.name == self.name }) { throw AddSourcesError.nameExists }
        if sources.contains(where: { $0.location == self.location }) { throw AddSourcesError.exists }
        sources.append(BlockSource(name: self.name, location: self.location))
        
        try await writeSources(sources, replace: true).get()
    }
}
