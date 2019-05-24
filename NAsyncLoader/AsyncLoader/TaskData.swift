//
//  TaskData.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/24/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import Foundation

/// URLSessionTask related data.
public struct TaskData {
    typealias Request = (identifier: Int, request: URLRequest)
    
    /// Buffer used to collect received data.
    var data = Data()
    
    /// All requests for the same URL, processed simultaneously.
    private var requests: [Request]
    
    var attachedRequests: [Int] {return requests.map{$0.identifier}}
    
    /// May be true when all relevant requests canceled.
    var isEmpty: Bool {return attachedRequests.isEmpty}
    
    init(_ request: URLRequest, identifier: Int) {
        requests = [(identifier, request)]
    }
    
    init(_ requests:  ArraySlice<Request>) {
        self.requests = Array(requests)
    }
    
    mutating func add(_ request: URLRequest, identifier: Int) {
        requests.append((identifier, request))
    }
    
    mutating func add(contentsOf tail: ArraySlice<Request>) {
        requests.append(contentsOf: tail)
    }
    
    mutating func removeRequest(with identifier: Int) -> URLRequest? {
        return requests.firstIndex {
            $0.identifier == identifier}.map{self.requests.remove(at: $0)
            }?.request
    }
    
    /// Remove and return all but first requests.
    mutating func removeTail() -> ArraySlice<Request> {
        guard !requests.isEmpty else {return []}
        let tail = requests.suffix(requests.count - 1)
        requests = [requests[0]]
        return tail
    }
}
