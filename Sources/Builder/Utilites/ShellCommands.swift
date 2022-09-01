//
//  Created by Anton Spivak.
//

import Foundation
import TSCUtility
import TSCBasic

/// Returns output from shell command
///
/// - Parameter arguments: Arguments passed to shell comand
/// - Parameter outputRedirection: How process redirects its output. Default value is .collect.
///
/// - Note: First argument is executable command
func shell(
    _ arguments: [String],
    outputRedirection: TSCBasic.Process.OutputRedirection = .collect
) throws -> String {
    let process = Process(
        arguments: arguments,
        outputRedirection: outputRedirection
    )
    
    try process.launch()
    let result = try process.waitUntilExit()
    
    var output = ""
    
    switch result.output {
    case let .failure(error):
        throw error
    case let .success(bytes):
        output = String(bytes: bytes, encoding: .utf8) ?? ""
    }
    
    return output.trimmingCharacters(in: .newlines)
}

/// Runs chmod +x at fileURL
///
/// - Parameter fileURL: URL of file that will be executable
/// - Parameter outputRedirection: How process redirects its output. Default value is .collect.
func markExecutable(
    _ fileURL: Foundation.URL,
    outputRedirection: TSCBasic.Process.OutputRedirection = .collect
) throws {
    let process = Process(
        arguments: ["chmod", "+x", fileURL.relativePath],
        outputRedirection: outputRedirection
    )
    
    try process.launch()
    let result = try process.waitUntilExit()
    
    
    try ProcessError.rethrowIfNeeded(result)
}

/// Joins static libraries into one fat file
///
/// - Parameter fileURLs: urls of static libs .a files
/// - Parameter outputURL: url of output fat .a file
/// - Parameter outputRedirection: How process redirects its output. Default value is .collect.
func libtool(
    fileURLs: [Foundation.URL],
    outputURL: Foundation.URL,
    outputRedirection: TSCBasic.Process.OutputRedirection = .collect
) throws {
    let process = Process(
        arguments: [
            "libtool",
            "-static",
            "-o", outputURL.relativePath
        ] + fileURLs.map { $0.relativePath },
        outputRedirection: outputRedirection
    )
    
    try process.launch()
    let result = try process.waitUntilExit()
    
    try ProcessError.rethrowIfNeeded(result)
}

/// Joins static fat libraries into one fat file
///
/// - Parameter fileURLs: urls of static libs .a files
/// - Parameter outputURL: url of output fat .a file
/// - Parameter outputRedirection: How process redirects its output. Default value is .collect.
func lipo(
    fileURLs: [Foundation.URL],
    outputURL: Foundation.URL,
    outputRedirection: TSCBasic.Process.OutputRedirection = .collect
) throws {
    let process = Process(
        arguments: [
            "lipo", "-create"
        ] + fileURLs.map { $0.relativePath } + [
            "-output", outputURL.relativePath
        ],
        outputRedirection: outputRedirection
    )
    
    try process.launch()
    let result = try process.waitUntilExit()
    
    try ProcessError.rethrowIfNeeded(result)
}

/// Saves script at tmp dir and exucutes
///
/// - Parameter script: The bash script
/// - Parameter workingDirectory: The path to the directory under which to run the process.
/// - Parameter environment: The environment to pass to subprocess. By default the current process environment will be inherited. 
/// - Parameter outputRedirection: How process redirects its output. Default value is .collect.
func execute(
    _ script: String,
    workingDirectory: Foundation.URL,
    environment: [String : String] = [:],
    outputRedirection: TSCBasic.Process.OutputRedirection = .collect
) throws {
    let url = Foundation.URL(fileURLWithPath: "\(NSTemporaryDirectory())\(UUID().uuidString).sh")
    
    try script.write(to: url, atomically: true, encoding: .utf8)
    try markExecutable(url)
    
    let global = ProcessInfo.processInfo.environment
    let process = Process(
        arguments: ["sh", url.relativePath],
        environment: global + environment,
        workingDirectory: AbsolutePath(workingDirectory.relativePath),
        outputRedirection: outputRedirection
    )
    
    try process.launch()
    
    let result = try process.waitUntilExit()
    try ProcessError.rethrowIfNeeded(result)
}
