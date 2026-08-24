//
//  MahjongTile.swift
//  MahSafe
//
//  棋盘上的单张麻将牌节点。只负责「呈现」某个 TileState，
//  不含谜题逻辑；逻辑状态由 PuzzleState 持有，改动后调用 apply 刷新。
//

import SpriteKit
import UIKit

final class MahjongTile: SKSpriteNode {

    private(set) var state: TileState

    private let selectionRing: SKShapeNode
    private let hintGlow: SKSpriteNode
    private let arrowBadge: SKShapeNode
    private let lockedBadge: SKSpriteNode

    init(state: TileState) {
        self.state = state
        self.selectionRing = SKShapeNode()
        self.hintGlow = SKSpriteNode()
        self.arrowBadge = SKShapeNode()
        self.lockedBadge = SKSpriteNode(color: .clear, size: .zero)
        super.init(texture: nil, color: .clear, size: CGSize(width: 1, height: 1))

        selectionRing.isHidden = true
        selectionRing.zPosition = 5
        addChild(selectionRing)

        hintGlow.isHidden = true
        hintGlow.zPosition = -2
        hintGlow.blendMode = .add
        addChild(hintGlow)

        arrowBadge.isHidden = true
        arrowBadge.zPosition = 6
        addChild(arrowBadge)

        lockedBadge.zPosition = 7
        lockedBadge.isHidden = true
        addChild(lockedBadge)

        // 初始纹理必须在这里显式设置：首次 apply 时 old == new，
        // 会被「状态没变就跳过换纹理」的分支跳过，导致牌永远空白。
        updateTexture(for: state)
        apply(state, animate: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("MahjongTile 仅支持代码构建")
    }

    // MARK: - 状态呈现

    /// 把节点的视觉同步到目标状态。animate 为 true 时对旋转/翻面/换牌做过渡动画。
    func apply(_ newState: TileState, animate: Bool) {
        let old = state

        if newState.isEmpty != old.isEmpty || newState.type != old.type || newState.isFlipped != old.isFlipped {
            updateTexture(for: newState)
            if animate && newState.type != old.type {
                run(.pressPulse(scale: 1.12, duration: 0.10))
            }
        }

        if newState.rotation != old.rotation {
            rotate(to: newState.rotation, animated: animate)
        } else if !animate {
            zRotation = radians(steps: newState.rotation)
        }

        if newState.isFlipped != old.isFlipped {
            if animate {
                flipVisual()
            }
        }

        state = newState
        arrowBadge.isHidden = !newState.showsArrow
        lockedBadge.isHidden = !newState.isLocked
        if newState.showsArrow {
            tintArrow(color: Theme.brassLight)
        }
    }

    private func updateTexture(for s: TileState) {
        if s.isEmpty {
            texture = MahjongRenderer.emptySlotTexture()
        } else if s.isFlipped {
            texture = s.backMark.map(MahjongRenderer.backTexture) ?? MahjongRenderer.plainBackTexture()
        } else {
            texture = MahjongRenderer.texture(for: s.type)
        }
    }

    private func rotate(to steps: Int, animated: Bool) {
        let target = radians(steps: steps)
        let delta = CGFloat(steps - state.rotation)
        let shortest = delta >= 2 ? delta - 4 : (delta <= -2 ? delta + 4 : delta)
        if animated {
            run(.rotate(byAngle: shortest * .pi / 2, duration: Timing.tileRotate))
        } else {
            zRotation = target
        }
    }

    private func flipVisual() {
        let half = Timing.tileFlip / 2
        let shrink = SKAction.scaleX(to: 0.02, duration: half)
        shrink.timingMode = .easeIn
        let swap = SKAction.run { [weak self] in
            guard let self else { return }
            self.updateTexture(for: self.state)
        }
        let grow = SKAction.scaleX(to: 1.0, duration: half)
        grow.timingMode = .easeOut
        run(.sequence([shrink, swap, grow]))
    }

    // MARK: - 子视觉布局

    /// 尺寸确定后调用，重建选择环 / 发光 / 箭头等子节点几何。
    func layoutSubvisuals() {
        let side = size.width
        let ringRect = CGRect(x: -side * 0.55, y: -side * 0.55,
                              width: side * 1.1, height: side * 1.1)
        let ringPath = CGPath(roundedRect: ringRect,
                              cornerWidth: side * 0.16, cornerHeight: side * 0.16,
                              transform: nil)
        selectionRing.path = ringPath
        selectionRing.strokeColor = Theme.selectionGlow
        selectionRing.lineWidth = side * 0.07
        selectionRing.glowWidth = side * 0.10

        hintGlow.texture = MahjongRenderer.glowTexture(color: Theme.hintGlow)
        hintGlow.size = CGSize(width: side * 1.9, height: side * 1.9)

        buildArrowBadge(side: side)
        buildLockedBadge(side: side)
    }

    private func buildArrowBadge(side: CGFloat) {
        let s = side * 0.26
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: s * 0.8))
        path.addLine(to: CGPoint(x: -s * 0.6, y: -s * 0.4))
        path.addLine(to: CGPoint(x: s * 0.6, y: -s * 0.4))
        path.closeSubpath()
        arrowBadge.path = path
        arrowBadge.position = CGPoint(x: 0, y: side * 0.38)
        arrowBadge.lineWidth = side * 0.02
    }

    private func buildLockedBadge(side: CGFloat) {
        lockedBadge.texture = nil
        lockedBadge.size = CGSize(width: side * 0.3, height: side * 0.3)
        lockedBadge.position = CGPoint(x: side * 0.28, y: -side * 0.28)
        let lock = SKLabelNode(text: "🔒")
        lock.fontSize = side * 0.22
        lock.zPosition = 1
        lockedBadge.addChild(lock)
    }

    private func tintArrow(color: UIColor) {
        arrowBadge.fillColor = color
        arrowBadge.strokeColor = color.blended(with: .black, amount: 0.35)
    }

    // MARK: - 交互视觉

    func setSelected(_ selected: Bool) {
        selectionRing.isHidden = !selected
        if selected {
            selectionRing.removeAllActions()
            selectionRing.run(.repeatForever(.sequence([
                .scale(to: 1.06, duration: 0.35),
                .scale(to: 1.0, duration: 0.35)
            ])))
        }
    }

    func showHintGlow(_ on: Bool) {
        hintGlow.isHidden = !on
        if on {
            hintGlow.removeAllActions()
            hintGlow.alpha = 0
            hintGlow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.9, duration: 0.4),
                .fadeAlpha(to: 0.25, duration: 0.4)
            ])))
        }
    }

    func showSolved() {
        selectionRing.removeAllActions()
        selectionRing.strokeColor = Theme.success
        selectionRing.glowWidth = size.width * 0.06
        selectionRing.setScale(1)
        selectionRing.isHidden = false
    }

    func pulse() {
        run(.pressPulse(scale: 1.10, duration: 0.08))
    }

    func shake() {
        let distance = size.width * 0.06
        let shake = SKAction.sequence([
            .moveBy(x: distance, y: 0, duration: 0.05),
            .moveBy(x: -distance * 2, y: 0, duration: 0.05),
            .moveBy(x: distance * 2, y: 0, duration: 0.05),
            .moveBy(x: -distance, y: 0, duration: 0.05)
        ])
        run(shake)
    }

    func flashRed() {
        let tint = SKAction.colorize(with: Theme.danger, colorBlendFactor: 0.6, duration: 0.05)
        let back = SKAction.colorize(withColorBlendFactor: 0, duration: 0.25)
        run(.sequence([tint, back]))
    }
}
