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
}

extension Transform where X == Void {
    func invoke(completion: @escaping ScalarCallback<Y>) {
        self.invoke(with: (), completion: completion)
    }
}
