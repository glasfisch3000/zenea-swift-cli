import ArgumentParser

public struct ZeneaSourcesAdd: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "add", abstract: "Add a Zenea block source.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument var source: BlockSource
    
    public func run() async throws {
        var sources: [BlockSource]
        do {
            sources = try await loadSources().get()
        } catch let error as LoadSourcesError where error == .missing {
            sources = []
        }
        
        sources.append(source)
        
        try await writeSources(sources, replace: true).get()
    }
}
