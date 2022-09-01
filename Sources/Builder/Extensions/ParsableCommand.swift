//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic

extension ParsableCommand {
    
    func stdout(_ value: String, newlines: Bool = true) {
        var string = value
        if newlines {
            string = "\n\(value)\n"
        }
        
        TerminalController.default?.write(
            string,
            with: .bold(color: .green)
        )
    }
}
