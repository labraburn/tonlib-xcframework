//
//  Created by Anton Spivak.
//

import Foundation
import TSCBasic

extension TerminalController {
    
    static let `default` = TerminalController(stream: stdoutStream)
    
    enum OutputStyle {
        
        case `default`
        case bold(color: Color)
        case normal(color: Color)
    }
    
    func write(_ string: String, with style: OutputStyle = .default) {
        switch style {
        case .default:
            write(string + "\n")
        case .bold(let color):
            write(string + "\n", inColor: color, bold: true)
        case .normal(let color):
            write(string + "\n", inColor: color, bold: false)
        }
    }
}
