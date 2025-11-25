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

    private let scrollBarWidth: CGFloat = 5
    private let scrollBarInset: CGFloat = 8
    private let scrollBarTrackHeightFactor: CGFloat = 1.0
    private var scrollBarTrack: SKShapeNode?
    private var scrollBarThumb: SKShapeNode?

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

        updateScrollBar()

        let reachedBoundary = clampedY != desiredY
        let velocityIsLow = abs(velocity) < 8
        if reachedBoundary || velocityIsLow {
            isDecelerating = false
            velocity = 0
            scheduleHideScrollBar()
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

        setupScrollBar()
    }

    private func clampedContentPosition(for desiredY: CGFloat) -> CGFloat {
        let areaHalf = scrollAreaHeight / 2
        let contentHalf = contentHeight / 2
        let maxY = areaHalf - contentHalf
        let minY = contentHalf - areaHalf
        return min(max(desiredY, maxY), minY)
    }

    private func setupScrollBar() {
        scrollBarTrack?.removeFromParent()
        scrollBarThumb?.removeFromParent()

        let trackHeight = scrollAreaHeight * scrollBarTrackHeightFactor
        let trackRect = CGRect(x: -scrollBarWidth / 2, y: -trackHeight / 2, width: scrollBarWidth, height: trackHeight)
        let track = SKShapeNode(rect: trackRect, cornerRadius: scrollBarWidth / 2)
        track.fillColor = SKColor(white: 1, alpha: 0.08)
        track.strokeColor = .clear
        track.position = CGPoint(x: size.width - scrollBarInset - scrollBarWidth / 2, y: scrollAreaHeight - trackHeight / 2)
        track.alpha = 0
        addChild(track)
        scrollBarTrack = track

        let thumb = SKShapeNode(rect: trackRect, cornerRadius: scrollBarWidth / 2)
        thumb.fillColor = SKColor(white: 1, alpha: 0.35)
        thumb.strokeColor = .clear
        thumb.position = track.position
        thumb.alpha = 0
        addChild(thumb)
        scrollBarThumb = thumb

        updateScrollBar()
    }

    private func showScrollBar() {
        let fadeIn = SKAction.fadeAlpha(to: 1, duration: 0.15)
        scrollBarTrack?.run(fadeIn, withKey: "fade")
        scrollBarThumb?.run(fadeIn, withKey: "fade")
    }

    private func scheduleHideScrollBar() {
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.fadeAlpha(to: 0, duration: 0.25)
        ])
        scrollBarTrack?.run(fadeOut, withKey: "fade")
        scrollBarThumb?.run(fadeOut, withKey: "fade")
    }

    private func updateScrollBar() {
        guard let track = scrollBarTrack, let thumb = scrollBarThumb else { return }

        guard contentHeight > scrollAreaHeight else {
            track.alpha = 0
            thumb.alpha = 0
            return
        }

        let trackHeight = track.frame.height
        let visibleRatio = scrollAreaHeight / contentHeight
        let thumbHeight = max(trackHeight * visibleRatio, scrollBarWidth * 2)

        thumb.path = CGPath(roundedRect: CGRect(x: -scrollBarWidth / 2, y: -thumbHeight / 2, width: scrollBarWidth, height: thumbHeight), cornerWidth: scrollBarWidth / 2, cornerHeight: scrollBarWidth / 2, transform: nil)

        let areaHalf = scrollAreaHeight / 2
        let contentHalf = contentHeight / 2
        let maxY = areaHalf - contentHalf
        let minY = contentHalf - areaHalf
        let progress = (contentNode.position.y - maxY) / (minY - maxY)
        let availableTravel = trackHeight - thumbHeight
        let thumbOffset = ((1 - progress) * availableTravel) - trackHeight / 2 + thumbHeight / 2
        thumb.position = CGPoint(x: track.position.x, y: track.position.y + thumbOffset)
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
            showScrollBar()
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
        showScrollBar()
        updateScrollBar()

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
            showScrollBar()
        } else {
            velocity = 0
            isDecelerating = false
            scheduleHideScrollBar()
        }
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        scheduleHideScrollBar()
        super.touchesCancelled(touches, with: event)
    }
}
