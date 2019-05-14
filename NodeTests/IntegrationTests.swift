//
//  IntegrationTests.swift
//  NodeTests
//
//  Created by Dima Bart on 2019-04-24.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import XCTest
@testable import Node

class IntegrationTests: XCTestCase {
    
    // MARK: - Integration -
    
    func testFetchAndCacheFlow() {
        
        let url = URL(string: "https://date.nager.at/api/v2/PublicHolidays/2019/CA")!
        
        let fetchHolidayCache = Node<Void, [Holiday], Error> { _, completion in
            print("Fetching holiday cache...", terminator: "")
            
            if let holidays = HolidayCache.shared.holidays(for: url.absoluteString) {
                print("success.")
                completion(.success(holidays))
            } else {
                print("failed.")
                completion(.failure(TestError.generic))
            }
        }
        
        let fetchCache = Node<Void, Data, Error> { _, completion in
            print("Fetching from cache...", terminator: "")
            
            if let data = Cache.shared.data(for: url.absoluteString) {
                print("success.")
                completion(.success(data))
            } else {
                print("failed.")
                completion(.failure(TestError.generic))
            }
        }
        
        let fetchRemote = Node<Void, Data, Error> { _, completion in
            print("Fetching remote...", terminator: "")
            
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    print("success.")
                    completion(.success(data))
                } else {
                    print("failed.")
                    completion(.failure(TestError.generic))
                }
            }
            
            task.resume()
        }
        
        let cacheData = Transform<Data, Data> { data, completion in
            print("Saving data to cache.")
            Cache.shared.set(data, for: url.absoluteString)
            completion(data)
        }
        
        let parseData = Node<Data, [[String: Any]], Error> { data, completion in
            print("Parsing data...", terminator: "")
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                print("success.")
                completion(.success(json))
            } else {
                print("failed.")
                completion(.failure(TestError.generic))
            }
        }
        
        let convert = Transform<[[String: Any]], [Holiday]> { jsonArray, completion in
            print("Converting models.")
            let holidays = jsonArray.map {
                Holiday(json: $0)
            }
            completion(holidays)
        }
        
        let persist = Transform<[Holiday], [Holiday]> { holidays, completion in
            print("Persisting holidays.")
            HolidayCache.shared.set(holidays, for: url.absoluteString)
            completion(holidays)
        }
        
        let pipeline = fetchHolidayCache | (fetchCache | (fetchRemote & cacheData)) & parseData & convert & persist
        
        let e1 = expectation(description: "First task")
        print("#1 Started.")
        pipeline.invoke { result in
            print("#1 Finished.")
            e1.fulfill()
        }
        
        wait(for: [e1], timeout: 10.0)
        
        let e2 = expectation(description: "Second task")
        print("#2 Started.")
        pipeline.invoke { result in
            print("#2 Finished.")
            e2.fulfill()
        }
        
        wait(for: [e2], timeout: 10.0)
    }
    
    func testSequencedUnrelatedOperations() {
        
        let e1 = expectation(description: "e1")
        let e2 = expectation(description: "e2")
        let e3 = expectation(description: "e3")
        
        let n1 = Node<Void, Void, TestError> { _, completion in
            completion(.success(()))
            e1.fulfill()
        }
        
        let n2 = Node<Void, Void, TestError> { _, completion in
            completion(.success(()))
            e2.fulfill()
        }
        
        let n3 = Node<Void, Void, TestError> { _, completion in
            completion(.success(()))
            e3.fulfill()
        }
        
        let pipeline = n1 & n2 & n3
        pipeline.invoke()
        
        wait(for: [e1, e2, e3], timeout: 1.0)
    }
    
    // MARK: - Performance -
    
    func testAgressiveComposition() {
        let incremenet = Node<Int, Int, TestError> { input, completion in
            completion(.success(input + 1))
        }
        
        var pipeline = incremenet
        for _ in 0..<1000 {
            pipeline = pipeline & incremenet
        }
        
        pipeline.invoke(with: 1) { result in
            XCTAssertEqual(result, .success(1002))
        }
    }
}

// MARK: - Cache -

private class Cache {
    
    static let shared = Cache()
    
    private let store = NSCache<NSString, NSData>()
    
    private init() {}
    
    func set(_ data: Data, for key: String) {
        self.store.setObject(data as NSData, forKey: key as NSString)
    }
    
    func data(for key: String) -> Data? {
        if let data = self.store.object(forKey: key as NSString) {
            return data as Data
        }
        return nil
    }
}

// MARK: - HolidayCache -

private class HolidayCache {
    
    static let shared = HolidayCache()
    
    private var store: [String: [Holiday]] = [:]
    
    private init() {}
    
    func set(_ holidays: [Holiday], for key: String) {
        self.store[key] = holidays
    }
    
    func holidays(for key: String) -> [Holiday]? {
        return self.store[key]
    }
}

// MARK: - Model -

private struct Holiday: Hashable {
    
    let name:     String
    let type:     String
    let isGlobal: Bool
    
    init(name: String, type: String, isGlobal: Bool) {
        self.name     = name
        self.type     = type
        self.isGlobal = isGlobal
    }
    
    init(json: [String: Any]) {
        self.init(
            name:     json["name"]   as! String,
            type:     json["type"]   as! String,
            isGlobal: json["global"] as! Bool
        )
    }
}
