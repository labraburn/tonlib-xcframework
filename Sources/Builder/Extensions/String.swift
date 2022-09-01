//
//  Created by Anton Spivak.
//

import Foundation

extension String {
    
    var standardizingPath: String { (self as NSString).standardizingPath }
    var stringByExpandingTildeInPath: String { (self as NSString).expandingTildeInPath }
    
    var stringByExpandingPathInCurrentDirectory: String {
        let fileManager = FileManager.default
        let currentDirectoryPath = fileManager.currentDirectoryPath
        
        if hasPrefix("/") {
            return URL(fileURLWithPath: self)
                .relativePath
                .standardizingPath
        } else if hasPrefix("..") {
            return URL(fileURLWithPath: "\(currentDirectoryPath)/\(self)".standardizingPath)
                .relativePath
                .standardizingPath
        } else if hasPrefix("~") {
            return URL(fileURLWithPath: stringByExpandingTildeInPath)
                .relativePath
                .standardizingPath
        } else {
            return URL(fileURLWithPath: "\(currentDirectoryPath)/\(standardizingPath)")
                .relativePath
                .standardizingPath
        }
    }
}
