import ArgumentParser
import Zenea

extension Block.ID: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(parsing: argument)
    }
}
