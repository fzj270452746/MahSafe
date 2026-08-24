//
//  SafeBolts.swift
//  MahSafe
//
//  保险箱侧边门栓。开门时依次向内收起。
//

import SpriteKit
import UIKit

final class SafeBolts: SKNode {

    private var rods: [SKShapeNode] = []
    private var retracted = false

    /// 依据保险箱内板区域布局门栓。
    func layout(in bodyRect: CGRect) {
        removeAllChildren()
        rods.removeAll()

        let rodWidth = bodyRect.width * 0.035
        let rodHeight = bodyRect.height * 0.16
        let gapY = bodyRect.height * 0.30
        let midY = bodyRect.midY

        for side in [-1, 1] {
            let x = side == -1 ? bodyRect.minX + bodyRect.width * 0.015
                               : bodyRect.maxX - bodyRect.width * 0.015 - rodWidth
            for dy in [-gapY, gapY] {
                let rod = SKShapeNode(rect: CGRect(x: x, y: midY + dy - rodHeight / 2,
                                                   width: rodWidth, height: rodHeight),
                                      cornerRadius: rodWidth * 0.5)
                rod.fillColor = Theme.brass
                rod.strokeColor = Theme.brassDark
                rod.lineWidth = 1
                rod.zPosition = 3
                addChild(rod)
                rods.append(rod)
            }
        }
    }

    func retract() {
        guard !retracted else { return }
        retracted = true
        for (i, rod) in rods.enumerated() {
            let direction: CGFloat = rod.position.x < 0 ? 1 : -1
            let distance = rod.frame.width * 1.6
            let delay = TimeInterval(i) * 0.05
            rod.run(.sequence([
                .wait(forDuration: delay),
                .moveBy(x: direction * distance, y: 0, duration: Timing.boltRetract)
            ]))
        }
    }

    func reset() {
        retracted = false
        for rod in rods {
            rod.removeAllActions()
        }
        // 门栓位置在 layout 时确定，重置仅需回到布局态。
        // 这里依赖外部重新 layout。
    }
}
