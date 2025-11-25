import SpriteKit

class InventoryScene: BaseScene {
    private let columns = 12
    private let rows = 60
    private var contentNode = SKNode()
    private var dragStartPoint: CGPoint?
    private var contentStartY: CGFloat = 0
    private var lastTouchLocation: CGPoint?
    private var lastTouchTimestamp: TimeInterval?
    private var velocity: CGFloat = 0
    private var isDecelerating = false
    private var lastUpdateTime: TimeInterval?

    private var scrollAreaHeight: CGFloat {
        size.height * 0.55
    }

    private var cellSize: CGFloat {
        floor(size.width / CGFloat(columns))
    }

    private var contentHeight: CGFloat {
        CGFloat(rows) * cellSize
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 12/255, green: 14/255, blue: 18/255, alpha: 1)
        removeAllChildren()
        super.didMove(to: view)
        setupGrid()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        defer { lastUpdateTime = currentTime }

        guard isDecelerating else { return }
        guard let previousTime = lastUpdateTime else { return }

        let deltaTime = currentTime - previousTime
        let decayRate: CGFloat = 0.975
        let framesPerSecond: CGFloat = 60
        velocity *= pow(decayRate, CGFloat(deltaTime * framesPerSecond))

        let deltaY = velocity * CGFloat(deltaTime)
        let desiredY = contentNode.position.y + deltaY
        let clampedY = clampedContentPosition(for: desiredY)
        contentNode.position.y = clampedY

        let reachedBoundary = clampedY != desiredY
        let velocityIsLow = abs(velocity) < 8
        if reachedBoundary || velocityIsLow {
            isDecelerating = false
            velocity = 0
        }
    }

    private func setupGrid() {
        let cropNode = SKCropNode()
        let mask = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: scrollAreaHeight))
        mask.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        mask.position = .zero
        cropNode.maskNode = mask
        cropNode.position = CGPoint(x: size.width / 2, y: scrollAreaHeight / 2)
        addChild(cropNode)

        contentNode.removeAllChildren()
        cropNode.addChild(contentNode)

        let gridWidth = cellSize * CGFloat(columns)
        let startX = -gridWidth / 2 + cellSize / 2
        let startY = contentHeight / 2 - cellSize / 2

        for row in 0..<rows {
            for column in 0..<columns {
                let square = SKShapeNode(rectOf: CGSize(width: cellSize - 4, height: cellSize - 4), cornerRadius: 4)
                square.fillColor = SKColor(red: 44/255, green: 47/255, blue: 56/255, alpha: 1)
                square.strokeColor = SKColor(red: 85/255, green: 94/255, blue: 108/255, alpha: 1)
                square.lineWidth = 1.5
                square.position = CGPoint(x: startX + CGFloat(column) * cellSize, y: startY - CGFloat(row) * cellSize)
                contentNode.addChild(square)
            }
        }

        contentNode.position = CGPoint(x: 0, y: scrollAreaHeight / 2 - contentHeight / 2)
    }

    private func clampedContentPosition(for desiredY: CGFloat) -> CGFloat {
        let areaHalf = scrollAreaHeight / 2
        let contentHalf = contentHeight / 2
        let maxY = areaHalf - contentHalf
        let minY = contentHalf - areaHalf
        return min(max(desiredY, maxY), minY)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if location.y <= scrollAreaHeight {
            dragStartPoint = location
            contentStartY = contentNode.position.y
            isDecelerating = false
            velocity = 0
            lastTouchLocation = location
            lastTouchTimestamp = touch.timestamp
        } else {
            dragStartPoint = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first, let start = dragStartPoint else { return }
        let location = touch.location(in: self)
        let deltaY = location.y - start.y
        let desiredY = contentStartY + deltaY
        contentNode.position.y = clampedContentPosition(for: desiredY)

        if let lastLocation = lastTouchLocation, let lastTimestamp = lastTouchTimestamp {
            let timeDelta = touch.timestamp - lastTimestamp
            if timeDelta > 0 {
                velocity = (location.y - lastLocation.y) / CGFloat(timeDelta)
            }
        }

        lastTouchLocation = location
        lastTouchTimestamp = touch.timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragStartPoint = nil
        if abs(velocity) > 20 {
            isDecelerating = true
        } else {
            velocity = 0
            isDecelerating = false
        }
        super.touchesEnded(touches, with: event)
    }
}
