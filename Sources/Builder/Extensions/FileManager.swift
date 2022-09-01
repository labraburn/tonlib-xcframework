//
//  Created by Anton Spivak.
//

import Foundation

extension FileManager {
    
    func cacheURL(withPath path: String? = nil, createIfNeeded: Bool = true) throws -> URL {
        var subpath = ""
        if let path = path {
            guard path.starts(with: "/")
            else {
                throw URLError.pathShouldStartWith
            }
            
            subpath = path
        }
        
        var path = "~/.tonlib-xcframework\(subpath)".standardizingPath.stringByExpandingTildeInPath
        if path.hasSuffix("/") {
            path.removeLast()
        }
        
        let url = URL(fileURLWithPath: path)
        
        if !directoryExists(atPath: path) && createIfNeeded {
            try createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        return url
    }
    
    func directoryExists(atPath path: String) -> Bool {
        var _bool = ObjCBool(false)
        guard fileExists(atPath: path, isDirectory: &_bool)
        else {
            return false
        }
        return _bool.boolValue
    }
}
