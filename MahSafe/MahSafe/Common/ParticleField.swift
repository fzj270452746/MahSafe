//
//  ParticleField.swift
//  MahSafe
//
//  程序化粒子：菜单里的暖光尘埃、胜利时的金色碎屑。
//  不依赖贴图文件，用发光纹理 + 小色块模拟，统一走 SKAction 驱动。
//

import SpriteKit
import UIKit

enum ParticleField {

    /// 在指定矩形内撒一圈缓慢上浮的尘埃粒子，营造暖光氛围。
    static func ambientDust(in rect: CGRect, parent: SKNode, count: Int, z: CGFloat = -5) {
        guard rect.width > 0, rect.height > 0 else { return }
        for _ in 0..<count {
            let size = CGFloat.random(in: 2...6)
            let mote = SKSpriteNode(texture: MahjongRenderer.glowTexture(color: Theme.innerLight))
            mote.size = CGSize(width: size, height: size)
            mote.alpha = CGFloat.random(in: 0.05...0.22)
            mote.blendMode = .add
            mote.zPosition = z
            let origin = CGPoint(x: rect.minX + CGFloat.random(in: 0...rect.width),
                                 y: rect.minY + CGFloat.random(in: 0...rect.height))
            mote.position = origin
            parent.addChild(mote)

            let duration = TimeInterval.random(in: 6...14)
            let drift = SKAction.moveBy(x: CGFloat.random(in: -40...40),
                                        y: rect.height * 0.6,
                                        duration: duration)
            drift.timingMode = .easeInEaseOut
            let breathe = SKAction.sequence([
                .fadeAlpha(to: CGFloat.random(in: 0.10...0.26), duration: duration * 0.5),
                .fadeAlpha(to: 0.04, duration: duration * 0.5)
            ])
            let reset = SKAction.move(to: origin, duration: 0)
            mote.run(.repeatForever(.sequence([.group([drift, breathe]), reset])))
        }
    }

    /// 胜利时的金色碎屑爆发，朝四周散射后消失。
    static func confettiBurst(at point: CGPoint, parent: SKNode, count: Int = 42) {
        let colors: [UIColor] = [Theme.brassLight, Theme.textGold, Theme.brass, Theme.innerLight]
        for _ in 0..<count {
            let size = CGFloat.random(in: 3...8)
            let piece = SKSpriteNode(color: colors.randomElement() ?? Theme.brass,
                                     size: CGSize(width: size, height: size))
            piece.position = point
            piece.zPosition = 90
            parent.addChild(piece)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 90...280)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed
            let move = SKAction.moveBy(x: dx, y: dy, duration: TimeInterval.random(in: 0.6...1.3))
            move.timingMode = .easeOut
            let spin = SKAction.rotate(byAngle: CGFloat.random(in: -6...6), duration: 1)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            piece.run(.sequence([.group([move, spin, fade]), .removeFromParent()]))
        }
    }
}
