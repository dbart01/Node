//
//  Node+Composition.swift
//  Node
//
//  Created by Dima Bart on 2019-04-24.
//  Copyright © 2019 Dima Bart. All rights reserved.
//

import Foundation

// MARK: - AND -

extension Node {
    
    func and<Z>(_ node: Node<Y, Z, E>) -> Node<X, Z, E> {
        return Node<X, Z, E> { x, completion in
            self.invoke(with: x) { result in
                switch result {
                case .success(let y):
                    node.invoke(with: y, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func and<Z>(_ transform: Transform<Y, Z>) -> Node<X, Z, E> {
        return Node<X, Z, E> { x, completion in
            self.invoke(with: x) { result in
                switch result {
                case .success(let y):
                    transform.invoke(with: y) { z in
                        completion(.success(z))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

func & <X, Y, Z, E>(lhs: Node<X, Y, E>, rhs: Node<Y, Z, E>) -> Node<X, Z, E> where E: Error {
    return lhs.and(rhs)
}

func & <X, Y, Z, E>(lhs: Node<X, Y, E>, rhs: Transform<Y, Z>) -> Node<X, Z, E> where E: Error {
    return lhs.and(rhs)
}

// MARK: - OR -

extension Node {
    
    func or(_ node: Node) -> Node {
        return Node { x, completion in
            self.invoke(with: x) { result in
                switch result {
                case .success(let y):
                    completion(.success(y))
                case .failure:
                    node.invoke(with: x, completion: completion)
                }
            }
        }
    }
    
    func or(_ node: Transform<X, Y>) -> Node {
        return Node { x, completion in
            self.invoke(with: x) { result in
                switch result {
                case .success(let y):
                    completion(.success(y))
                case .failure:
                    node.invoke(with: x, completion: { y in
                        completion(.success(y))
                    })
                }
            }
        }
    }
}

func | <X, Y, E>(lhs: Node<X, Y, E>, rhs: Node<X, Y, E>) -> Node<X, Y, E> where E: Error {
    return lhs.or(rhs)
}

func | <X, Y, E>(lhs: Node<X, Y, E>, rhs: Transform<X, Y>) -> Node<X, Y, E> where E: Error {
    return lhs.or(rhs)
}
