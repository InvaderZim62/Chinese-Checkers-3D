//
//  Hud.swift
//  Chinese Checkers
//
//  Created by Phil Stern on 10/11/26.
//

import Foundation
import SpriteKit
import SceneKit

class Hud: SKScene {
    
    var winner: Player? = nil {
        didSet {
            updateMessage()
        }
    }
    
    // callbacks
    var restartSelected: (() -> Void)?
    var touchedHudAt: ((CGPoint) -> Void)?  // callback used to pass touch location to GameViewController

    private var messageLabel: SKLabelNode = {
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontColor = .lightGray
        labelNode.fontSize = 32
        labelNode.isHidden = true
        return labelNode
    }()

    private var restartLabel: SKLabelNode = {
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontColor = .lightGray
        labelNode.fontSize = 22
        labelNode.text = "Restart"
        return labelNode
    }()

    func setup(restartCallback: @escaping () -> Void,
               touchHandler: @escaping (CGPoint) -> Void) {
        
        restartSelected = restartCallback
        touchedHudAt = touchHandler

        messageLabel.position = CGPoint(x: frame.midX, y: 0.85 * frame.height)
        addChild(messageLabel)

        restartLabel.position = CGPoint(x: frame.midX, y: 30)
        addChild(restartLabel)
    }
    
    private func updateMessage() {
        messageLabel.isHidden = winner == nil
        if let winner {
            messageLabel.text = winner == .computer ? "Computer Wins!" : "You Win!"
        }
    }

    // call callback when rotation labels touched
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        if restartLabel.contains(location) {
            restartSelected?()
        } else {
            touchedHudAt?(location)
        }
    }
}
