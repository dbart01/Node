//
//  TransformTests.swift
//  NodeTests
//
//  Created by Dima Bart on 2019-04-24.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import XCTest
@testable import Node

class TransformTests: XCTestCase {

    // MARK: - Init -
    
    func testInit() {
        let block: (Int, (Int) -> Void) -> Void = { x, completion in
            return completion(x)
        }
        
        let transform = Transform(block)
        
        transform.invoke(with: 3) { y in
            XCTAssertEqual(y, 3)
        }
    }
    
    // MARK: - Wait -
    
    func testSynchronousWait() {
        let t1 = Transform<Void, String> { _, completion in
            DispatchQueue.global().async {
                // Simulate long-running computation
                sleep(1)
                completion("123")
            }
        }
        
        let result = t1.invokeAndWait()
        XCTAssertEqual(result, "123")
    }
    
    // MARK: - AND (T + T) -
    
    func testANDComposingTransformations() {
        let t1 = Transform<Void, Int> { _, completion in
            completion(3)
        }
        
        let t2 = Transform<Int, String> { input, completion in
            completion(String(input))
        }
        
        let t3 = t1 & t2
        
        t3.invoke { result in
            XCTAssertEqual(result, "3")
        }
    }
    
    // MARK: - AND (T + N) -
    
    func testANDComposingTransformationNodeSuccess() {
        let t1 = Transform<Int, Int> { x, completion in
            completion(x * 2)
        }
        
        let n1 = Node<Int, Data, TestError> { y, completion in
            let string = String(y)
            if let data = string.data(using: .utf8) {
                completion(.success(data))
            } else {
                completion(.failure(.generic))
            }
        }
        
        let n2 = t1 & n1
        
        n2.invoke(with: 5) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, "10".data(using: .utf8))
            case .failure:
                XCTFail()
            }
        }
    }
}
