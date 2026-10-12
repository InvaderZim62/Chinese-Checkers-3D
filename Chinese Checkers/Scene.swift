//
//  Scene.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//
//  SceneKit axes
//       y (height)
//       |
//       |___ x (width)
//      /
//     z (length)
//

import Foundation
import SceneKit

class Scene {
    
    var scnScene: SCNScene!
    var scnView: SCNView!
    var cameraNode: SCNNode!
    
    let defaultLightNode: SCNNode = {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        return lightNode
    }()
    
    let extraLightNode: SCNNode = {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        return lightNode
    }()
    
    let torchLightNode: SCNNode = {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        return lightNode
    }()

    private var view: UIView!  // GameViewController's view

    init(view: UIView) {
        self.view = view
        setupScene()
        setupView()
        setupCamera()
    }
    
    var isShowTorchLight = false {
        didSet {
            defaultLightNode.light?.intensity = isShowTorchLight ? 0 : 500
            extraLightNode.light?.intensity = isShowTorchLight ? 0 : 500
            torchLightNode.light?.intensity = isShowTorchLight ? 500 : 0
        }
    }

    private func setupScene() {
        scnScene = SCNScene()
        scnScene.background.contents = "Background_Diffuse.png"
    }
    
    private func setupView() {
        scnView = view as? SCNView
        scnView.allowsCameraControl = true  // true: allow standard camera controls with panning, false: move camera programmatically
        scnView.autoenablesDefaultLighting = true
        scnView.isPlaying = true  // prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = scnScene
//        scnView.debugOptions = .showPhysicsShapes  // for debugging
//        scnView.debugOptions = .showLightInfluences  // show location of lights
    }

    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        let cameraAngle: Float = 40 * .pi / 180  // position camera 40 degrees above horizon
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, -Float(cameraAngle), 1, 0, 0)
        let cameraDistance = Constant.nominalCameraDistance * (2 * Float(view.bounds.width) / 375.0 - 1)  // iPhone SE is 375 wide
        cameraNode.position = SCNVector3(0, cameraDistance * sin(cameraAngle), cameraDistance * cos(cameraAngle))
        cameraNode.transform = SCNMatrix4Rotate(cameraNode.transform, Float(-0.02), 1, 0, 0)  // rotate camera a little more down, to move room up on screen
        scnScene.rootNode.addChildNode(cameraNode)
//        scnView.allowsCameraControl = false
    }
}
