//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser

enum BuildPlatform: String, ExpressibleByArgument, CustomStringConvertible {
    
    static var targets: [BuildPlatform] = [
        .iOS, .iOSSimulator,
        .tvOS, .tvOSSimulator,
        .watchOS, .watchOSSimulator,
        .macOS,
        .macCatalyst,
    ]
    
    case iOS = "iphoneos"
    case iOSSimulator = "iphonesimulator"
    case tvOS = "appletvos"
    case tvOSSimulator = "appletvsimulator"
    case watchOS = "watchos"
    case watchOSSimulator = "watchsimulator"
    case macOS = "macosx"
    case macCatalyst = "maccatalyst"
    
    var xcodeSDKName: String {
        switch self {
        case .iOS: return "iPhoneOS"
        case .iOSSimulator: return "iPhoneSimulator"
        case .tvOS: return "AppleTVOS"
        case .tvOSSimulator: return "AppleTVSimulator"
        case .watchOS: return "WatchOS"
        case .watchOSSimulator: return "WatchSimulator"
        case .macOS: return "MacOSX"
        case .macCatalyst: return "MacOSX"
        }
    }
    
    var description: String { self.rawValue }
    
    func applePlatform() -> String {
        switch self {
        case .iOS: return "iPhoneOS"
        case .iOSSimulator: return "iPhoneSimulator"
        case .tvOS: return "AppleTVOS"
        case .tvOSSimulator: return "AppleTVSimulator"
        case .watchOS: return "WatchOS"
        case .watchOSSimulator: return "WatchSimulator"
        case .macOS: return "MacOSX"
        case .macCatalyst: return "MacOSX"
        }
    }
    
    func currentSDKVersion() throws -> String {
        let sdk: String
        
        switch self {
        case .iOS, .iOSSimulator: sdk = "iphoneos"
        case .tvOS, .tvOSSimulator: sdk = "appletvos"
        case .watchOS, .watchOSSimulator: sdk = "watchos"
        case .macOS: sdk = "macosx"
        case .macCatalyst: sdk = "macosx"
        }
        
        return try shell(["xcrun", "-sdk", sdk, "--show-sdk-version"])
    }
    
    func minimumSDKVersion() -> String {
        switch self {
        case .iOS, .iOSSimulator: return "11.0"
        case .tvOS, .tvOSSimulator: return "11.0"
        case .watchOS, .watchOSSimulator: return "6.0"
        case .macOS: return "10.11"
        case .macCatalyst: return "14.0" // using iOS version for .macCatalyst build
        }
    }
    
    func buildURLPathComponent() -> String {
        return "Release-\(rawValue)"
    }
}
