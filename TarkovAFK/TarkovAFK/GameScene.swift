//
//  GameScene.swift
//  TarkovAFK
//
//  Created by 时天昊 on 2025/11/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {

    private enum MenuItem: String, CaseIterable {
        case escape = "逃离"
        case trading = "交易"
        case inventory = "仓库"
        case hideout = "藏身处"
    }

    private var buttonNodes: [MenuItem: SKLabelNode] = [:]
    private let logoText = "TarkovAFK"

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 18/255, green: 19/255, blue: 24/255, alpha: 1)
        removeAllChildren()
        setupLogo()
        setupButtons()
    }

    private func setupLogo() {
        let logoLabel = SKLabelNode(text: logoText)
        logoLabel.fontName = "AvenirNext-Bold"
        logoLabel.fontSize = 48
        logoLabel.fontColor = SKColor.white
        logoLabel.position = CGPoint(x: frame.midX, y: frame.midY + 180)
        logoLabel.horizontalAlignmentMode = .center
        logoLabel.verticalAlignmentMode = .center
        addChild(logoLabel)
    }

    private func setupButtons() {
        let spacing: CGFloat = 70
        let startY = frame.midY + spacing
        for (index, item) in MenuItem.allCases.enumerated() {
            let button = SKLabelNode(text: item.rawValue)
            button.fontName = "AvenirNext-Medium"
            button.fontSize = 32
            button.fontColor = SKColor(red: 198/255, green: 210/255, blue: 226/255, alpha: 1)
            button.position = CGPoint(x: frame.midX, y: startY - CGFloat(index) * spacing)
            button.name = item.rawValue
            button.horizontalAlignmentMode = .center
            button.verticalAlignmentMode = .center
            buttonNodes[item] = button
            addChild(button)
        }
    }

    private func presentPlaceholder(for item: MenuItem) {
        let nextScene: SKScene
        switch item {
        case .inventory:
            nextScene = InventoryScene(size: size)
        default:
            nextScene = PlaceholderScene(size: size, title: item.rawValue)
        }

        nextScene.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(nextScene, transition: transition)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self) else { return }
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            if let name = node.name, let item = MenuItem(rawValue: name) {
                presentPlaceholder(for: item)
                return
            }
        }
    }
}
