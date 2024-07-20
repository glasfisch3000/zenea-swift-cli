import ArgumentParser

public struct ZeneaSourcesEnable: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "enable",
        abstract: "Enable or disable a Zenea block source.",
        usage: nil,
        discussion: "",
        version: "1.0.0",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
    
    @Argument var source: String
    @Option(name: [.customLong("enabled", withSingleDash: true)]) var enabled: Bool = true
    
    public func run() async throws {
        var sources = try await loadSources().get()
        
        guard let index = sources.firstIndex(where: { $0.name == self.source }) else { throw EnableSourceError.notFound }
        sources[index].isEnabled = self.enabled
        
        try await writeSources(sources, replace: true).get()
    }
}

public struct ZeneaSourcesDisable: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(
        commandName: "disable",
        abstract: "Disable a Zenea block source.",
        usage: "", 
        discussion: "",
        version: "",
        shouldDisplay: true,
        subcommands: [],
        defaultSubcommand: nil,
        helpNames: nil,
        aliases: []
    )
    
    @Argument var source: String
    
    public func run() async throws {
        var sources = try await loadSources().get()
        
        guard let index = sources.firstIndex(where: { $0.name == self.source }) else { throw EnableSourceError.notFound }
        sources[index].isEnabled = false
        
        try await writeSources(sources, replace: true).get()
    }
}

public enum EnableSourceError: Error, CustomStringConvertible {
    case notFound
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        }
    }
}
