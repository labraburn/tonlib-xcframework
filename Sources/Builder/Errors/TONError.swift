//
//  Created by Anton Spivak.
//

import Foundation

enum TONError: LocalizedError {
    
    case cmakeNotFound
    
    var errorDescription: String? {
        switch self {
        case .cmakeNotFound:
            return "cmake not found"
        }
    }
}
