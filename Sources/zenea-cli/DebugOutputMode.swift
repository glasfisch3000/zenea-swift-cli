import ArgumentParser

public enum DebugOutputMode: EnumerableFlag, Hashable, Sendable, Codable {
    case silent
    case normal
    case verbose
    
    public static func name(for value: DebugOutputMode) -> NameSpecification {
        switch value {
        case .silent: .long
        case .normal: .customLong("debug")
        case .verbose: [.short, .long]
        }
    }
    
    public static func help(for value: DebugOutputMode) -> ArgumentHelp? {
        switch value {
        case .silent: "Disable debug output."
        case .normal: "Normal debug output mode."
        case .verbose: "Enable verbose debug output."
        }
    }
}
