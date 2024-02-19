import zenea

public enum SyncError: Error, CustomStringConvertible {
    case sourceNotFound
    case destinationNotFound
    
    case fetchError(_ error: BlockFetchError)
    case putError(_ error: BlockPutError)
    
    public var description: String {
        switch self {
        case .sourceNotFound: "Unable to locate specified block source."
        case .destinationNotFound: "Unable to locate specified block destination."
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
