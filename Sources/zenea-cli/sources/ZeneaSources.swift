import ArgumentParser

public struct ZeneaSources: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "sources", abstract: "Configure Zenea block sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [ZeneaSourcesList.self], defaultSubcommand: nil, helpNames: nil)
}