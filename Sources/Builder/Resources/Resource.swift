//
//  Created by Anton Spivak.
//

import Foundation

struct Resource {
    
    let contents: Data
    let fileName: String
    
    init(contents: Data, fileName: String) {
        self.contents = contents
        self.fileName = fileName
    }
    
    @discardableResult
    func write(into directory: URL) throws -> URL {
        let fileManager = FileManager.default
        guard directory.isFileURL,
              fileManager.directoryExists(atPath: directory.relativePath)
        else {
            throw URLError.notDirectory(url: directory)
        }
        
        let url = directory.appendingPathComponent(fileName)
        try contents.write(to: url)
        
        return url
    }
}
