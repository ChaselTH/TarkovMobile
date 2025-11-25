//
//  PlaceholderScene.swift
//  TarkovAFK
//
//  Created by 时天昊 on 2025/11/25.
//

import SpriteKit

class PlaceholderScene: BaseScene {

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
        super.didMove(to: view)
        setupTitle()
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
}
