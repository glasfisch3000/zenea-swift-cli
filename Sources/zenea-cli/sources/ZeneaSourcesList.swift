import ArgumentParser

public struct ZeneaSourcesList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "List available Zenea block sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public func run() async throws {
        let sources = try await loadSources().get()
        
        for source in sources {
            print(source.description)
        }
    }
}
