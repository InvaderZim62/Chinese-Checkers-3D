//
//  PathNode.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/20/26.
//
//  Note: SCNCylinder nodes are aligned with the y-axis.
//
//  SceneKit axes
//       y (height) green
//       |
//       |___ x (width) red
//      /
//     z (length) blue
//

import UIKit
import SceneKit

class PathNode: SCNNode {
    
    let globalData = GlobalData.shared
    
    func createPathThroughSequence(_ moveSequence: [Move], color: UIColor = .clear) {
        childNodes.forEach { $0.removeFromParentNode() }
        for move in moveSequence {
            let path = SCNTorus(ringRadius: move.distance / 2, pipeRadius: Constant.pathRadius)
            path.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.7)
            let pathNode = SCNNode(geometry: path)
            pathNode.transform = SCNMatrix4Rotate(pathNode.transform, -.pi / 2, 1, 0, 0)  // rotate before setting position
            pathNode.transform = SCNMatrix4Rotate(pathNode.transform, -move.bearing, 0, 0, 1)  // 0 deg along x-axis, 90 deg along z-axis
            pathNode.position = move.midPoint - SCNVector3(x: 0, y: 0.1, z: 0)
            addChildNode(pathNode)
            opacity = 1
        }
    }
    
    func clearSequencePath() {
        createPathThroughSequence([])
    }

    override init() {
        super.init()
        name = "Path"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
