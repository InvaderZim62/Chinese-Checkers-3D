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
    
    func createPathThroughSequence(_ moveSequence: [Move], color: UIColor) {
        childNodes.forEach { $0.removeFromParentNode() }
        for move in moveSequence {
//            let plane = SCNPlane(width: move.distance, height: 0.05)
//            plane.firstMaterial?.diffuse.contents = color
////            plane.firstMaterial?.isDoubleSided = true
//            let planeNode = SCNNode(geometry: plane)
//            planeNode.transform = SCNMatrix4Rotate(planeNode.transform, -.pi / 2, 1, 0, 0)  // rotate before setting position
//            planeNode.transform = SCNMatrix4Rotate(planeNode.transform, move.bearing, 0, 0, -1)  // 0 deg along x-axis, 90 deg along z-axis
//            planeNode.position = move.midPoint  // through center of marbles
//            addChildNode(planeNode)
            
            let path = SCNCylinder(radius: Constant.pathRadius, height: move.distance)
            path.firstMaterial?.diffuse.contents = color
            let pathNode = SCNNode(geometry: path)
            pathNode.transform = SCNMatrix4Rotate(pathNode.transform, -.pi / 2, 1, 0, 0)  // rotate before setting position
            pathNode.transform = SCNMatrix4Rotate(pathNode.transform, .pi / 2 - move.bearing, 0, 0, 1)  // 0 deg along x-axis, 90 deg along z-axis
            pathNode.position = move.midPoint  // through center of marbles
            addChildNode(pathNode)
        }
    }

    override init() {
        super.init()
        name = "Path"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
