//
//  Created by Anton Spivak.
//


import Foundation

private let _ton_apple_simple_cmake =
"""
add_definitions (-DTARGET_CPU_X86_64)
add_definitions (-DTARGET_OS_OSX)

""".data(using: .utf8)!

extension Resource {
    
    static let tonAppleSimpleCmake = Resource(contents: _ton_apple_simple_cmake, fileName: "Simple.cmake")
}
