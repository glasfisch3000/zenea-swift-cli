import ArgumentParser

public struct ZeneaSources: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "sources", abstract: "Configure Zenea block sources.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [ZeneaSourcesList.self, ZeneaSourcesReset.self, ZeneaSourcesAdd.self, ZeneaSourcesMove.self, ZeneaSourcesRename.self, ZeneaSourcesRemove.self], defaultSubcommand: nil, helpNames: nil)
}
