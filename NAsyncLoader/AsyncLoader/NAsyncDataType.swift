//
//  NAsyncDataType.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//


import UIKit

/// Resources loadable by the `NAsyncURLLoader` should be represented by the type
/// conforming to `NAsyncDataType` protocol.
/// To ensure conformance the type must have `init?(data: Data)` constructor.
/// Conformance can easily be provided for types
/// such as {UIImage, XMLParser and PDFDocument by extensions as follows:
/// ```
///    extension UIImage: NAsyncDataType {}
/// ```
/// To represent JSON resources the types `JSONObject<Type:BaseModel>` and `JSONArray<Type:BaseModel>`
/// are defined below having a `value` property of type
/// 'Type and [Type] respectively.
public protocol NAsyncDataType {
    init?(data: Data)
}


extension UIImage: NAsyncDataType {}

public struct JsonObject: NAsyncDataType {
    public let value: [String: Any]
    public init?(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        guard let dictionary =  json as? [String: Any] else {
            return nil
        }
        self.value = dictionary
    }
}

public struct JsonArray: NAsyncDataType {
    public let value: [Any]
    public init?(data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        guard let array =  json as? [Any] else {
            return nil
        }
        self.value = array
    }
}




// JSONObject user codable Swift for decode json
// your model should extends  BaseModel to be able to work with JSONObject
// and it returns a JSONObject that hold a value of your model type

public struct JSONObject<T:BaseModel>: NAsyncDataType {
    public let value: T
    public init?(data: Data) {
        guard let json = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
       
        self.value = json
    }
}

// JSONArray user codable Swift for decode json
// your model should extends  BaseModel to be able to work with JSONObject
// and it returns a JSONArray that hold an array of values of your model type

public struct JSONArray<T:BaseModel>: NAsyncDataType {
    public let value: [T]
    public init?(data: Data) {
        guard let jsonArray = try? JSONDecoder().decode([T].self, from: data) else {
            return nil
        }
        self.value = jsonArray
    }
}

