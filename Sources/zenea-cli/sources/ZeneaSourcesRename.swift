import ArgumentParser

public struct ZeneaSourcesRename: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "rename", abstract: "Rename a Zenea block source.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument var oldName: String
    @Argument var newName: String
    
    public func run() async throws {
        var sources = try await loadSources().get()
        
        if sources.contains(where: { $0.name == newName }) { throw RenameSourcesError.nameExists }
        
        var renamed = false
        for i in sources.indices {
            let source = sources[i]
            guard source.name == oldName else { continue }
            
            renamed = true
            sources[i].name = newName
        }
        
        guard renamed else { throw RenameSourcesError.notFound }
        
        try await writeSources(sources, replace: true).get()
    }
}

public enum RenameSourcesError: Error, CustomStringConvertible {
    case notFound
    case nameExists
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        case .nameExists: "A source with the specified identifier already exists."
        }
    }
}
