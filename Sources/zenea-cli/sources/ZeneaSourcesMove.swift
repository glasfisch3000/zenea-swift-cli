import ArgumentParser

public struct ZeneaSourcesMove: AsyncParsableCommand {
    public init() {}
    
    public static var configuration: CommandConfiguration = .init(commandName: "move", abstract: "Move a Zenea block source up or down the list.", usage: "", discussion: "", version: "", shouldDisplay: true, subcommands: [], defaultSubcommand: nil, helpNames: nil)
    
    @Argument(help: "The name of the source to move.") var name: String
    @Argument(help: "The source's new index, starting at 1.") var newIndex: Int
    
    public func run() async throws {
        var sources = try await loadSources().get()
        
        guard (1...sources.count).contains(newIndex) else { throw MoveSourcesError.indexOutOfBounds }
        guard let index = sources.firstIndex(where: { $0.name == name }) else { throw MoveSourcesError.notFound }
        
        let source = sources.remove(at: index)
        sources.insert(source, at: newIndex-1)
        
        try await writeSources(sources, replace: true).get()
    }
}

public enum MoveSourcesError: Error, CustomStringConvertible {
    case notFound
    case indexOutOfBounds
    
    public var description: String {
        switch self {
        case .notFound: "Unable to locate specified block source."
        case .indexOutOfBounds: "The specified index is not in the list."
        }
    }
}
