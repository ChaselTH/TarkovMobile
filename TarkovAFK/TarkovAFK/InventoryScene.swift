//
//  InventoryScene.swift
//  TarkovAFK
//
//  Created by 时天昊 on 2025/11/25.
//

import SpriteKit
import UIKit

class InventoryScene: SKScene {

    private let backButtonName = "backButton"
    private var edgePanGesture: UIScreenEdgePanGestureRecognizer?
    private let columns = 12
    private let rows = 60
    private let horizontalMargin: CGFloat = 20
    private let cellSpacing: CGFloat = 4
    private var gridContainer = SKNode()
    private var gridMaskSize: CGSize = .zero
    private var minOffsetY: CGFloat = 0
    private var maxOffsetY: CGFloat = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 12/255, green: 14/255, blue: 18/255, alpha: 1)
        removeAllChildren()

        setupBackArrow()
        setupLayout()
        addEdgePanGesture(to: view)
    }

    override func willMove(from view: SKView) {
        if let gesture = edgePanGesture {
            view.removeGestureRecognizer(gesture)
        }
    }

    private func setupBackArrow() {
        let arrowLabel = SKLabelNode(text: "←")
        arrowLabel.fontName = "AvenirNext-Bold"
        arrowLabel.fontSize = 28
        arrowLabel.fontColor = SKColor(red: 198/255, green: 210/255, blue: 226/255, alpha: 1)
        arrowLabel.position = CGPoint(x: 30, y: size.height - 50)
        arrowLabel.horizontalAlignmentMode = .left
        arrowLabel.verticalAlignmentMode = .center
        arrowLabel.name = backButtonName
        addChild(arrowLabel)
    }

    private func setupLayout() {
        let topReservedHeight = size.height * 0.35
        gridMaskSize = CGSize(width: size.width - horizontalMargin * 2,
                              height: size.height - topReservedHeight - horizontalMargin)

        let maskNode = SKSpriteNode(color: .white, size: gridMaskSize)
        maskNode.position = CGPoint(x: 0, y: 0)

        let cropNode = SKCropNode()
        cropNode.maskNode = maskNode
        cropNode.position = CGPoint(x: size.width / 2, y: horizontalMargin + gridMaskSize.height / 2)
        addChild(cropNode)

        gridContainer = SKNode()
        gridContainer.position = CGPoint(x: -gridMaskSize.width / 2, y: -gridMaskSize.height / 2)
        cropNode.addChild(gridContainer)

        buildGrid()
    }

    private func buildGrid() {
        let availableWidth = gridMaskSize.width
        let totalSpacing = CGFloat(columns - 1) * cellSpacing
        let cellSize = (availableWidth - totalSpacing) / CGFloat(columns)
        let contentHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * cellSpacing

        maxOffsetY = 0
        minOffsetY = gridMaskSize.height - contentHeight

        for row in 0..<rows {
            for col in 0..<columns {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 4)
                cell.fillColor = SKColor(red: 63/255, green: 69/255, blue: 80/255, alpha: 1)
                cell.strokeColor = SKColor(red: 94/255, green: 103/255, blue: 115/255, alpha: 1)
                cell.lineWidth = 1.5

                let x = cellSize / 2 + CGFloat(col) * (cellSize + cellSpacing)
                let y = contentHeight - cellSize / 2 - CGFloat(row) * (cellSize + cellSpacing)
                cell.position = CGPoint(x: x, y: y)
                gridContainer.addChild(cell)
            }
        }

        gridContainer.position.y = min(minOffsetY, maxOffsetY)
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

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let previous = touch.previousLocation(in: self)
        let current = touch.location(in: self)
        let deltaY = current.y - previous.y

        let proposedY = gridContainer.position.y + deltaY
        gridContainer.position.y = max(minOffsetY, min(maxOffsetY, proposedY))
    }
}

