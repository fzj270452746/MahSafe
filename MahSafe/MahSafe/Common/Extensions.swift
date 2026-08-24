//
//  Extensions.swift
//  MahSafe
//
//  轻量扩展，只放跨模块真正复用的小工具。
//

import CoreGraphics
import SpriteKit
import UIKit

extension CGFloat {
    var clamped01: CGFloat {
        if self < 0 { return 0 }
        if self > 1 { return 1 }
        return self
    }

    func clamped(_ low: CGFloat, _ high: CGFloat) -> CGFloat {
        if self < low { return low }
        if self > high { return high }
        return self
    }

    /// 把本值从 [inLow, inHigh] 线性映射到 [outLow, outHigh]。
    func remap(from inLow: CGFloat, _ inHigh: CGFloat, to outLow: CGFloat, _ outHigh: CGFloat) -> CGFloat {
        guard inHigh != inLow else { return outLow }
        let t = (self - inLow) / (inHigh - inLow)
        return outLow + t.clamped01 * (outHigh - outLow)
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension CGSize {
    var midX: CGFloat { width / 2 }
    var midY: CGFloat { height / 2 }
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

extension SKAction {
    /// 依次执行，最后跑 completion（主线程安全的回调）。
    static func run(_ actions: [SKAction], completion: @escaping () -> Void) -> SKAction {
        let done = SKAction.run(completion)
        return SKAction.sequence(actions + [done])
    }

    /// 轻微弹性的缩放强调，用于按钮按下。
    static func pressPulse(scale: CGFloat = 1.06, duration: TimeInterval = 0.10) -> SKAction {
        let up = SKAction.scale(to: scale, duration: duration)
        let down = SKAction.scale(to: 1.0, duration: duration * 1.4)
        down.timingMode = .easeOut
        return SKAction.sequence([up, down])
    }
}

extension SKSpriteNode {
    /// 用纯色生成一个 1x1 纹理精灵，便于铺底色。
    convenience init(color: UIColor, size: CGSize) {
        self.init(texture: SKTexture(color: color), color: color, size: size)
    }
}

extension SKTexture {
    /// 纯色 1x1 纹理，适合铺底或做发光层。
    convenience init(color: UIColor) {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        self.init(image: image)
    }
}

extension Array {
    /// 用给定随机源洗牌（保持确定性）。
    mutating func shuffle<G: RandomNumberGenerator>(using generator: inout G) {
        guard count > 1 else { return }
        for i in stride(from: count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i, using: &generator)
            swapAt(i, j)
        }
    }

    func shuffled<G: RandomNumberGenerator>(using generator: inout G) -> [Element] {
        var copy = self
        copy.shuffle(using: &generator)
        return copy
    }
}

extension Array where Element: Hashable {
    /// 每个元素出现的次数，顺序稳定。
    func frequency() -> [Element: Int] {
        reduce(into: [:]) { dict, item in
            dict[item, default: 0] += 1
        }
    }
}
