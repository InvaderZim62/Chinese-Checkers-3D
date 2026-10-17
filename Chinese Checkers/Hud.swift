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
    var difficultySelected: (() -> Void)?
    var restartSelected: (() -> Void)?
    var touchedHudAt: ((CGPoint) -> Void)?  // callback used to pass touch location to GameViewController

    static var regularAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Helvetica-Bold", size: 22)!,
        .foregroundColor: UIColor.lightGray]
    
    static var underlineAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Helvetica-Bold", size: 22)!,
        .foregroundColor: UIColor.white,
        .underlineStyle: NSUnderlineStyle.thick.rawValue]

    var isHardPlay = false {
        didSet {
            // underline selected label, remove underline from other label
            let mediumString = NSAttributedString(string: "Medium", attributes: isHardPlay ? Hud.regularAttributes : Hud.underlineAttributes)
            mediumLabel.attributedText = mediumString
            
            let hardString = NSAttributedString(string: "Hard", attributes: isHardPlay ? Hud.underlineAttributes : Hud.regularAttributes)
            hardLabel.attributedText = hardString
        }
    }
    
    private var mediumLabel = SKLabelNode()
    private var hardLabel = SKLabelNode()

    private var messageLabel: SKLabelNode = {
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontColor = .white
        labelNode.fontSize = 32
        labelNode.isHidden = true
        return labelNode
    }()

    private var restartLabel: SKLabelNode = {
        let labelNode = SKLabelNode(fontNamed: "Helvetica-Bold")
        labelNode.fontColor = .white
        labelNode.fontSize = 22
        labelNode.text = "Restart"
        return labelNode
    }()
    
    func setup(difficultyHandler: @escaping () -> Void,
               restartHandler: @escaping () -> Void,
               touchHandler: @escaping (CGPoint) -> Void) {
        
        difficultySelected = difficultyHandler
        restartSelected = restartHandler
        touchedHudAt = touchHandler
        
        isHardPlay = false
        
        mediumLabel.position = CGPoint(x: frame.midX - 50, y: 90)
        addChild(mediumLabel)
        
        hardLabel.position = CGPoint(x: frame.midX + 60, y: 90)
        addChild(hardLabel)

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
        if mediumLabel.contains(location) {
            isHardPlay = false
            difficultySelected?()
        } else if hardLabel.contains(location) {
            isHardPlay = true
            difficultySelected?()
        } else if restartLabel.contains(location) {
            restartSelected?()
        } else {
            touchedHudAt?(location)
        }
    }
}
