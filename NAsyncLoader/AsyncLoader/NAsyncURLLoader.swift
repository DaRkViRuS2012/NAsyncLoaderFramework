//
//  NAsyncURLLoader.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import Foundation

/// `NAsyncURLLoader` is an object asynchronously load resources identified by URL.
/// The result of the request is represented by the type
/// conforming to `NAsyncDataType` protocol.

public class NAsyncURLLoader<Type: NAsyncDataType> : NAsyncLoaderSessionDelegate {
    
    /// To ensure conformance the type must have an `init?(data: Data)` constructor.
    /// Conformance can easily be provided for types
    /// such as UIImage, XMLParser and PDFDocument by extensions as follows:
    /// ```
    ///    extension UIImage: NAsyncDataType {}
    /// ```
    /// To represent JSON resources the types `JSONObject<Type:BaseModel>` and `JSONArray<Type:BaseModel>`
    /// are defined below having a `value` property of type
    /// 'Type and [Type] respectively.
    
    
    /// Result of load request
    public  enum Result {
        case success(Type)
        case empty
        case error(Error)
        
        init(data: Data?, error: Error? = nil) {
            if let error = error {
                self = Result.error(error)
            } else if let resource = (data.flatMap{Type.self.init(data: $0)}) {
                self = Result.success(resource)
            } else {
                self = Result.empty
            }
        }
    }
    
    /// The type of the closure called to process loaded resources.
    /// - Parameters:
    ///     - result: Loaded resource or `nil` when the error occured.
    ///     - request: completed request descriptor.
    ///     - arbitrary user data provided when the corresponding request was made.
    public typealias AcceptorType = (_ result: Result,
        _ userData: Any?) -> ()
    
    lazy var session = NAsyncLoaderSession(delegate: self)
    
    /// Dispatch queue where callback acceptors will be executed.
    private let callbackQueue: DispatchQueue
    
    /// Dispatch queue used to protect consistency of
    /// internal data structures in multithreaded environment.
    private let requestsQueue = DispatchQueue(label: "network_session", qos: .utility)
    
    /// Request related data.
    private struct RequestData {
        let response: AcceptorType
        let userData: Any?
        
        init(acceptor: @escaping AcceptorType, userData: Any?) {
            self.response = acceptor
            self.userData = userData
        }
        
        func complete(with result: Result, using queue: DispatchQueue) {
            queue.async {
                self.response(result, self.userData)
            }
        }
    }
    
    private var requestPool = [Int : RequestData]()
    
    /// Creates NAsyncURLLoader object.
    /// - Parameter callbackQueue: Dispatch queue where callback acceptors
    ///                            for loaded resources will be executed.
    ///                            When omitted DispatchQueue.main will be used.
    public init (callbackQueue: DispatchQueue = DispatchQueue.main) {
        self.callbackQueue = callbackQueue
    }
    
    /// All processed request must be canceled
    /// because callbacks will disppear now.
    deinit {
        cancelAll()
    }
    
    /// Initiate asynchronous loading of the resource.
    /// - Parameters:
    ///     - url: loaded resource URL.
    ///     - userData: Arbitrary user data passed to acceptor callback
    ///                 when request is completed.
    ///     - acceptor: The completion handler closure called
    ///                 when the load succeeds or fails.
    /// - Returns: unique identifier for created request.
    @discardableResult
    public func requestResource(from url: URL,
                                userData: Any? = nil,
                                for acceptor: @escaping AcceptorType)
        -> Int {
            var requestId = 0
            requestsQueue.sync {
                requestId = session.makeRequest(url: url)
                requestPool[requestId] = RequestData(acceptor: acceptor,
                                                     userData: userData)
            }
            return requestId
    }
    
    /// Cancel resource loading.
    /// When  specified loading query already completed or canceled,
    /// subsequent calls to cancelRequest are ignored.
    /// - Parameter request: canceling request identifier.returned from the
    ///                    `requestResource` method corresponding call.
    public func cancelRequest(_ identifier: Int) {
        requestsQueue.sync {
            session.cancelRequest(identifier)
        }
    }
    
    /// Cancel all currently processed requests.
    public func cancelAll() {
        requestsQueue.sync {
            requestPool.keys.forEach(session.cancelRequest)
        }
    }
    
    // MARK: - NAsyncLoaderSessionDelegate method.
    
    ///
    func completionHandler(request: Int, didReceive data: Data, with error: Error?) {
        requestsQueue.async {
            guard let requestData = self.requestPool.removeValue(forKey: request) else {
                return
            }
            let result = Result(data: data, error: error)
            requestData.complete(with: result, using: self.callbackQueue)
        }
    }
}

