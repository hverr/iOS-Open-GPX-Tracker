//
//  GPXLocalTileStore.swift
//  OpenGpxTracker
//
//  Created by Henri Verroken on 27/07/2022.
//

import Foundation

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
    
}
