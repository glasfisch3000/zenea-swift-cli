import ArgumentParser

public struct ZeneaSources: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "sources", abstract: "A Tool for configuring Zenea sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [ZeneaSourcesList.self], defaultSubcommand: nil, helpNames: nil)
}
