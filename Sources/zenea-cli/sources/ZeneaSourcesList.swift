import ArgumentParser

public struct ZeneaSourcesList: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "list", abstract: "List all Zenea block sources.", usage: nil, discussion: "", version: "1.0.0", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    public func run() async throws {
        let sources = try await loadSources().get()
        
        var i = 1
        for source in sources {
            print("\(i). \(source.name) [\(source.isEnabled ? "enabled" : "disabled")]: \(source.location.description)")
            i += 1
        }
    }
}
