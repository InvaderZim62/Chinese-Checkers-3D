//
//  ContactNode.swift
//  DnDDice
//
//  Created by Phil Stern on 3/20/25.
//

import UIKit
import SceneKit

class ContactNode: SCNNode {
    
    init(part: String, isSoundMaking: Bool, isConcave: Bool) {
        super.init()
        name = part
        let fileName = "art.scnassets/\(part).scn"
        let scene = SCNScene(named: fileName)!
        let partNode = scene.rootNode.childNode(withName: part, recursively: true)!
        
        geometry = partNode.geometry
        // if concave, make physics body hug geometry (otherwise it uses a simple shape to enclose it)
        //   from: https://stackoverflow.com/a/43166708/2526464
        var options: [SCNPhysicsShape.Option: Any]?
        if isConcave {
            options = [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
        } else {
            options = [:]
        }
        physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: partNode, options: options))
//        physicsBody?.friction = 1.0  // 0: slippery, 1: sticky (default: 0.5)
//        physicsBody?.restitution = 0.0  // 0: inelastic, 1: perfectly elastic (default: 0.5)
//        physicsBody?.categoryBitMask = isSoundMaking ? ContactCategory.hardSurface : ContactCategory.softSurface
//        physicsBody?.contactTestBitMask = ContactCategory.die  // add both hardSurface and softSurface to DieNode contactBitMask
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
