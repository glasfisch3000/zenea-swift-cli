import ArgumentParser
import Foundation

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
    
    public init?(decoding string: String, as format: Block.DataFormat) {
        switch format {
        case .raw:
            guard let data = string.data(using: .utf8) else { return nil }
            self.init(content: data)
        case .hex:
            guard let data = Data(hexString: string) else { return nil }
            self.init(content: data)
        case .base64:
            guard let data = Data(base64Encoded: string) else { return nil }
            self.init(content: data)
        }
    }
}

extension Block.ID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
