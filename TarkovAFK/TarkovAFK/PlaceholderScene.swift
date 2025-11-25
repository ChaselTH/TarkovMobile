//
//  PlaceholderScene.swift
//  TarkovAFK
//
//  Created by 时天昊 on 2025/11/25.
//

import SpriteKit

class PlaceholderScene: SKScene {

    private let titleText: String

    init(size: CGSize, title: String) {
        self.titleText = title
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.titleText = ""
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 12/255, green: 14/255, blue: 18/255, alpha: 1)
        removeAllChildren()
        setupTitle()
        setupBackButton()
    }

    private func setupTitle() {
        let label = SKLabelNode(text: titleText)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 40
        label.fontColor = SKColor(red: 211/255, green: 217/255, blue: 233/255, alpha: 1)
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        addChild(label)
    }

    private func setupBackButton() {
        let backButton = SKLabelNode(text: "返回")
        backButton.fontName = "AvenirNext-DemiBold"
        backButton.fontSize = 24
        backButton.fontColor = SKColor(red: 137/255, green: 196/255, blue: 244/255, alpha: 1)
        backButton.position = CGPoint(x: frame.midX, y: frame.midY - 100)
        backButton.name = "backButton"
        backButton.horizontalAlignmentMode = .center
        backButton.verticalAlignmentMode = .center
        addChild(backButton)
    }

    private func goBackToMenu() {
        let menuScene = GameScene(size: size)
        menuScene.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(menuScene, transition: transition)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint where node.name == "backButton" {
            goBackToMenu()
            return
        }
    }
}
