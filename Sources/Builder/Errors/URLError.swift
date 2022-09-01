//
//  Created by Anton Spivak.
//

import Foundation

enum URLError: LocalizedError {
    
    case undefined
    case pathShouldStartWith
    case cantCreateURLFromString(string: String)
    case notAnArchiveURL(url: URL)
    case notFileURL(url: URL)
    case notDirectory(url: URL)
    
    var errorDescription: String? {
        switch self {
        case .undefined:
            return "Undefined error."
        case .pathShouldStartWith:
            return "Subpath should start with `/` symbol."
        case let .cantCreateURLFromString(string):
            return "Can't create URL from string: \(string)."
        case let .notAnArchiveURL(url):
            return "File is not an archive file: \(url)."
        case let .notFileURL(url):
            return "Not file url: \(url)."
        case let .notDirectory(url):
            return "Not directory url: \(url)"
        }
    }
}
