//
//  StarNode.swift
//  MahSafe
//
//  星级：五角星，金 / 灰两种填充，带弹入动画。
//

import SpriteKit
import UIKit

final class StarNode: SKNode {

    private let shape: SKShapeNode
    private let size: CGFloat
    private(set) var isFilled: Bool

    init(size: CGFloat, filled: Bool) {
        self.size = size
        self.isFilled = filled
        self.shape = SKShapeNode(path: StarNode.starPath(radius: size / 2))
        super.init()
        shape.lineWidth = size * 0.07
        shape.lineJoin = .round
        applyFill()
        addChild(shape)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func setFilled(_ filled: Bool, animated: Bool = false) {
        isFilled = filled
        applyFill()
        if animated {
            pop()
        }
    }

    /// 弹入：从 0 放大到 1 再轻微回弹。
    func pop(delay: TimeInterval = 0) {
        setScale(0.01)
        let grow = SKAction.scale(to: 1.25, duration: Timing.starPop * 0.6)
        grow.timingMode = .easeOut
        let settle = SKAction.scale(to: 1.0, duration: Timing.starPop * 0.4)
        settle.timingMode = .easeInEaseOut
        run(.sequence([.wait(forDuration: delay), grow, settle]))
    }

    private func applyFill() {
        if isFilled {
            shape.fillColor = Theme.textGold
            shape.strokeColor = Theme.brassLight
        } else {
            shape.fillColor = Theme.metalDark
            shape.strokeColor = Theme.metalLight
        }
    }

    /// 生成五角星轮廓，中心在原点。
    static func starPath(radius: CGFloat) -> CGPath {
        let inner = radius * 0.5
        let path = CGMutablePath()
        let vertexCount = 10
        for i in 0..<vertexCount {
            let angle = CGFloat(i) * .pi / 5 - .pi / 2
            let r = i % 2 == 0 ? radius : inner
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}
