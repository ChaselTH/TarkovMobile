import SpriteKit

class BaseScene: SKScene {
    private let backButtonName = "backButton"
    private var touchStartPoint: CGPoint?
    private let swipeThreshold: CGFloat = 60
    private let edgeThreshold: CGFloat = 40

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        setupBackArrow()
    }

    func setupBackArrow() {
        childNode(withName: backButtonName)?.removeFromParent()
        let backLabel = SKLabelNode(text: "←")
        backLabel.fontName = "AvenirNext-Bold"
        backLabel.fontSize = 28
        backLabel.fontColor = SKColor(red: 211/255, green: 217/255, blue: 233/255, alpha: 1)
        backLabel.position = CGPoint(x: frame.minX + 32, y: frame.maxY - 48)
        backLabel.horizontalAlignmentMode = .left
        backLabel.verticalAlignmentMode = .center
        backLabel.name = backButtonName
        addChild(backLabel)
    }

    func goBackToMenu() {
        let menuScene = GameScene(size: size)
        menuScene.scaleMode = scaleMode
        let transition = SKTransition.fade(withDuration: 0.3)
        view?.presentScene(menuScene, transition: transition)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let location = touches.first?.location(in: self) {
            touchStartPoint = location
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let location = touches.first?.location(in: self) else { return }

        if let nodeName = nodes(at: location).first(where: { $0.name == backButtonName })?.name, nodeName == backButtonName {
            goBackToMenu()
            return
        }

        if let start = touchStartPoint, start.x <= frame.minX + edgeThreshold {
            let deltaX = location.x - start.x
            if deltaX >= swipeThreshold {
                goBackToMenu()
            }
        }
    }
}
