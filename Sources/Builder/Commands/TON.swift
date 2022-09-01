//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility

struct TON: AwaitingParsableCommand {
    
    static var configuration = CommandConfiguration(
        commandName: "ton",
        abstract: "Builds TON for Apple devices."
    )
    
    mutating func run() async throws {
        let fileManager = FileManager.default
        
        let buildURL = try fileManager.cacheURL(withPath: "/build/ton", createIfNeeded: true)
        let sourceURL = try fileManager.cacheURL(withPath: "/build/ton/source", createIfNeeded: true)
        let outputURL = try BuildLibrary.ton.outputURL(createIfNeeded: true)
        
        try cloneIfNeeded(to: sourceURL)
        
        stdout(
            """
            TON.
            Build directry: \(buildURL.relativePath)
            Source direcotry: \(sourceURL.relativePath)
            Out directory: \(outputURL.relativePath)
            """
        )
        
        try prepare(sourceURL: sourceURL, to: outputURL)
        for platform in BuildPlatform.targets {
            try await build(
                for: platform,
                sourceURL: sourceURL,
                to: outputURL
            )
        }
        
        stdout(
            """
            Done! Did build TON.
            Output directory: \(outputURL.relativePath)
            """
        )
    }
    
    private func cloneIfNeeded(to url: Foundation.URL) throws {
        let fileManager = FileManager.default
        let sourceURL = url
        
        guard sourceURL.isFileURL
        else {
            throw URLError.notDirectory(url: sourceURL)
        }
        
        guard !fileManager.directoryExists(atPath: sourceURL.appendingPathComponent(".git").relativePath)
        else {
            stdout(
                """
                TON is already cloned: \(sourceURL.relativePath).
                Updating submodules.
                """
            )
            
            try execute(
                """
                #!/bin/sh
                cd \(sourceURL.relativePath)
                git checkout labraburn
                git pull
                git submodule update --init --recursive
                git submodule sync --recursive
                """,
                workingDirectory: sourceURL,
                outputRedirection: .none
            )
            
            return
        }
        
        // Clone
        
        stdout("Start cloning TON: \(sourceURL.relativePath).")
        
        try execute(
            """
            #!/bin/sh
            git clone git@github.com:labraburn/ton.git \(sourceURL.relativePath)
            git checkout labraburn
            git pull
            cd \(sourceURL.relativePath)
            git submodule update --init --recursive
            git submodule sync --recursive
            """,
            workingDirectory: sourceURL,
            outputRedirection: .none
        )
    }
    
    private func prepare(
        sourceURL: Foundation.URL,
        to: Foundation.URL
    ) throws {
        // use this platfrom to prepare cross-compiling
        let platform = BuildPlatform.macOS
        
        guard try BuildLibrary.openssl.buildExists(for: platform)
        else {
            throw OpenSSLError.notExistsForPlatfrom(platfrom: platform)
        }
        
        let fileManager = FileManager.default
        let targetURL = to.appendingPathComponent("Release-common")
        
        try? fileManager.removeItem(at: targetURL)
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)
        
        let toolchainURL = (try toolchainsURL()).appendingPathComponent("Simple.cmake")
        let options = [
            "-DOPENSSL_FOUND=1",
            "-DOPENSSL_CRYPTO_LIBRARY=\((try BuildLibrary.openssl.buildLibURL(for: platform)).relativePath)",
            "-DOPENSSL_INCLUDE_DIR=\((try BuildLibrary.openssl.buildIncludeURL(for: platform)).relativePath)",
            "-DCMAKE_BUILD_TYPE=Release",
            "-DTON_ONLY_TONLIB=ON",
            "-DCMAKE_TOOLCHAIN_FILE=\(toolchainURL.relativePath)",
            "-DTON_ARCH=",
            "-DGIT_EXECUTABLE=/usr/bin/git",
        ]
        
        stdout(
            """
            Start TON build preparing.
            Output directory: \(targetURL.relativePath)
            """
        )
        
        try execute(
            """
            cd \(targetURL.relativePath)
            cmake \(options.joined(separator: " ")) \(sourceURL.relativePath) || exit
            cmake --build . --target prepare_cross_compiling || exit
            
            """,
            workingDirectory: targetURL
        )
        
        stdout("Done.")
    }
    
    private func build(
        for platform: BuildPlatform,
        sourceURL: Foundation.URL,
        to: Foundation.URL
    ) async throws {
        guard try BuildLibrary.openssl.buildExists(for: platform)
        else {
            throw OpenSSLError.notExistsForPlatfrom(platfrom: platform)
        }
        
        let fileManager = FileManager.default
        let targetURL = to.appendingPathComponent(platform.buildURLPathComponent())
        
        stdout(
            """
            Start build TON for platfrom: \(platform.rawValue).
            Output directory: \(targetURL.relativePath)
            """
        )
        
        //
        // Build all OpenSSL targtes for given platform
        //
        
        var cmakePlatfromBuildURLs: [Foundation.URL] = []
        let threads = try shell(["sysctl", "hw.ncpu"]).components(separatedBy: " ")[1]
        let toolchainURL = (try toolchainsURL()).appendingPathComponent("Apple.cmake")
        
        try platform.tonTargetPlatfroms.forEach({ tonTargetPlatfrom in
            
            let installURL = to.appendingPathComponent("\(platform.buildURLPathComponent())-\(tonTargetPlatfrom)")
            let buildURL = to.appendingPathComponent("\(platform.buildURLPathComponent())-\(tonTargetPlatfrom)-build")
            
            let options = [
                "-DOPENSSL_FOUND=1",
                "-DOPENSSL_CRYPTO_LIBRARY=\((try BuildLibrary.openssl.buildLibURL(for: platform)).relativePath)",
                "-DOPENSSL_INCLUDE_DIR=\((try BuildLibrary.openssl.buildIncludeURL(for: platform)).relativePath)",
                "-DCMAKE_BUILD_TYPE=Release",
                "-DTON_ONLY_TONLIB=ON",
                "-DCMAKE_TOOLCHAIN_FILE=\(toolchainURL.relativePath)",
                "-DTON_ARCH=",
                "-DGIT_EXECUTABLE=/usr/bin/git",
                "-DCMAKE_INSTALL_PREFIX=\(installURL.relativePath)",
                "-DPLATFORM=\(tonTargetPlatfrom)",
                "-DDEPLOYMENT_TARGET=\(platform.tonDeploymentTarget)",
                "-DENABLE_BITCODE=TRUE",
            ]

            try? fileManager.removeItem(at: installURL)
            try fileManager.createDirectory(at: installURL, withIntermediateDirectories: true, attributes: nil)
            
            try? fileManager.removeItem(at: buildURL)
            try fileManager.createDirectory(at: buildURL, withIntermediateDirectories: true, attributes: nil)
            
            try execute(
                """
                cd \(buildURL.relativePath)
                cmake \(options.joined(separator: " ")) \(sourceURL.relativePath) || exit
                make -j\(threads) install || exit
                
                """,
                workingDirectory: Foundation.URL(fileURLWithPath: "/usr/bin")
            )
            
            let libsURL = installURL.appendingPathComponent("lib")
            let libs = try fileManager
                .contentsOfDirectory(atPath: libsURL.relativePath)
                .compactMap({ filename -> Foundation.URL? in
                    guard filename.hasSuffix(".a")
                    else {
                        return nil
                    }
                    
                    return libsURL.appendingPathComponent(filename)
                })
            
            try libtool(
                fileURLs: libs,
                outputURL: libsURL.appendingPathComponent(BuildLibrary.ton.libraryName)
            )
            
            try fileManager.removeItem(at: buildURL)
            cmakePlatfromBuildURLs.append(installURL)
        })
        
        //
        // Join platform arhes with lipo
        //
        
        try? fileManager.removeItem(at: targetURL)
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true, attributes: nil)

        // This not a right because we are copying include/ from first arch
        // Some values in this headers ma not be equal
        // TODO: Should be reworked or something
        try fileManager.copyItem(at: cmakePlatfromBuildURLs[0].appendingPathComponent("include"), to: targetURL.appendingPathComponent("include"))
        try fileManager.createDirectory(at: targetURL.appendingPathComponent("lib"), withIntermediateDirectories: true, attributes: nil)

        try lipo(
            fileURLs: cmakePlatfromBuildURLs.map({ $0.appendingPathComponent("lib/\(BuildLibrary.ton.libraryName)") }),
            outputURL: targetURL.appendingPathComponent("lib/\(BuildLibrary.ton.libraryName)")
        )

        try cmakePlatfromBuildURLs.forEach({ try fileManager.removeItem(at: $0) })
        
        stdout("Done.")
    }
    
    private func toolchainsURL() throws -> Foundation.URL {
        let fileManager = FileManager.default
        let url = try fileManager.cacheURL(withPath: "/build/ton/toolchains", createIfNeeded: true)
        try Resource.tonAppleSimpleCmake.write(into: url)
        try Resource.tonAppleCommonCmake.write(into: url)
        return url
    }
}

fileprivate extension BuildPlatform {
    
    var tonTargetPlatfroms: [String] {
        switch self {
        case .iOS:
            return ["OS"]
        case .iOSSimulator:
            return ["SIMULATOR", "SIMULATORARM64"]
        case .tvOS:
            return ["TVOS"]
        case .tvOSSimulator:
            return ["TVOS_SIMULATOR"]
        case .watchOS:
            return ["WATCHOS"]
        case .watchOSSimulator:
            return ["WATCHOS_SIMULATOR"]
        case .macOS:
            return ["MAC", "MAC_ARM64"]
        case .macCatalyst:
            return ["MAC_CATALYST", "MAC_CATALYST_ARM64"]
        }
    }
    
    var tonDeploymentTarget: String {
        switch self {
        case .iOS, .iOSSimulator: return "12.0"
        case .tvOS, .tvOSSimulator: return "12.0"
        case .watchOS, .watchOSSimulator: return "6.0"
        case .macOS: return "11.0"
        case .macCatalyst: return "14.0"
        }
    }
}
