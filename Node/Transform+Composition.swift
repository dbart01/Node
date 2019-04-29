//
//  Transform+Composition.swift
//  Node
//
//  Created by Dima Bart on 2019-04-24.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import Foundation

// MARK: - AND -

extension Transform {
    
    func and<Z, E>(_ node: Node<Y, Z, E>) -> Node<X, Z, E> {
        return Node<X, Z, E> { x, completion in
            self.invoke(with: x) { y in
                node.invoke(with: y, completion: completion)
            }
        }
    }
    
    func and<Z>(_ transform: Transform<Y, Z>) -> Transform<X, Z> {
        return Transform<X, Z> { x, completion in
            self.invoke(with: x) { y in
                transform.invoke(with: y, completion: completion)
            }
        }
    }
}

func & <X, Y, Z>(lhs: Transform<X, Y>, rhs: Transform<Y, Z>) -> Transform<X, Z> {
    return lhs.and(rhs)
}

func & <X, Y, Z, E>(lhs: Transform<X, Y>, rhs: Node<Y, Z, E>) -> Node<X, Z, E> where E: Error {
    return lhs.and(rhs)
}

// MARK: - OR -

///  For `Transform` 'OR' composition is not a rational option. Execution proceeds
///  to the next `Transform` or `Node` if invocation of this `Transform` fails.
///  Since a `Transform` cannot fail, conceptually, 'OR' composition that originates
///  with a `Transform` does not make sense.
///
///  func | <X, Y>(lhs: Transform<X, Y>, rhs: Transform<X, Y>) -> Transform<X, Y> {
///      return lhs.or(rhs)
///  }
