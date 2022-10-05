//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility

struct OpenSSL: AwaitingParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "openssl",
        abstract: "Builds OpenSSL for Apple devices."
    )
    
    @Option(wrappedValue: "1.1.1i", help: "The version of OpenSSL library (1.1.1i or another).")
    var version: String
    
    @Option(wrappedValue: BuildPlatform.targets, help: "Specify build targets. Target list: \(BuildPlatform.targets.map { $0.rawValue })")
    var targets: [BuildPlatform]
    
    @Flag(wrappedValue: false, help: "Enables enable-ec_nistp_64_gcc_128 for arm64 builds.")
    var nistp64gcc128: Bool
    
    mutating func run() async throws {
        let fileManager = FileManager.default
        
        let buildURL = try fileManager.cacheURL(withPath: "/build/openssl", createIfNeeded: true)
        let sourceURL = try fileManager.cacheURL(withPath: "/build/openssl/source", createIfNeeded: true)
        let outputURL = try BuildLibrary.openssl.outputURL(createIfNeeded: true)
        
        let archiveURL = try await downloadArchiveIfNeeded(version)
        try unpackArchiveIfNeeded(from: archiveURL, to: sourceURL)
        
        stdout(
            """
            OpenSSL: \(version).
            Build directry: \(buildURL.relativePath)
            Source direcotry: \(sourceURL.relativePath)
            Out directory: \(outputURL.relativePath)
            """
        )
        
        let configurationsURL = buildURL.appendingPathComponent("configurations")
        try fileManager.createDirectory(at: configurationsURL, withIntermediateDirectories: true, attributes: nil)
        try Resource.openSSLPlatforms.write(into: configurationsURL)
        
        for platform in BuildPlatform.targets {
            if !targets.contains(platform) && platform != .macOS { continue }
            
            try await build(
                for: platform,
                configurationsURL: configurationsURL,
                sourceURL: sourceURL,
                to: outputURL
            )
        }
        
        stdout(
            """
            Done! Did build OpenSSL: \(version).
            Output directory: \(outputURL.relativePath)
            """
        )
    }
    
    private func downloadArchiveIfNeeded(_ version: String) async throws -> Foundation.URL {
        let fileManager = FileManager.default
        
        let downloadsURL = try fileManager.cacheURL(withPath: "/downloads", createIfNeeded: true)
        let archiveName = "openssl-\(version).tar.gz"
        
        let localURL = downloadsURL.appendingPathComponent(archiveName)
        guard !fileManager.fileExists(atPath: localURL.relativePath)
        else {
            stdout("Did found cached OpenSSL archive: \(localURL.relativePath).")
            return localURL
        }
        
        let downloadURLString = "https://www.openssl.org/source/\(archiveName)"
        guard let url = URL(string: downloadURLString)
        else {
            throw URLError.cantCreateURLFromString(string: downloadURLString)
        }
        
        stdout("Start downloading OpenSSL archive: \(url.relativePath).")
        
        let downloader = Downloader(url: url, header: "Downloading OpenSSL...")
        try await downloader.download(to: localURL)
        
        return localURL
    }
    
    private func unpackArchiveIfNeeded(from: Foundation.URL, to: Foundation.URL) throws {
        let fileManager = FileManager.default
        let arguments = ["tar", "-zxf", from.relativePath]
        
        guard from.lastPathComponent.hasSuffix(".tar.gz")
        else {
            throw URLError.notAnArchiveURL(url: from)
        }
        
        var name = from.lastPathComponent
        name.removeLast(7)
        
        let process = Process(
            arguments: arguments,
            workingDirectory: AbsolutePath(from.deletingLastPathComponent().relativePath)
        )
        try process.launch()
        
        let result = try process.waitUntilExit()
        
        switch result.output {
        case let .failure(error):
            throw error
        case .success:
            break
        }
        
        try? fileManager.removeItem(at: to)
        let unarhivedURL = from.deletingLastPathComponent().appendingPathComponent(name)
        
        try fileManager.moveItem(at: unarhivedURL, to: to)
    }
    
    private func build(
        for platform: BuildPlatform,
        configurationsURL: Foundation.URL,
        sourceURL: Foundation.URL,
        to: Foundation.URL
    ) async throws {
        let fileManager = FileManager.default
        let platfromURL = to.appendingPathComponent(platform.buildURLPathComponent())
        
        let developerPath = try shell(["xcode-select", "-print-path"])
        guard !developerPath.isEmpty
        else {
            throw OpenSSLError.developerPathNotSet
        }
        
        let threads = try shell(["sysctl", "hw.ncpu"]).components(separatedBy: " ")[1]
        let currentSDKVersion = try platform.currentSDKVersion()
        
        let environment = [
            "CROSS_COMPILE" : "\(developerPath)/Toolchains/XcodeDefault.xctoolchain/usr/bin/",
            "CROSS_TOP" : "\(developerPath)/Platforms/\(platform.applePlatform()).platform/Developer",
            "CROSS_SDK" : "\(platform.applePlatform())\(currentSDKVersion).sdk",
            "MIN_SDK_VERSION": "\(platform.minimumSDKVersion())",
            "OPENSSL_LOCAL_CONFIG_DIR" : configurationsURL.relativePath,
        ]
        
        stdout(
            """
            Start building OpenSSL for platrom: \(platform.rawValue)
            Destination URL: \(platfromURL.relativePath)
            """
        )
        
        //
        // Build all OpenSSL targtes for given platform
        //
        
        var archBuildURLs: [Foundation.URL] = []
        
        try platform.openSSLTargets.forEach({ openSSLTarget in
            guard let arch = openSSLTarget.components(separatedBy: "-").last
            else {
                throw OpenSSLError.undefinedArchInTarget(target: openSSLTarget)
            }
            
            // Cleanup build arch direcotry if needed
            let archURL = Foundation.URL(fileURLWithPath: "\(platfromURL.relativePath)-\(arch)")
            try? fileManager.removeItem(at: archURL)
            try fileManager.createDirectory(
                at: archURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            // Create local copy of source files for ARCH
            let sourceArchURL = archURL.appendingPathComponent("source")
            try fileManager.copyItem(at: sourceURL, to: sourceArchURL)
            
            // prevent async (references to getcontext(), setcontext() and makecontext() result in App Store rejections)
            // and creation of shared libraries (default since 1.1.0)
            var options = "no-async no-shared"
            
            // openssl-1.1.1 tries to use an unguarded fork(), affecting AppleTVOS and WatchOS.
            // Luckily this is only present in the testing suite and can be built without it.
            switch platform {
            case .tvOS, .tvOSSimulator, .watchOS, .watchOSSimulator:
                options = "\(options) no-tests"
            default:
                break
            }
            
            // Relevant only for 64 bit builds
            if nistp64gcc128 && arch.hasSuffix("64") {
                options = "\(options) enable-ec_nistp_64_gcc_128"
            }
            
            // Build script that helps store all ENV variables in one process
            try execute(
                """
                #!/bin/sh
                XCODE_SELECT_PATH="$(xcode-select -p)"
                export LDFLAGS="-L$XCODE_SELECT_PATH/Platforms/\(platform.xcodeSDKName).platform/Developer/SDKs/\(platform.xcodeSDKName).sdk/usr/lib $LDFLAGS"
                export CPPFLAGS="-I$XCODE_SELECT_PATH/Platforms/\(platform.xcodeSDKName).platform/Developer/SDKs/\(platform.xcodeSDKName).sdk/usr/include $CPPFLAGS"
                cd \(sourceArchURL.relativePath)
                perl ./Configure \(openSSLTarget) --prefix=\(archURL.relativePath) \(options)
                make -j\(threads)
                make install_dev
                """,
                workingDirectory: archURL,
                environment: environment,
                outputRedirection: .collect(redirectStderr: true)
            )
            
            try libtool(
                fileURLs: [
                    archURL.appendingPathComponent("lib/libssl.a"),
                    archURL.appendingPathComponent("lib/libcrypto.a"),
                ],
                outputURL: archURL.appendingPathComponent("lib/\(BuildLibrary.openssl.libraryName)")
            )
            
            archBuildURLs.append(archURL)
        })
        
        //
        // Join platform arhes with lipo
        //

        try? fileManager.removeItem(at: platfromURL)
        try fileManager.createDirectory(
            at: platfromURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // This not a right because we are copying include/ from first arch
        // Some values in this headers ma not be equal
        // TODO: Should be reworked or something
        try fileManager.copyItem(at: archBuildURLs[0].appendingPathComponent("include"), to: platfromURL.appendingPathComponent("include"))
        try fileManager.createDirectory(at: platfromURL.appendingPathComponent("lib"), withIntermediateDirectories: true, attributes: nil)
        
        try lipo(
            fileURLs: archBuildURLs.map({ $0.appendingPathComponent("lib/\(BuildLibrary.openssl.libraryName)") }),
            outputURL: platfromURL.appendingPathComponent("lib/\(BuildLibrary.openssl.libraryName)")
        )
        
        try archBuildURLs.forEach({ try fileManager.removeItem(at: $0) })
        
        stdout("Done.")
    }
}

fileprivate extension BuildPlatform {
    
    var openSSLTargets: [String] {
        switch self {
        case .iOS:
            return ["ios-arm64"]
        case .iOSSimulator:
            return ["ios-simulator-x86_64", "ios-simulator-arm64"]
        case .tvOS:
            return ["tvos-arm64"]
        case .tvOSSimulator:
            return ["tvos-simulator-x86_64"]
        case .watchOS:
            return ["watchos-armv7k", "watchos-arm64_32"]
        case .watchOSSimulator:
            return ["watchos-simulator-i386"]
        case .macOS:
            return ["macos-x86_64", "macos-arm64"]
        case .macCatalyst:
            return ["mac-catalyst-x86_64", "mac-catalyst-arm64"]
        }
    }
}
