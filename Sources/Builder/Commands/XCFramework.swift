//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility

struct XCFramework: AwaitingParsableCommand {
    
    @Option(help: "The output directory of generated XCFrameworks.")
    var output: String?
    
    @Flag(wrappedValue: false, help: "Use this flag to force rebuild OpenSSL and TON libraries.")
    var clean: Bool
    
    static var configuration = CommandConfiguration(
        commandName: "xcframework",
        abstract: "Builds TON (if not builded), OpenSSL (if not builded) and generates XCFrameworks for Apple devices."
    )
    
    mutating func run() async throws {
        let fileManager = FileManager.default
        
        let outputURL: Foundation.URL
        if let output = output {
            outputURL = Foundation.URL(fileURLWithPath: output.stringByExpandingPathInCurrentDirectory)
            if clean {
                try? fileManager.removeItem(at: outputURL)
            }
        } else {
            outputURL = try fileManager.cacheURL(withPath: "/xcframeworks", createIfNeeded: true)
            try? fileManager.removeItem(at: outputURL)
        }
        
        if fileManager.directoryExists(atPath: outputURL.relativePath) {
            guard (try fileManager.contentsOfDirectory(atPath: outputURL.relativePath)).isEmpty
            else {
                throw CommonError.directoryNotEmpty(url: outputURL)
            }
        } else {
            try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        stdout(
            """
            Start XCFramework build.
            Output directry: \(outputURL.relativePath)
            """
        )
        
        let libraries: [BuildLibrary] = [.openssl, .ton]
        for library in libraries {
            try await xcframework(
                library,
                outputDirectoryURL: outputURL
            )
        }
        
        stdout(
            """
            Done! Did crete XCFrameworks.
            Output directory: \(outputURL.relativePath)
            """
        )
    }
    
    private func xcframework(
        _ library: BuildLibrary,
        outputDirectoryURL: Foundation.URL
    ) async throws {
        let buildedLibrariesURL = try library.outputURL()
        
        if !(try library.buildExists()) || clean {
            var command = try library.buildCommand().parse([])
            try await command.run()
        } else {
            let url = try library.outputURL()
            stdout("Using previously builded library: \(url.relativePath)", newlines: false)
        }
        
        let platforms = BuildPlatform.targets
        var arguments = [String]()
        
        platforms.forEach({ platform in
            let platfromLibraryDirectoryURL = buildedLibrariesURL.appendingPathComponent(platform.buildURLPathComponent())
            let platfromLibraryURL = platfromLibraryDirectoryURL.appendingPathComponent("lib/\(library.libraryName)")
            let platfromIncludeURL = platfromLibraryDirectoryURL.appendingPathComponent("include")
            arguments.append("-library \(platfromLibraryURL.relativePath) -headers \(platfromIncludeURL.relativePath)")
        })
        
        try execute(
            """
            xcodebuild -create-xcframework \(arguments.joined(separator: " ")) -output \(outputDirectoryURL.relativePath)/\(library.xcframeworkName)
            """,
            workingDirectory: outputDirectoryURL
        )
    }
}
