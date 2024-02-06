import NIOFileSystem
import Foundation

public let zeneaFiles = Files(path: FilePath(NSString("~/.zenea").expandingTildeInPath as String))

public struct Files {
    public var path: FilePath
    
    public var config: ConfigFiles { .init(path: path.appending("config")) }
}

public struct ConfigFiles {
    public var path: FilePath
    
    public var sources: FilePath { path.appending("sources.json") }
}
