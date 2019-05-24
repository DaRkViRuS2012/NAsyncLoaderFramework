//
//  File.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import Foundation

/*
 NAsyncLoaderSessionDelegate
 *******************************
 The protocol specifies the methods that URLResourceManager
 Responding to classes that requesting a resource
 
 */


protocol NAsyncLoaderSessionDelegate: class {
    
    /*
     completionHandler
     *******************************
     1. Called when the resource data available for an URL either from Server or from Cache.
     2. Used to catch errors while fetching data for the Resource.
     */
    
    func completionHandler(request: Int, didReceive data: Data, with error: Error?)
    
}
