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
//        return try? FileManager.default.fileSizeForDirectory(at: folderURL())
        return 0;
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
                    skipped += 1
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
                }
                num_files += 1
            }
            
            print("Copied \(num_files) files (skipped \(skipped))")
            
            try fileManager.removeItem(at: tmpDirURL)
            print("Removed tmp folder")
            
        } catch {
            print("ZIP EXTRACT FAILED: \(error)")
        }
    }
    
}
