import ArgumentParser

@main
struct ZeneaCLI: AsyncParsableCommand {
    static var configuration: CommandConfiguration = .init(commandName: "zenea", abstract: "A CLI for the Zenea Project Data Layer.", usage: "", discussion: "", version: "0.0.0", shouldDisplay: true, subcommands: [ZeneaList.self, ZeneaCheck.self, ZeneaFetch.self, ZeneaPut.self, ZeneaSync.self, ZeneaDownload.self, ZeneaUpload.self, ZeneaSources.self], defaultSubcommand: nil, helpNames: nil)
    
    func run() async throws {
        var cmd = ZeneaList()
        cmd.printSources = true
        try await cmd.run()
    }
}
