import ArgumentParser

@main
struct ZeneaCLI: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "zenea",
        abstract: "A CLI for the Zenea Project Data Layer.",
        usage: nil,
        discussion: "",
        version: "1.0.1",
        shouldDisplay: true,
        subcommands: [ZeneaList.self, ZeneaCheck.self, ZeneaFetch.self, ZeneaPut.self, ZeneaSync.self, ZeneaDownload.self, ZeneaUpload.self, ZeneaSources.self],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
}
