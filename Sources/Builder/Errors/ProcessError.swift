//
//  Created by Anton Spivak.
//

import Foundation
import TSCBasic

enum ProcessError: LocalizedError {
    
    case signalled(signal: Int32)
    case terminated(code: Int32, message: String)
    
    var errorDescription: String? {
        switch self {
        case .signalled(let signal):
            return "Process was killed by system: \(signal)"
        case .terminated(let code, let message):
            return "Process did exit with code: \(code), message: \(message)"
        }
    }
    
    static func rethrowIfNeeded(_ result: ProcessResult) throws {
        switch result.exitStatus {
        case let .signalled(signal):
            throw ProcessError.signalled(signal: signal)
        case let .terminated(code):
            guard code == 0
            else {
                let message: String
                if let stderr = try? result.utf8stderrOutput(), !stderr.isEmpty {
                    message = stderr
                } else if let output = try? result.utf8Output() {
                    message = output
                } else {
                    message = "No ouput."
                }
                
                throw ProcessError.terminated(
                    code: code,
                    message: message
                )
            }
            break
        }
    }
}
