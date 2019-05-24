//
//  BaseModel.swift
//  NAsyncLoader
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import Foundation

// extends this model to be able to user
// obj =  JSONObject<T> and array = JSONArray<T>
// and get the values
// obj.value "value of type T"
// array.value  "value of type [T]"

open  class BaseModel:Codable {}
