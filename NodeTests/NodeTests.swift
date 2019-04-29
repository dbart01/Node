//
//  NodeTests.swift
//  NodeTests
//
//  Created by Dima Bart on 2019-04-23.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import XCTest
@testable import Node

class NodeTests: XCTestCase {
    
    // MARK: - Init -
    
    func testInit() {
        let block: (Int, (Result<Int, TestError>) -> Void) -> Void = { x, completion in
            completion(.success(x))
        }
        
        let node = Node(block)
        
        node.invoke(with: 3) { result in
            XCTAssertEqual(result, .success(3))
        }
    }
    
    // MARK: - Convenience Extensions -
    
    func testInvokeInputVoid() {
        let n1 = Node<Void, String, TestError> { _, completion in
            completion(.success("dogs"))
        }
        
        n1.invoke { result in
            XCTAssertEqual(result, .success("dogs"))
        }
    }
    
    func testInvokeInputOutputVoid() {
        let e1 = expectation(description: "e1")
        
        let n1 = Node<Void, Void, TestError> { _, completion in
            completion(.success(()))
            e1.fulfill()
        }
        
        n1.invoke()
        
        wait(for: [e1], timeout: 1.0)
    }
    
    func testSynchronousWait() {
        let n1 = Node<Void, String, TestError> { _, completion in
            DispatchQueue.global().async {
                // Simulate long-running computation
                sleep(1)
                completion(.success("123"))
            }
        }
        
        let result = n1.invokeAndWait()
        XCTAssertEqual(result, .success("123"))
    }
    
    // MARK: - AND (N + N) -

    func testANDComposingMismatchedTypesSuccess() {
        let n1 = Node<Void, Int, TestError> { _, completion in
            completion(.success(3))
        }
        
        let n2 = Node<Int, String, TestError> { input, completion in
            completion(.success(String(input)))
        }
        
        let n3 = n1 & n2
        
        n3.invoke { result in
            XCTAssertEqual(result, .success("3"))
        }
    }
    
    func testANDComposingSameTypesSuccess() {
        let n1 = Node<Int, Int, TestError> { input, completion in
            completion(.success(input + 5))
        }
        
        let n2 = Node<Int, Int, TestError> { input, completion in
            completion(.success(input * 2))
        }
        
        let n3 = n1 & n2
        
        n3.invoke(with: 5) { result in
            XCTAssertEqual(result, .success(20))
        }
    }
    
    func testANDComposingMismatchedTypesFailure() {
        let n1 = Node<Void, Int, TestError> { _, completion in
            completion(.failure(.generic))
        }
        
        let n2 = Node<Int, String, TestError> { input, completion in
            XCTFail()
            completion(.success(String(input)))
        }
        
        let n3 = n1 & n2
        
        n3.invoke { result in
            XCTAssertEqual(result, .failure(.generic))
        }
    }
    
    // MARK: - AND (N + T) -
    
    func testANDComposingTransformationSuccess() {
        let n1 = Node<Void, Int, TestError> { _, completion in
            completion(.success(3))
        }
        
        let t1 = Transform<Int, String> { y, completion in
            completion(String(y))
        }
        
        let n2 = n1 & t1
        
        n2.invoke { result in
            XCTAssertEqual(result, .success("3"))
        }
    }
    
    func testANDComposingTransformationFailure() {
        let n1 = Node<Void, Int, TestError> { _, completion in
            completion(.failure(.generic))
        }
        
        let t1 = Transform<Int, String> { y, completion in
            XCTFail()
            completion(String(y))
        }
        
        let n2 = n1 & t1
        
        n2.invoke { result in
            XCTAssertEqual(result, .failure(.generic))
        }
    }
    
    // MARK: - OR (N + N) -
    
    func testORCompositionFirstSuccess() {
        let n1 = Node<Int, Int, TestError> { input, completion in
            completion(.success(input + 5))
        }
        
        let n2 = Node<Int, Int, TestError> { input, completion in
            XCTFail()
            completion(.success(input * 2))
        }
        
        let n3 = n1 | n2
        
        n3.invoke(with: 2) { result in
            XCTAssertEqual(result, .success(7))
        }
    }
    
    func testORCompositionSecondSuccess() {
        let n1 = Node<Int, Int, TestError> { input, completion in
            completion(.failure(.generic))
        }
        
        let n2 = Node<Int, Int, TestError> { input, completion in
            completion(.success(input * 2))
        }
        
        let n3 = n1 | n2
        
        n3.invoke(with: 2) { result in
            XCTAssertEqual(result, .success(4))
        }
    }
    
    // MARK: - OR (N + T) -
    
    func testORComposingTransformationSuccess() {
        let n1 = Node<Int, Int, TestError> { x, completion in
            completion(.success(x + 5))
        }
        
        let t1 = Transform<Int, Int> { y, completion in
            completion(y * 2)
        }
        
        let n2 = n1 | t1
        
        n2.invoke(with: 2) { result in
            XCTAssertEqual(result, .success(7))
        }
    }
    
    func testORComposingTransformationFailure() {
        let n1 = Node<Int, Int, TestError> { x, completion in
            completion(.failure(.generic))
        }
        
        let t1 = Transform<Int, Int> { y, completion in
            completion(y * 2)
        }
        
        let n2 = n1 | t1
        
        n2.invoke(with: 2) { result in
            XCTAssertEqual(result, .success(4))
        }
    }
}
