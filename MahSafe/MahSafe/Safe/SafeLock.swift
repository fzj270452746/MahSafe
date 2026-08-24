//
//  SafeLock.swift
//  MahSafe
//
//  保险箱中央的机械锁盘。纯装饰元素，开门时旋转并「咔哒」归位。
//

import SpriteKit
import UIKit

final class SafeLock: SKNode {

    private let dial: SKSpriteNode
    private let needle: SKShapeNode
    private let tickLayer: SKShapeNode

    override init() {
        dial = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        needle = SKShapeNode()
        tickLayer = SKShapeNode()
        super.init()
        addChild(dial)
        dial.addChild(tickLayer)
        dial.addChild(needle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(center: CGPoint, diameter: CGFloat) {
        let side = diameter
        let radius = side * 0.5
        dial.texture = TableSurfaces.brass(size: CGSize(width: side, height: side), radius: radius)
        dial.size = CGSize(width: side, height: side)
        dial.position = center
        dial.zPosition = 6

        // 刻度。
        tickLayer.path = nil
        let tickPath = CGMutablePath()
        let outer = radius * 0.90
        let inner = radius * 0.78
        for i in 0..<12 {
            let angle = CGFloat(i) * .pi * 2 / 12
            let cosA = cos(angle), sinA = sin(angle)
            tickPath.move(to: CGPoint(x: cosA * inner, y: sinA * inner))
            tickPath.addLine(to: CGPoint(x: cosA * outer, y: sinA * outer))
        }
        tickLayer.path = tickPath
        tickLayer.strokeColor = Theme.brassDark
        tickLayer.lineWidth = 2

        // 指针。
        let needlePath = CGMutablePath()
        needlePath.move(to: CGPoint(x: 0, y: 0))
        needlePath.addLine(to: CGPoint(x: 0, y: radius * 0.72))
        needle.path = needlePath
        needle.strokeColor = Theme.symbolInk
        needle.lineWidth = 3
    }

    /// 锁盘旋转一圈并归位。
    func unlock() {
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: Timing.lockClick)
        spin.timingMode = .easeInEaseOut
        needle.run(spin)
    }

    func reset() {
        needle.removeAllActions()
        needle.zRotation = 0
    }
}
