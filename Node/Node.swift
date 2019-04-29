//
//  Node.swift
//  Node
//
//  Created by Dima Bart on 2019-04-23.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import Foundation

typealias ResultCallback<Y, E: Error> = (Result<Y, E>) -> Void

struct Node<X, Y, E> where E: Error {

    private let block: (X, @escaping ResultCallback<Y, E>) -> Void

    init(_ block: @escaping (X, @escaping ResultCallback<Y, E>) -> Void) {
        self.block = block
    }

    func invoke(with input: X, completion: @escaping ResultCallback<Y, E>) {
        self.block(input, completion)
    }
    
    func invokeAndWait(with input: X) -> Result<Y, E> {
        let semaphore = DispatchSemaphore(value: 0)
        
        var output: Result<Y, E>!
        self.invoke(with: input) { result in
            output = result
            semaphore.signal()
        }
        
        semaphore.wait()
        return output
    }
}

extension Node where X == Void {
    func invoke(completion: @escaping ResultCallback<Y, E>) {
        self.invoke(with: (), completion: completion)
    }
    
    func invokeAndWait() -> Result<Y, E> {
        return self.invokeAndWait(with: ())
    }
}

extension Node where X == Void, Y == Void {
    func invoke() {
        self.invoke { _ in }
    }
}
