//
//  Created by Anton Spivak.
//

import Foundation
import ArgumentParser
import TSCBasic

public protocol AwaitingParsableCommand: ParsableCommand {
    
    mutating func run() async throws
}

fileprivate class _AwaitingParsableCommand<T: AwaitingParsableCommand> {
    var command: T
    var error: Error?
    
    init(command: T) {
        self.command = command
    }
}

extension AwaitingParsableCommand {
    
    mutating func run() throws {
        let state = _AwaitingParsableCommand(command: self)
        
        let group = DispatchGroup()
        group.enter()
        
        Task.detached(priority: .userInitiated) {
            defer {
                group.leave()
            }
            
            do {
                try await state.command.run()
            } catch {
                state.error = error
            }
        }
        
        group.wait()
        
        self = state.command
        
        guard let error = state.error
        else {
            return
        }
        
        TerminalController.default?.write(
            error.localizedDescription,
            with: .normal(color: .red)
        )
        
        Foundation.exit(1)
    }
}
