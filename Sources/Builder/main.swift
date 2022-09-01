//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic

struct Builder: ParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "An utility to build OpenSSL and TON for Apple devices.",
        subcommands: [OpenSSL.self, TON.self, XCFramework.self],
        defaultSubcommand: XCFramework.self
    )
}

Builder.main()
