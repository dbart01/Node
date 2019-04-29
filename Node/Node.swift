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
}

extension Node where X == Void {
    func invoke(completion: @escaping ResultCallback<Y, E>) {
        self.invoke(with: (), completion: completion)
    }
}
