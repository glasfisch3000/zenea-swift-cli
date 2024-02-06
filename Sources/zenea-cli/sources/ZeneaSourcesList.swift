import ArgumentParser

public struct ZeneaSourcesList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "A Tool for listing available Zenea sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public func run() async throws {
        let sources = try await listSources().get()
        
        for source in sources {
            print(source.description)
        }
    }
}
