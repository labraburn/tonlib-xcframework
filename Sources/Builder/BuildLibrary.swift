//
//  Created by Anton Spivak.
//

import Foundation

enum BuildLibrary: String, CaseIterable {
    
    case openssl
    case ton
    
    var libraryName: String {
        switch self {
        case .openssl:
            return "libopenssl.a"
        case .ton:
            return "libton.a"
        }
    }
    
    var xcframeworkName: String {
        switch self {
        case .openssl:
            return "OpenSSL.xcframework"
        case .ton:
            return "TON.xcframework"
        }
    }
    
    func outputURL(createIfNeeded: Bool = false) throws -> URL {
        let fileManager = FileManager.default
        
        var path = ""
        switch self {
        case .openssl:
            path = "/build/openssl/ouput"
        case .ton:
            path = "/build/ton/ouput"
        }
        
        return try fileManager.cacheURL(
            withPath: path,
            createIfNeeded: createIfNeeded
        )
    }
    
    func buildCommand() -> AwaitingParsableCommand.Type {
        switch self {
        case .openssl:
            return OpenSSL.self
        case .ton:
            return TON.self
        }
    }
    
    func buildExists() throws -> Bool {
        let fileManager = FileManager.default
        let outputURL = try outputURL()
        
        if fileManager.directoryExists(atPath: outputURL.relativePath) {
            return !(try fileManager.contentsOfDirectory(atPath: outputURL.relativePath)).isEmpty
        }
        
        return false
    }
    
    func buildExists(for platform: BuildPlatform) throws -> Bool {
        let fileManager = FileManager.default
        let outputURL = (try outputURL()).appendingPathComponent(platform.buildURLPathComponent())
        
        if fileManager.directoryExists(atPath: outputURL.relativePath) {
            return !(try fileManager.contentsOfDirectory(atPath: outputURL.relativePath)).isEmpty
        }
        
        return false
    }
    
    func buildIncludeURL(for platform: BuildPlatform) throws -> Foundation.URL {
        let outputURL = (try outputURL()).appendingPathComponent(platform.buildURLPathComponent())
        let includeURL = outputURL.appendingPathComponent("include")
        return includeURL
    }
    
    func buildLibURL(for platform: BuildPlatform) throws -> Foundation.URL {
        let outputURL = (try outputURL()).appendingPathComponent(platform.buildURLPathComponent())
        let includeURL = outputURL.appendingPathComponent("lib/\(libraryName)")
        return includeURL
    }
}

fileprivate enum BuildLibraryError: LocalizedError {
    
    case dosntHaveAnyBuildedLibrary(url: URL)
    
    var errorDescription: String? {
        switch self {
        case let .dosntHaveAnyBuildedLibrary(url):
            return "Can't locate builded libraries at \(url.relativePath)"
        }
    }
}
