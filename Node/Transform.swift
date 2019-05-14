//
//  Transform.swift
//  Node
//
//  Created by Dima Bart on 2019-04-24.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import Foundation

typealias ScalarCallback<Y> = (Y) -> Void

struct Transform<X, Y> {
    
    private let block: (X, @escaping ScalarCallback<Y>) -> Void
    
    init(_ block: @escaping (X, @escaping ScalarCallback<Y>) -> Void) {
        self.block = block
    }
    
    func invoke(with input: X, completion: @escaping ScalarCallback<Y>) {
        self.block(input, completion)
    }
    
    func invokeAndWait(with input: X) -> Y {
        let semaphore = DispatchSemaphore(value: 0)
        
        var output: Y!
        self.invoke(with: input) { result in
            output = result
            semaphore.signal()
        }
        
        semaphore.wait()
        return output
    }
}

extension Transform where X == Void {
    func invoke(completion: @escaping ScalarCallback<Y>) {
        self.invoke(with: (), completion: completion)
    }
    
    func invokeAndWait() -> Y {
        return self.invokeAndWait(with: ())
    }
}

extension Transform where Y == Void {
    func invoke(with input: X) {
        self.invoke(with: input) { _ in }
    }
}

extension Transform where X == Void, Y == Void {
    func invoke() {
        self.invoke { _ in }
    }
}
