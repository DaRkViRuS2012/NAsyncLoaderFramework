//
//  NAsyncLoaderSession.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import Foundation



/// This class actually performs the entire load,
/// but delegates loaded data processing.
class NAsyncLoaderSession: NSObject {
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = NAsyncSettings.settings.requestTimeoutSeconds
        configuration.timeoutIntervalForResource = NAsyncSettings.settings.requestTimeoutSeconds
        configuration.httpMaximumConnectionsPerHost = NAsyncSettings.settings.maximumSimultaneousDownloads
        configuration.requestCachePolicy = NAsyncSettings.settings.cache.requestCachePolicy
        
        let cachePath = NAsyncSettings.settings.cache.diskPath
    
        let cache = URLCache(
            memoryCapacity: NAsyncSettings.settings.cache.memoryCapacityBytes,
            diskCapacity: NAsyncSettings.settings.cache.diskCapacityBytes,
            diskPath: cachePath)
        
        configuration.urlCache = cache
        return URLSession(configuration: configuration,
                          delegate: self, delegateQueue: nil)
    }()
    
    /// Dispatch queue used to protect consistency of
    /// internal data structures in multithreaded environment.
    private let poolQueue = DispatchQueue(label: "network_session", qos: .utility)
    
    
    /// Tasks being processed.
    private var taskPool = [URLSessionTask : TaskData]()
    
    /// Variable used to generate request identifier.
    static var requestNumber = Int(0)
    
    var delegate: NAsyncLoaderSessionDelegate
    
    /// This class is useless without delegate,
    /// so it is assumed that the creating object set self as a delegate.
    init(delegate: NAsyncLoaderSessionDelegate) {
        self.delegate = delegate
    }
    
    /// Create request to load from URL. If this URL currently processed,
    /// request attached to existing task, else new task created.
    /// - Parameter url: loaded resource URL.
    /// - Returns: unique request identifier.
    func makeRequest(url: URL) -> Int {
        let request = URLRequest(url: url)
        var requestId = 0
        poolQueue.sync {
            NAsyncLoaderSession.requestNumber = NAsyncLoaderSession.requestNumber &+ 1
            requestId = NAsyncLoaderSession.requestNumber
            let tasks = self.taskPool.keys
            if let task = (tasks.first{$0.currentRequest?.url == url}) {
                // currently loaded.
                var taskData = self.taskPool[task]!
                taskData.add(request, identifier: requestId)
                self.taskPool[task] = taskData
            } else {
                // new load is initiated.
                let task = self.session.dataTask(with: request)
                self.taskPool[task] = TaskData(request, identifier: requestId)
                task.resume()
            }
        }
        return requestId
    }
    
    func cancelRequest(_ identifier: Int) {
        poolQueue.sync {
            for (task, taskData) in taskPool {
                var newData = taskData
                if newData.removeRequest(with: identifier) != nil {
                    if newData.isEmpty {
                        task.cancel()
                    } else {
                        taskPool[task] = newData
                    }
                    break
                }
            }
        }
    }
}

extension NAsyncLoaderSession:
URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate  {
    
    // MARK: - URLSessionDataDelegate method.
    
    /// Part of data received.
    func urlSession(_ session: URLSession,
                    dataTask task: URLSessionDataTask,
                    didReceive data: Data) {
        poolQueue.async {
            var taskData = self.taskPool[task]
            taskData?.data.append(data)
            self.taskPool[task] = taskData
        }
    }
    
    // MARK: - URLSessionTaskDelegate methods.
    
    /// Response headers received.
    func urlSession(_ session: URLSession,
                    dataTask task: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let response = response as? HTTPURLResponse,
            (400...599).contains(response.statusCode) {
            // HTTP error codes
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }
    
    /// Load completed.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        poolQueue.async {
            guard let taskData = self.taskPool.removeValue(forKey: task) else {
                return
            }
            let data = taskData.data
            taskData.attachedRequests.forEach {
                self.delegate.completionHandler(request: $0, didReceive: data, with: error)
            }
        }
    }
    
    /// URL Redirection.
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        assert((300...399).contains(response.statusCode))
        poolQueue.async {
            if var taskData = self.taskPool.removeValue(forKey: task) {
                // Remove all additional requests for original URL
                let tail = taskData.removeTail()
                self.taskPool[task] = taskData
                if tail.count != 0 {
                    // and start new task for them.
                    let newTask = self.session.dataTask(with: task.originalRequest!)
                    self.taskPool[newTask] = TaskData(tail)
                    newTask.resume()
                }
            }
        }
        completionHandler(request)
    }
}


