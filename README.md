# About zenea-swift-cli

A swift client command line interface for interacting with Zenea Project Data Layer block storage systems.

Built with [swift-argument-parser](https://github.com/apple/swift-argument-parser) on top of [Zenea Project](https://github.com/zenea-project)'s zenea and valya libraries.
Utilises [async-http-client](https://github.com/swift-server/async-http-client) for communicating with web interfaces as well as [swift-nio's](https://github.com/apple/swift-nio) `NIOFileSystem` for local data storage.

# How to Use

If you haven't already, download the latest version of Swift, but at least version 5.9.2. On macOS, the recommended way to do this is by downloading the Xcode app. On Linux, you'll want to use [swiftly](https://github.com/swift-server/swiftly).

In the directory that this README file is in, run `swift build`. This fetches all dependencies and builds an executable product.
Once the process is done, you can find that product by running `swift build --show-bin-path`, which will output a directory. The executable named "zenea-cli" should be in that directory.

Move the file out of the bin directory and rename it to "zenea".
You can choose any path you want for executing the file, however it might be useful to move it (or a link) to somewhere like `/usr/bin/`.

NOTE: This package may not work on systems that do not provide an adequate `Foundation` library. In any recent release of macOS, this should not be a problem. However, on Linux systems you might be using an older version of the library or it might be missing entirely. Apple is currently working on making an [open-source swift version](https://github.com/apple/swift-foundation) of that package that can be used as a dependency on all systems, but as it is still in an early stage, you could run into problems compiling this package.

## Functions and Subcommands

### Help
- show general help information: `zenea -h`
- show help information about a subcommand: `zenea help <subcommand>`

### Blocks
Blocks can be encoded or decoded in one of three formats: `raw`, `hex` and `base64`. The default value is `raw`.

- list blocks available for download: `zenea list [--print-sources] [--sort]`
- check a block's availability: `zenea check <block-id>`
- print a block's contents: `zenea fetch [-f <format>] [--print-source] <block-id>`
- download a block's contents to the file system, valya-decompressing if possible: `zenea download <block-id> <destination-file>`
- put data into a block: `zenea put [-f <format>] <block-content>`
- upload a block from file, valya-compressing if needed: `zenea upload <source-file>`
- synchronise a block from one source to another: `zenea sync [-s <source>] <block> <destination>`

### Block Sources
- list available block sources: `zenea sources list`
- get info about a block source: `zenea sources info <name>`
- add block source: `zenea sources add <name> <location>`
- rename a block source: `zenea sources rename <old-name> <new-name>`
- enable/disable a block source: `zenea sources enable [--enabled <bool>] <name>` or `zenea sources disable <name>`
- move a block source up or down the list: `zenea sources move <name> <new-index>`
- remove block source: `zenea sources remove <name>`
- reset/initialise block sources: `zenea sources reset`
