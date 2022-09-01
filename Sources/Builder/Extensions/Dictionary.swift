//
//  Created by Anton Spivak.
//

import Foundation

extension Dictionary {
    
    static func +(_ lhs: Dictionary<Key, Value>, _ rhs: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        var new = lhs
        new.merge(rhs)
        return new
    }
    
    mutating func merge(_ rhs: [Key: Value]) {
        for (key, value) in rhs {
            updateValue(value, forKey: key)
        }
    }
}
