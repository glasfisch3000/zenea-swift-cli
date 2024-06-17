import ArgumentParser

public struct ZeneaSourcesInfo: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "info", abstract: "Get information about a Zenea block source.", usage: nil, discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument var source: String
    
    public func run() async throws {
        let sources = try await loadSources().get()
        
        guard let source = sources.first(where: { $0.name == source }) else { throw GetSourceInfoError.notFound }
        print("name: \(source.name)")
        print("status: \(source.isEnabled ? "enabled" : "disabled")")
        print("location: \(source.location.description)")
    }
}

public enum GetSourceInfoError: Error, CustomStringConvertible {
    case notFound
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        }
    }
}
