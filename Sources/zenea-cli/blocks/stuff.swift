import ArgumentParser
import zenea

extension Block {
    public enum DataFormat: String, ExpressibleByArgument {
        case raw
        case hex
        case base64
    }
    
    public func encode(as format: Block.DataFormat) -> String? {
        switch format {
        case .raw:
            guard let string = String(data: self.content, encoding: .utf8) else { return nil }
            return string
        case .hex:
            return self.content.toHexString()
        case .base64:
            return self.content.base64EncodedString()
        }
    }
}

extension Block.ID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
