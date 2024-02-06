# About zenea-swift-cli

A swift client command line interface for interacting with Zenea Project Data Layer block storage systems.

Built on [swift-argument-parser](https://github.com/apple/swift-argument-parser) and [zenea-swift](https://github.com/glasfisch3000/zenea-swift).
Utilises [async-http-client](https://github.com/swift-server/async-http-client) as well as [swift-nio's](https://github.com/apple/swift-nio) `NIOFileSystem`.

# How to Use

If you haven't already, download the latest version of Swift, but at least version 5.9.2. On macOS, the recommended way to do this is by downloading the Xcode app. On Linux, you'll want to use [swiftly](https://github.com/swift-server/swiftly).

In the directory that this README file is in, run `swift build`. This fetches all dependencies and builds an executable product.
Once the process is done, you can find that product by running `swift build --show-bin-path`, which will output a directory. The executable named "zenea-cli" should be in that directory.

Move the file out of the bin directory and rename it to "zenea".
You can shoose any path you want for executing the file, however it might be useful to move it (or a link) to somewhere like `/usr/bin/`.

NOTE: This package may not work on systems that do not provide an adequate `Foundation` library. In any recent release of macOS, this should not be a problem. However, on Linux systems you might be using an older version of the library or it might be missing entirely. Apple is currently working on making an [open-source swift version](https://github.com/apple/swift-foundation) of that package that can be used as a dependency on all systems, but as it is still in an early stage, you could run into problems compiling this package.

## Functions and Subcommands

### Help
- show general help information: `zenea -h`
- show help information about a subcommand: `zenea help <subcommand>`

### Blocks
Blocks can be encoded or decoded in one of three formats: `raw`, `hex` and `base64`. The default value is `raw`.

- list blocks available for download: `zenea list`
- download a block: `zenea fetch [-f <format>] <block-id>`
- upload a block: `zenea put [-f <format>] <block-content>`

### Block Sources
- list available block sources: `zenea sources list`
- reset/initialise block sources: `zenea sources reset`
- add block source: `zenea sources add <source>`
- remove block source: `zenea sources remove <source>`
