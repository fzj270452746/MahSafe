//
//  SafeDoor.swift
//  MahSafe
//
//  保险箱门板。麻将网格就挂在门板上，解锁时门板淡出、
//  露出背后暖光。
//

import SpriteKit
import UIKit

final class SafeDoor: SKNode {

    private let panel: SKSpriteNode
    /// 麻将网格挂载点，由 GameScene 往里加牌。
    let board = SKNode()

    override init() {
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        super.init()
        addChild(panel)
        addChild(board)
        board.zPosition = 2
        panel.zPosition = 1
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in innerRect: CGRect) {
        panel.texture = TableSurfaces.recessed(size: innerRect.size, radius: innerRect.width * 0.04)
        panel.size = innerRect.size
        panel.position = innerRect.center
        board.position = innerRect.center
    }

    /// 门板淡出 + 轻微收缩，模拟向前开启。
    func open(completion: @escaping () -> Void) {
        let fade = SKAction.fadeOut(withDuration: Timing.doorOpen * 0.7)
        let shrink = SKAction.scale(to: 0.94, duration: Timing.doorOpen)
        let group = SKAction.group([fade, shrink])
        run(.run([group], completion: completion))
    }

    func reset() {
        removeAllActions()
        panel.alpha = 1
        panel.setScale(1)
    }
}
