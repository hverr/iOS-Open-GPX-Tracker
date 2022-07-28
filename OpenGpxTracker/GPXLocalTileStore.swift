//
//  GPXLocalTileStore.swift
//  OpenGpxTracker
//
//  Created by Henri Verroken on 27/07/2022.
//

import Foundation
import ZIPFoundation

open class GPXLocalTileStore {
    open class func folderURL() -> URL {
        let docsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let baseURL = URL(fileURLWithPath: docsPath, isDirectory: true).appendingPathComponent("opengpx_tiles", isDirectory: true)
        return baseURL
    }
    
    open class func storeSize() -> UInt64? {
        return try? fileSizeForDirectory(at: folderURL())
    }
    
    open class func loadZipFile(url: URL) {
        print("GPXLocalTileStore: loadZipFile \(url)")
        let fileManager = FileManager()
        let tmpDirURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let tmpDirPathComps = tmpDirURL.pathComponents.count
        let destURL = folderURL()

        do {
            try fileManager.createDirectory(at: tmpDirURL, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: destURL, withIntermediateDirectories: true)
            
            print("Unzipping to tmp dir: \(tmpDirURL)")
            try fileManager.unzipItem(at: url, to: tmpDirURL)
            
            print("Copying each file to dest")
            var num_files = 0
            var skipped = 0
            let urls = fileManager.enumerator(at: tmpDirURL, includingPropertiesForKeys: [.isDirectoryKey])
            while let url = urls?.nextObject() as? URL {
                if try url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true {
                    continue
                }
                let relPathComps = url.pathComponents.dropFirst(tmpDirPathComps)
                var tileDest = URL(string: destURL.absoluteString)!
                for c in relPathComps {
                    tileDest.appendPathComponent(c)
                }
                if !fileManager.fileExists(atPath: tileDest.path) {
                    try fileManager.createDirectory(at: tileDest.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try fileManager.copyItem(at: url, to: tileDest)
                    num_files += 1
                } else {
                    skipped += 1
                }
            }
            
            print("Copied \(num_files) files (skipped \(skipped))")
            
            try fileManager.removeItem(at: tmpDirURL)
            print("Removed tmp folder")
            
        } catch {
            print("ZIP EXTRACT FAILED: \(error)")
        }
    }
    
    class func fileSizeForDirectory(at directoryURL: URL) throws -> UInt64 {
        
        func regularFileSize(url: URL) throws -> UInt64 {
            let allocatedSizeResourceKeys: Set<URLResourceKey> = [
                .isRegularFileKey,
                .fileSizeKey,
            ]
            let resourceValues = try url.resourceValues(forKeys: allocatedSizeResourceKeys)
            // We only look at regular files.
            guard resourceValues.isRegularFile ?? false else {
                return 0
            }
          return UInt64(resourceValues.fileSize ?? 0)
        }
        
        // The error handler simply stores the error and stops traversal
        var enumeratorError: Error? = nil
        
        /// Handler in case of error when calculating the filesize
        func errorHandler(_: URL, error: Error) -> Bool {
            enumeratorError = error
            return false
        }
        let allocatedSizeResourceKeys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .fileSizeKey
        ]
        
        // We have to enumerate all directory contents, including subdirectories.
        let enumerator = FileManager.default.enumerator(at: directoryURL,
                                         includingPropertiesForKeys: Array(allocatedSizeResourceKeys),
                                         options: [],
                                         errorHandler: errorHandler)!
        
        // We'll sum up content size here:
        var accumulatedSize: UInt64 = 0
        // Perform the traversal.
        for item in enumerator {
            // Bail out on errors from the errorHandler.
            if enumeratorError != nil { break }
            // Add up individual file sizes.
            let contentItemURL = item as! URL
            accumulatedSize += try regularFileSize(url: contentItemURL)
        }
        // Rethrow errors from errorHandler.
        if let error = enumeratorError { throw error }
        return accumulatedSize
    }
    
}
