import SpriteKit

class InventoryScene: BaseScene {
    struct GridPosition: Equatable {
        var column: Int
        var row: Int
    }

    struct GridSize {
        var width: Int
        var height: Int
    }

    private class InventoryItemNode: SKNode {
        let gridSize: GridSize
        var gridPosition: GridPosition
        private let sprite: SKSpriteNode
        private let highlight: SKShapeNode
        private var targetSize: CGSize
        private let padding: CGFloat = 6
        private let trimmedTextureSize: CGSize

        init(textureName: String, gridSize: GridSize, cellSize: CGFloat, gridPosition: GridPosition) {
            self.gridSize = gridSize
            self.gridPosition = gridPosition
            let originalTexture = SKTexture(imageNamed: textureName)
            let (trimmedTexture, trimmedSize) = InventoryItemNode.trimmedTexture(from: originalTexture)
            trimmedTextureSize = trimmedSize
            targetSize = InventoryItemNode.targetSize(for: gridSize, cellSize: cellSize)

            sprite = SKSpriteNode(texture: trimmedTexture)
            sprite.size = InventoryItemNode.fittedSize(for: trimmedSize, in: targetSize, padding: padding)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            sprite.zPosition = 10

            highlight = SKShapeNode(rectOf: targetSize, cornerRadius: 4)
            highlight.strokeColor = .white
            highlight.lineWidth = 3
            highlight.fillColor = .clear
            highlight.isHidden = true
            highlight.zPosition = 11

            super.init()
            addChild(sprite)
            addChild(highlight)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setHighlighted(_ highlighted: Bool) {
            highlight.isHidden = !highlighted
        }

        func setDraggingStyle(_ isDragging: Bool) {
            alpha = isDragging ? 0.7 : 1
        }

        func updateSize(with cellSize: CGFloat) {
            targetSize = InventoryItemNode.targetSize(for: gridSize, cellSize: cellSize)
            sprite.size = InventoryItemNode.fittedSize(for: trimmedTextureSize, in: targetSize, padding: padding)
            highlight.path = CGPath(roundedRect: CGRect(origin: CGPoint(x: -targetSize.width / 2, y: -targetSize.height / 2), size: targetSize), cornerWidth: 4, cornerHeight: 4, transform: nil)
        }

        private static func targetSize(for gridSize: GridSize, cellSize: CGFloat) -> CGSize {
            CGSize(width: cellSize * CGFloat(gridSize.width), height: cellSize * CGFloat(gridSize.height))
        }

        private static func fittedSize(for contentSize: CGSize, in targetSize: CGSize, padding: CGFloat) -> CGSize {
            let availableWidth = max(targetSize.width - padding, 0)
            let availableHeight = max(targetSize.height - padding, 0)
            guard contentSize.width > 0, contentSize.height > 0 else {
                return CGSize(width: availableWidth, height: availableHeight)
            }

            let widthRatio = availableWidth / contentSize.width
            let heightRatio = availableHeight / contentSize.height
            let scale = min(widthRatio, heightRatio)
            return CGSize(width: contentSize.width * scale, height: contentSize.height * scale)
        }

        private static func trimmedTexture(from texture: SKTexture) -> (SKTexture, CGSize) {
            guard let cgImage = texture.cgImage() else {
                return (texture, texture.size())
            }

            guard let dataProvider = cgImage.dataProvider, let data = dataProvider.data, let bytes = CFDataGetBytePtr(data) else {
                return (texture, texture.size())
            }

            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = cgImage.bytesPerRow

            var minX = width
            var minY = height
            var maxX = 0
            var maxY = 0

            for y in 0..<height {
                let rowStart = y * bytesPerRow
                for x in 0..<width {
                    let index = rowStart + x * bytesPerPixel
                    let alpha = bytes[index + 3]
                    if alpha > 5 {
                        minX = min(minX, x)
                        minY = min(minY, y)
                        maxX = max(maxX, x)
                        maxY = max(maxY, y)
                    }
                }
            }

            if maxX < minX || maxY < minY {
                return (texture, texture.size())
            }

            let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
            guard let trimmedImage = cgImage.cropping(to: cropRect) else {
                return (texture, texture.size())
            }

            let trimmedTexture = SKTexture(cgImage: trimmedImage)
            return (trimmedTexture, CGSize(width: cropRect.width, height: cropRect.height))
        }
    }

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

    private var gridCells: [[SKShapeNode]] = []
    private var occupied: [[InventoryItemNode?]] = []
    private var items: [InventoryItemNode] = []
    private var selectedItem: InventoryItemNode?
    private var draggingItem: InventoryItemNode?
    private var dragOffset: CGPoint = .zero
    private var originalGridPosition: GridPosition?
    private var pendingGridPosition: GridPosition?
    private var dropPreviewNodes: [SKShapeNode] = []

    private var startX: CGFloat = 0
    private var startY: CGFloat = 0

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
        startX = -gridWidth / 2 + cellSize / 2
        startY = contentHeight / 2 - cellSize / 2

        gridCells = []
        occupied = Array(repeating: Array(repeating: nil, count: columns), count: rows)

        for row in 0..<rows {
            var rowNodes: [SKShapeNode] = []
            for column in 0..<columns {
                let square = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize), cornerRadius: 0)
                square.fillColor = SKColor(red: 44/255, green: 47/255, blue: 56/255, alpha: 1)
                square.strokeColor = SKColor(red: 85/255, green: 94/255, blue: 108/255, alpha: 1)
                square.lineWidth = 1.5
                square.position = CGPoint(x: startX + CGFloat(column) * cellSize, y: startY - CGFloat(row) * cellSize)
                contentNode.addChild(square)
                rowNodes.append(square)
            }
            gridCells.append(rowNodes)
        }

        contentNode.position = CGPoint(x: 0, y: scrollAreaHeight / 2 - contentHeight / 2)

        setupScrollBar()
        addInitialItems()
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
        let contentLocation = convert(location, to: contentNode)

        if let item = item(at: contentLocation) {
            select(item)
            beginDragging(item, touchLocation: contentLocation)
            dragStartPoint = nil
            return
        }

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
        guard let touch = touches.first else { return }

        if let draggingItem = draggingItem {
            let contentLocation = convert(touch.location(in: self), to: contentNode)
            let targetCenter = CGPoint(x: contentLocation.x - dragOffset.x, y: contentLocation.y - dragOffset.y)
            draggingItem.position = targetCenter
            let proposedPosition = clampedGridPosition(gridPosition(for: draggingItem, centeredAt: targetCenter), for: draggingItem)
            pendingGridPosition = proposedPosition
            updateDropPreview(for: draggingItem, at: proposedPosition)
            return
        }

        guard let start = dragStartPoint else { return }
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
        if let draggingItem = draggingItem {
            completeDrag(for: draggingItem)
            return
        }

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
        if let draggingItem = draggingItem {
            revertDrag(for: draggingItem)
        }
        scheduleHideScrollBar()
        super.touchesCancelled(touches, with: event)
    }

    private func addInitialItems() {
        let moonshine = InventoryItemNode(textureName: "FierceMoonshine", gridSize: GridSize(width: 1, height: 2), cellSize: cellSize, gridPosition: GridPosition(column: 2, row: 2))
        place(item: moonshine, at: moonshine.gridPosition)
        items.append(moonshine)
        
        let icedGreenTea = InventoryItemNode(textureName: "IcedGreenTea", gridSize: GridSize(width: 1, height: 1), cellSize: cellSize, gridPosition: GridPosition(column: 4, row: 2))
        place(item: icedGreenTea, at: icedGreenTea.gridPosition)
        items.append(icedGreenTea)

        let pureWater = InventoryItemNode(textureName: "PureWater", gridSize: GridSize(width: 2, height: 2), cellSize: cellSize, gridPosition: GridPosition(column: 6, row: 2))
        place(item: pureWater, at: pureWater.gridPosition)
        items.append(pureWater)
    }

    private func point(for position: GridPosition, size: GridSize) -> CGPoint {
        let centerX = startX + (CGFloat(position.column) + CGFloat(size.width) / 2 - 0.5) * cellSize
        let centerY = startY - (CGFloat(position.row) + CGFloat(size.height) / 2 - 0.5) * cellSize
        return CGPoint(x: centerX, y: centerY)
    }

    private func place(item: InventoryItemNode, at position: GridPosition) {
        item.gridPosition = position
        item.position = point(for: position, size: item.gridSize)
        if item.parent !== contentNode {
            item.removeFromParent()
            contentNode.addChild(item)
        }
        occupyCells(for: item, at: position)
    }

    private func gridPosition(for item: InventoryItemNode, centeredAt point: CGPoint) -> GridPosition {
        let colValue = (point.x - startX) / cellSize - (CGFloat(item.gridSize.width) / 2 - 0.5)
        let rowValue = (startY - point.y) / cellSize - (CGFloat(item.gridSize.height) / 2 - 0.5)
        return GridPosition(column: Int(round(colValue)), row: Int(round(rowValue)))
    }

    private func clampedGridPosition(_ position: GridPosition, for item: InventoryItemNode) -> GridPosition {
        let maxColumn = columns - item.gridSize.width
        let maxRow = rows - item.gridSize.height
        let clampedColumn = min(max(position.column, 0), maxColumn)
        let clampedRow = min(max(position.row, 0), maxRow)
        return GridPosition(column: clampedColumn, row: clampedRow)
    }

    private func occupyCells(for item: InventoryItemNode, at position: GridPosition) {
        for row in position.row..<(position.row + item.gridSize.height) {
            for column in position.column..<(position.column + item.gridSize.width) {
                occupied[row][column] = item
                let cell = gridCells[row][column]
                cell.strokeColor = .clear
            }
        }
    }

    private func clearCells(for item: InventoryItemNode) {
        for row in 0..<rows {
            for column in 0..<columns {
                if occupied[row][column] === item {
                    occupied[row][column] = nil
                    let cell = gridCells[row][column]
                    cell.strokeColor = SKColor(red: 85/255, green: 94/255, blue: 108/255, alpha: 1)
                }
            }
        }
    }

    private func canPlace(item: InventoryItemNode, at position: GridPosition) -> Bool {
        guard position.column >= 0, position.row >= 0 else { return false }
        guard position.column + item.gridSize.width <= columns else { return false }
        guard position.row + item.gridSize.height <= rows else { return false }

        for row in position.row..<(position.row + item.gridSize.height) {
            for column in position.column..<(position.column + item.gridSize.width) {
                if let occupant = occupied[row][column], occupant !== item {
                    return false
                }
            }
        }
        return true
    }

    private func item(at location: CGPoint) -> InventoryItemNode? {
        for node in contentNode.nodes(at: location) {
            if let item = node as? InventoryItemNode {
                return item
            }
            if let parent = node.parent as? InventoryItemNode {
                return parent
            }
        }
        return nil
    }

    private func select(_ item: InventoryItemNode) {
        selectedItem?.setHighlighted(false)
        item.setHighlighted(true)
        selectedItem = item
    }

    private func beginDragging(_ item: InventoryItemNode, touchLocation: CGPoint) {
        draggingItem = item
        dragOffset = CGPoint(x: touchLocation.x - item.position.x, y: touchLocation.y - item.position.y)
        originalGridPosition = item.gridPosition
        pendingGridPosition = item.gridPosition
        item.setDraggingStyle(true)
        clearCells(for: item)
        updateDropPreview(for: item, at: item.gridPosition)
    }

    private func completeDrag(for item: InventoryItemNode) {
        guard let target = pendingGridPosition else {
            revertDrag(for: item)
            return
        }

        if canPlace(item: item, at: target) {
            place(item: item, at: target)
        } else if let original = originalGridPosition {
            place(item: item, at: original)
        }

        endDragging(item)
    }

    private func revertDrag(for item: InventoryItemNode) {
        if let original = originalGridPosition {
            place(item: item, at: original)
        }
        endDragging(item)
    }

    private func endDragging(_ item: InventoryItemNode) {
        item.setDraggingStyle(false)
        clearDropPreview()
        draggingItem = nil
        originalGridPosition = nil
        pendingGridPosition = nil
    }

    private func updateDropPreview(for item: InventoryItemNode, at position: GridPosition) {
        clearDropPreview()
        let isValid = canPlace(item: item, at: position)
        let color = isValid ? SKColor.green.withAlphaComponent(0.35) : SKColor.red.withAlphaComponent(0.35)

        for row in position.row..<(position.row + item.gridSize.height) {
            for column in position.column..<(position.column + item.gridSize.width) {
                let preview = SKShapeNode(rectOf: CGSize(width: cellSize - 4, height: cellSize - 4), cornerRadius: 3)
                preview.fillColor = color
                preview.strokeColor = .clear
                preview.position = CGPoint(x: startX + CGFloat(column) * cellSize, y: startY - CGFloat(row) * cellSize)
                preview.zPosition = 9
                contentNode.addChild(preview)
                dropPreviewNodes.append(preview)
            }
        }
    }

    private func clearDropPreview() {
        for node in dropPreviewNodes {
            node.removeFromParent()
        }
        dropPreviewNodes.removeAll()
    }
}
