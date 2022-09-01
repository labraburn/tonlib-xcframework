//
//  Created by Anton Spivak.
//

import Foundation
import TSCBasic
import TSCUtility

final class Downloader {
    
    private class Internal: NSObject, URLSessionDownloadDelegate {
        
        private lazy var session: URLSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        
        private let url: Foundation.URL
        private var task: URLSessionDownloadTask?
        private var progress: ((Double) -> Void)?
        private var comletion: ((Result<Foundation.URL, Error>) -> Void)?
        
        init(url: Foundation.URL) {
            self.url = url
        }
        
        func download(
            progress: @escaping (Double) -> Void,
            completion: @escaping (Result<Foundation.URL, Error>) -> Void
        ) {
            self.progress = progress
            self.comletion = completion
            
            let task = session.downloadTask(with: url)
            task.resume()
        }
        
        func clean() {
            progress = nil
            comletion = nil
        }
        
        // MARK: URLSessionDownloadDelegate
        
        func urlSession(
            _ session: URLSession,
            downloadTask: URLSessionDownloadTask,
            didWriteData bytesWritten: Int64,
            totalBytesWritten: Int64,
            totalBytesExpectedToWrite: Int64
        ) {
            progress?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Swift.Error?) {
            if let error = error {
                comletion?(.failure(error))
            } else {
                comletion?(.failure(URLError.undefined))
            }
            
            clean()
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: Foundation.URL) {
            comletion?(.success(location))
            clean()
        }
    }
    
    private let header: String
    private let url: Foundation.URL
    
    /// Convenience method to download using an URL, creates and resumes an URLSessionDownloadTask internally.
    ///
    /// - Parameter url: The URL for which to download.
    /// - Parameter header: The string that will be printed in stdout.
    /// - Returns: Downloaded file URL.. The file will not be removed automatically.
    init(url: Foundation.URL, header: String) {
        self.url = url
        self.header = header
    }
    
    /// Method to download.
    ///
    /// - Parameter fileURL: The URL where downloaded file will be moved..
    func download(to fileURL: Foundation.URL) async throws {
        guard fileURL.isFileURL
        else {
            throw URLError.notFileURL(url: fileURL)
        }
        
        let _internal = Internal(url: url)
        let _animation = PercentProgressAnimation(stream: stdoutStream, header: header)
        
        return try await withCheckedThrowingContinuation({ continuation in
            _internal.download(
                progress: { progress in
                    _animation.update(step: Int(progress * 100), total: 100, text: "...")
                },
                completion: { result in
                    switch result {
                    case let .success(location):
                        do {
                            let fileManager = FileManager.default
                            
                            try? fileManager.removeItem(at: fileURL)
                            try fileManager.moveItem(at: location, to: fileURL)

                            
                            _animation.update(step: 100, total: 100, text: "Done.\n")
                            _animation.complete(success: true)
                            
                            continuation.resume(returning: ())
                        } catch {
                            
                            _animation.update(step: 100, total: 100, text: "Error.\n")
                            _animation.complete(success: false)
                            
                            continuation.resume(throwing: error)
                        }
                    case let .failure(error):
                        _animation.update(step: 100, total: 100, text: "Error.\n")
                        _animation.complete(success: false)
                        
                        continuation.resume(throwing: error)
                    }
                }
            )
        })
    }
}
