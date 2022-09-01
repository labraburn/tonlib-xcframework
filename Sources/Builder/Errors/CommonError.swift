//
//  Created by Anton Spivak.
//

import Foundation

enum CommonError: LocalizedError {
    
    case directoryNotEmpty(url: URL)
    
    var errorDescription: String? {
        switch self {
        case let .directoryNotEmpty(url):
            return "Directory not empty: \(url.relativePath)"
        }
    }
}
