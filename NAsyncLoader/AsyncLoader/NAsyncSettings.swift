//
//  NAsyncSettings.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//
import Foundation


public struct NAsyncSettings {
    /// Settings for caching of the images.
    public var cache = NAsyncCacheSettings()
    
    public static var settings = NAsyncSettings()
    
    /// Timeout for image requests in seconds. This will cause a timeout if a resource is not able to be retrieved within a given timeout. Default timeout: 10 seconds.
    public var requestTimeoutSeconds: Double = 10
    
    /// Maximum number of simultaneous image downloads. Default: 4.
    public var maximumSimultaneousDownloads: Int = 4
}

func ==(lhs: NAsyncSettings, rhs: NAsyncSettings) -> Bool {
    return lhs.requestTimeoutSeconds == rhs.requestTimeoutSeconds
        && lhs.maximumSimultaneousDownloads == rhs.maximumSimultaneousDownloads
        && lhs.cache == rhs.cache
}

func !=(lhs: NAsyncSettings, rhs: NAsyncSettings) -> Bool {
    return !(lhs == rhs)
}
