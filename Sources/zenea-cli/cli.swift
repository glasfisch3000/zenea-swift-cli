import ArgumentParser

@main
struct ZeneaCLI: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "zenea", abstract: "A CLI for the Zenea Project Data Layer.", usage: "", discussion: "", version: "0.0.0", shouldDisplay: true, subcommands: [ZeneaList.self, ZeneaFetch.self, ZeneaPut.self], defaultSubcommand: nil, helpNames: nil)
}
