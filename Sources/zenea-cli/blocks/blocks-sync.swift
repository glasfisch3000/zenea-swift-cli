import Zenea

public enum SyncError: Error, CustomStringConvertible {
    case sourceNotFound
    case sourceDisabled
    case destinationNotFound
    case destinationDisabled
    
    case fetchError(_ error: Block.FetchError)
    case putError(_ error: Block.PutError)
    
    public var description: String {
        switch self {
        case .sourceNotFound: "Unable to locate specified block source."
        case .sourceDisabled: "Block source is disabled."
        case .destinationNotFound: "Unable to locate specified block destination."
        case .destinationDisabled: "Block destination is disabled."
        case .fetchError(.invalidContent), .fetchError(.unable): "Internal error at source."
        case .fetchError(.notFound): "Specified block not found at source."
        case .putError(.overflow): "Block is too large."
        case .putError(.exists): "Block already exists at destination."
        case .putError(.notPermitted): "Not permitted to put block at destination."
        case .putError(.unavailable): "Destination not available."
        case .putError(.unable): "Destination unable to put block."
        }
    }
}
