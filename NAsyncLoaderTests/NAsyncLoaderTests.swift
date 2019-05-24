//
//  NAsyncLoaderTests.swift
//  NAsyncLoaderTests
//
//  Created by Nour  on 5/23/19.
//  Copyright © 2019 Nour . All rights reserved.
//

import XCTest
@testable import NAsyncLoader


extension XMLParser: NAsyncDataType {}

func archive(_ object: NSSecureCoding) -> Data {
    let archiver = NSKeyedArchiver()
    object.encode(with: archiver)
    archiver.finishEncoding()
    return archiver.encodedData
}

class NAsyncLoaderTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    
    
    func testJPG() {
        let loader = NAsyncURLLoader<UIImage>(callbackQueue: DispatchQueue.global())
        let bundle = Bundle(for: type(of: self))
        
        let name = "orange"
        let ext = "jpg"
        
        let path = bundle.path(forResource: name, ofType: ext)!
        let url = bundle.url(forResource: name, withExtension: ext)!
        
        let image = UIImage(contentsOfFile: path)!
        let imageData = archive(image)
        
        let completion = DispatchSemaphore(value: 0)
        
        loader.requestResource(from: url, userData: imageData) {resource, userData             in
            XCTAssertNotNil(userData as? Data)
            switch resource {
            case .success(let received):
                XCTAssertEqual(received.size, image.size)
                XCTAssertEqual(archive(received), imageData)
                if let userData = userData as? Data {
                    XCTAssertEqual(userData, imageData)
                }
            case .empty:
                XCTFail("can't load JPEG from " + url.relativeString)
            case .error(let error):
                XCTFail("Error \(error) while loading from " + url.relativeString)
            }
            completion.signal()
        }
        XCTAssertEqual(completion.wait(timeout: DispatchTime.now() + .seconds(1)), .success)
    }
    
    func testPNG() {
        let loader = NAsyncURLLoader<UIImage>(callbackQueue: DispatchQueue.global())
        let bundle = Bundle(for: type(of: self))
        
        let name = "cherries"
        let ext = "png"
        
        let path = bundle.path(forResource: name, ofType: ext)!
        let url = bundle.url(forResource: name, withExtension: ext)!
        
        let image = UIImage(contentsOfFile: path)!
        let imageData = archive(image)
        
        let completion = DispatchSemaphore(value: 0)
        loader.requestResource(from: url) {resource, _ in
            switch resource {
            case .success(let received):
                XCTAssertEqual(received.size, image.size)
                XCTAssertEqual(archive(received), imageData)
            case .empty:
                XCTFail("can't load PNG from " + url.relativeString)
            case .error(let error):
                XCTFail("Error \(error) while loading from " + url.relativeString)
            }
            completion.signal()
        }
        XCTAssertEqual(completion.wait(timeout: DispatchTime.now() + .seconds(1)), .success)
        
    }
    
    func testXML() {
        
        class TestXMLParser: NSObject, XMLParserDelegate {
            var value = String()
            func parser(_ : XMLParser,
                        didStartElement elementName: String,
                        namespaceURI _: String?,
                        qualifiedName _: String?,
                        attributes _: [String : String]) {
                self.value.append(elementName)
            }
            
            func parser(_ : XMLParser,
                        didEndElement elementName: String,
                        namespaceURI _: String?,
                        qualifiedName _: String?) {
                self.value.append(elementName)
            }
            
            func parser(_ : XMLParser, foundCharacters: String) {
                self.value.append(foundCharacters)
            }
        }
        
        let loader = NAsyncURLLoader<XMLParser>(callbackQueue: DispatchQueue.global())
        let bundle = Bundle(for: type(of: self))
        
        let name = "Info"
        let ext = "plist"
        
        let url = bundle.url(forResource: name, withExtension: ext)!
        let parser = XMLParser(contentsOf: url)!
        let parserDelegate = TestXMLParser()
        parser.delegate = parserDelegate
        parser.parse()
        let xmlContent = parserDelegate.value
        
        let completion = DispatchSemaphore(value: 0)
        loader.requestResource(from: url) {resource, _  in
            switch resource {
            case .success(let received):
                let parserDelegate = TestXMLParser()
                received.delegate = parserDelegate
                received.parse()
                XCTAssertEqual(parserDelegate.value, xmlContent)
            case .empty:
                XCTFail("can't load XML from " + url.relativeString)
            case .error(let error):
                XCTFail("Error \(error) while loading from " + url.relativeString)
            }
            completion.signal()
        }
        XCTAssertEqual(completion.wait(timeout: DispatchTime.now() + .seconds(1)), .success)
    }
    
    
    func testJSONObject() {
        let loader = NAsyncURLLoader<JsonObject>(callbackQueue: DispatchQueue.global())
        let bundle = Bundle(for: type(of: self))
        
        let name = "JSONObject"
        let ext = "json"
        
        let url = bundle.url(forResource: name, withExtension: ext)!
        
        let completion = DispatchSemaphore(value: 0)
        loader.requestResource(from: url) {resource, _  in
            switch resource {
            case .success(let received):
                XCTAssertNotNil(received.value["number"] as? Int)
                XCTAssertNotNil(received.value["string"] as? String)
                XCTAssertNotNil(received.value["bool"] as? Bool)
                XCTAssertNotNil(received.value["empty"] as? NSNull)
            case .empty:
                XCTFail("can't load JSON object from " + url.relativeString)
            case .error(let error):
                XCTFail("Error \(error) while loading from " + url.relativeString)
            }
            completion.signal()
        }
        XCTAssertEqual(completion.wait(timeout: DispatchTime.now() + .seconds(1)), .success)
    }
    
    func testJSONArray() {
        let loader = NAsyncURLLoader<JsonArray>(callbackQueue: DispatchQueue.global())
        let bundle = Bundle(for: type(of: self))
        
        let name = "JSONArray"
        let ext = "json"
        
        let url = bundle.url(forResource: name, withExtension: ext)!
        
        let completion = DispatchSemaphore(value: 0)
        loader.requestResource(from: url) {resource, _  in
            switch resource {
            case .success(let received):
                XCTAssertEqual(received.value.count, 12)
            case .empty:
                XCTFail("can't load JSON object from " + url.relativeString)
            case .error(let error):
                XCTFail("Error \(error) while loading from " + url.relativeString)
            }
            completion.signal()
        }
        XCTAssertEqual(completion.wait(timeout: DispatchTime.now() + .seconds(1)), .success)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
