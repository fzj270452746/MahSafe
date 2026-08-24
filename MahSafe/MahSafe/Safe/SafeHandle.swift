//
//  SafeHandle.swift
//  MahSafe
//
//  保险箱底部的机械把手。拉动时旋转 90°，配合震动与音效。
//

import SpriteKit
import UIKit

final class SafeHandle: SKNode {

    private let hub: SKSpriteNode
    private let lever: SKShapeNode
    private var isTurned = false

    override init() {
        hub = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        lever = SKShapeNode()
        super.init()
        hub.zPosition = 4
        lever.zPosition = 5
        addChild(hub)
        addChild(lever)
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in bodyRect: CGRect) {
        let hubSide = bodyRect.width * 0.14
        let hubRadius = hubSide * 0.42
        let hubSize = CGSize(width: hubSide, height: hubSide)

        hub.texture = TableSurfaces.brass(size: hubSize, radius: hubRadius)
        hub.size = hubSize
        hub.position = CGPoint(x: bodyRect.midX, y: bodyRect.minY + bodyRect.height * 0.10)

        let leverWidth = bodyRect.width * 0.30
        let leverHeight = bodyRect.height * 0.05
        let leverPath = CGPath(roundedRect: CGRect(x: -leverWidth / 2, y: -leverHeight / 2,
                                                   width: leverWidth, height: leverHeight),
                               cornerWidth: leverHeight / 2, cornerHeight: leverHeight / 2, transform: nil)
        lever.path = leverPath
        lever.fillColor = Theme.brassLight
        lever.strokeColor = Theme.brassDark
        lever.lineWidth = 1.5
        lever.position = hub.position
    }

    /// 拉动把手：旋转 90°。
    func pull() {
        guard !isTurned else { return }
        isTurned = true
        let hubSpin = SKAction.rotate(byAngle: .pi / 2, duration: Timing.handleTurn)
        hubSpin.timingMode = .easeInEaseOut
        hub.run(hubSpin)
        lever.run(hubSpin)
    }

    func reset() {
        isTurned = false
        hub.removeAllActions()
        lever.removeAllActions()
        hub.zRotation = 0
        lever.zRotation = 0
    }
}
