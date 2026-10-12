//
//  BoardNode.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import UIKit
import SceneKit

class BoardNode: SCNNode {
    
    override init() {
        super.init()
        name = "Board"
        
        let fileName = "art.scnassets/board.scn"
        let scene = SCNScene(named: fileName)!
        let boardNode = scene.rootNode.childNode(withName: "board", recursively: true)!
        
        geometry = boardNode.geometry
        // concave makes physics body hug geometry
        // from: https://stackoverflow.com/a/43166708/2526464
        let options = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
        physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: boardNode, options: options))
//        physicsBody?.friction = 1.0  // 0: slippery, 1: sticky (default: 0.5)
        physicsBody?.restitution = 0.0  // 0: inelastic, 1: perfectly elastic (default: 0.5)
        physicsBody?.categoryBitMask = ContactCategory.board
        physicsBody?.collisionBitMask = ContactCategory.marble | ContactCategory.board
//        physicsBody?.contactTestBitMask = ContactCategory.marble | ContactCategory.board  // also added part to marble bit mask
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
