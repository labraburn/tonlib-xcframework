//
//  Created by Anton Spivak.
//

import Foundation

enum OpenSSLError: LocalizedError {
    
    case developerPathNotSet
    case undefinedArchInTarget(target: String)
    case notExistsForPlatfrom(platfrom: BuildPlatform)
    
    var errorDescription: String? {
        switch self {
        case .developerPathNotSet:
            return "Xcode path is not set correctly! try run `sudo xcode-select`"
        case let .undefinedArchInTarget(target):
            return "Can't get arch from OpenSSL target: \(target)."
        case let .notExistsForPlatfrom(platfrom):
            return "Can't find OpenSSL library for platform: \(platfrom)."
        }
    }
}
