//
//  PlaceholderScene.swift
//  TarkovAFK
//
//  Created by 时天昊 on 2025/11/25.
//

import SpriteKit
import UIKit

class PlaceholderScene: SKScene {

    private let titleText: String
    private let backButtonName = "backButton"
    private var edgePanGesture: UIScreenEdgePanGestureRecognizer?

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
        addEdgePanGesture(to: view)
    }

    override func willMove(from view: SKView) {
        if let gesture = edgePanGesture {
            view.removeGestureRecognizer(gesture)
        }
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
        let backButton = SKLabelNode(text: "←")
        backButton.fontName = "AvenirNext-Bold"
        backButton.fontSize = 28
        backButton.fontColor = SKColor(red: 198/255, green: 210/255, blue: 226/255, alpha: 1)
        backButton.position = CGPoint(x: 30, y: frame.maxY - 50)
        backButton.name = backButtonName
        backButton.horizontalAlignmentMode = .left
        backButton.verticalAlignmentMode = .center
        addChild(backButton)
    }

    private func addEdgePanGesture(to view: SKView) {
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        edgePanGesture = edgePan
    }

    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            goBackToMenu()
        }
    }

    private func goBackToMenu() {
        let menuScene = GameScene(size: size)
        menuScene.scaleMode = scaleMode
        let transition = SKTransition.push(with: .left, duration: 0.3)
        view?.presentScene(menuScene, transition: transition)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint where node.name == backButtonName {
            goBackToMenu()
            return
        }
    }
}
