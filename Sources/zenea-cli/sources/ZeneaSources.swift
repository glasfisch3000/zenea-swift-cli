import ArgumentParser

public struct ZeneaSources: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "sources",
        abstract: "Configure Zenea block sources.",
        usage: nil,
        discussion: "",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [ZeneaSourcesList.self, ZeneaSourcesInfo.self, ZeneaSourcesAdd.self, ZeneaSourcesRename.self, ZeneaSourcesEnable.self, ZeneaSourcesDisable.self, ZeneaSourcesMove.self, ZeneaSourcesRemove.self, ZeneaSourcesReset.self],
        defaultSubcommand: nil,
        helpNames: nil
    )
}
