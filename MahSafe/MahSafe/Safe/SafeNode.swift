//
//  SafeNode.swift
//  MahSafe
//
//  保险箱视觉总装：外框 + 门板 + 锁盘 + 把手 + 门栓 + 内部暖光。
//  只负责「长什么样、怎么动」，不参与谜题判定。
//

import SpriteKit
import UIKit

enum SafeState {
    case locked
    case analyzing
    case unlocking
    case opened
    case failed
}

final class SafeNode: SKNode {

    private let body: SKSpriteNode
    private let innerLight: SKSpriteNode
    private let door = SafeDoor()
    private let lock = SafeLock()
    private let handle = SafeHandle()
    private let bolts = SafeBolts()
    private let outerBevel: SKShapeNode
    private let doorContour: SKShapeNode
    private let serialLabel: SKLabelNode
    private let verifyLabel: SKLabelNode
    private let indicatorLights: [SKShapeNode]
    private var cornerBolts: [SKShapeNode] = []
    private var doorRivets: [SKShapeNode] = []
    private var grooveLine: SKShapeNode?

    /// 麻将网格的可用区域，由 GameScene 据此排布牌。
    private(set) var boardRect: CGRect = .zero
    private(set) var state: SafeState = .locked
    private(set) var innerRect: CGRect = .zero

    /// 把手可点区域（场景坐标），用于「拉把手」触发确认。
    var handleHitRect: CGRect {
        let w = innerRect.width * 0.34
        let h = innerRect.height * 0.22
        return CGRect(x: innerRect.midX - w / 2,
                      y: innerRect.minY + innerRect.height * 0.01,
                      width: w, height: h)
    }

    override init() {
        body = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        innerLight = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        outerBevel = SKShapeNode()
        doorContour = SKShapeNode()
        serialLabel = SKLabelNode(fontNamed: Theme.headingFont)
        verifyLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        indicatorLights = (0..<3).map { _ in SKShapeNode(circleOfRadius: 2) }
        super.init()

        innerLight.zPosition = 0
        innerLight.blendMode = .add
        innerLight.alpha = 0
        addChild(innerLight)

        // 外框垫底：它是不透明金属、铺满整个 bodyRect，必须放在最下层，
        // 否则会把门板和门板上的麻将牌整个盖住（只剩把手锁盘浮在金属上）。
        body.zPosition = 1
        addChild(body)

        outerBevel.zPosition = 1.5
        addChild(outerBevel)

        door.zPosition = 2
        addChild(door)

        doorContour.zPosition = 2.5
        addChild(doorContour)

        bolts.zPosition = 3
        addChild(bolts)

        handle.zPosition = 5
        addChild(handle)

        lock.zPosition = 6
        addChild(lock)

        serialLabel.zPosition = 7
        serialLabel.horizontalAlignmentMode = .left
        serialLabel.verticalAlignmentMode = .center
        addChild(serialLabel)

        verifyLabel.zPosition = 7
        verifyLabel.horizontalAlignmentMode = .center
        verifyLabel.verticalAlignmentMode = .center
        addChild(verifyLabel)

        for light in indicatorLights {
            light.zPosition = 7
            addChild(light)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    var board: SKNode { door.board }

    // MARK: - 布局

    func layout(in bodyRect: CGRect) {
        let w = bodyRect.width
        let h = bodyRect.height

        body.texture = TableSurfaces.vaultMetal(size: bodyRect.size, radius: w * 0.04)
        body.size = bodyRect.size
        body.position = bodyRect.center

        let bevelRect = bodyRect.insetBy(dx: w * 0.018, dy: h * 0.018)
        outerBevel.path = CGPath(roundedRect: bevelRect,
                                 cornerWidth: w * 0.028,
                                 cornerHeight: w * 0.028,
                                 transform: nil)
        outerBevel.fillColor = .clear
        outerBevel.strokeColor = Theme.brassDark.withAlphaComponent(0.85)
        outerBevel.lineWidth = max(1, w * 0.006)

        let inner = bodyRect.insetBy(dx: w * 0.06, dy: h * 0.06)
        innerRect = inner
        door.layout(in: inner)

        let contourRect = inner.insetBy(dx: -w * 0.012, dy: -h * 0.012)
        doorContour.path = CGPath(roundedRect: contourRect,
                                  cornerWidth: w * 0.032,
                                  cornerHeight: w * 0.032,
                                  transform: nil)
        doorContour.fillColor = .clear
        doorContour.strokeColor = Theme.brassPatina.withAlphaComponent(0.72)
        doorContour.lineWidth = max(1, w * 0.008)

        let topBand = inner.height * 0.11
        let bottomBand = inner.height * 0.14
        boardRect = CGRect(x: inner.minX + w * 0.025,
                           y: inner.minY + bottomBand,
                           width: inner.width - w * 0.05,
                           height: inner.height - topBand - bottomBand)

        lock.layout(center: CGPoint(x: inner.midX, y: inner.maxY - topBand * 0.55),
                    diameter: inner.width * 0.16)
        handle.layout(in: inner)
        bolts.layout(in: inner)

        serialLabel.text = "BRASS LOCK  /  TABLE 08"
        serialLabel.fontSize = w * 0.020
        serialLabel.fontColor = Theme.brassLight
        serialLabel.position = CGPoint(x: inner.minX + inner.width * 0.045,
                                       y: inner.maxY - topBand * 0.55)

        verifyLabel.text = "PULL TO TRY"
        verifyLabel.fontSize = w * 0.017
        verifyLabel.fontColor = Theme.textDim
        verifyLabel.position = CGPoint(x: inner.midX,
                                       y: inner.minY + bottomBand * 0.89)

        let lampRadius = w * 0.010
        let lampY = inner.maxY - topBand * 0.55
        for (index, light) in indicatorLights.enumerated() {
            light.path = CGPath(ellipseIn: CGRect(x: -lampRadius, y: -lampRadius,
                                                  width: lampRadius * 2, height: lampRadius * 2),
                                transform: nil)
            light.position = CGPoint(x: inner.maxX - inner.width * 0.045 - CGFloat(2 - index) * lampRadius * 3.0,
                                     y: lampY)
            light.fillColor = index == 0 ? Theme.success : Theme.metalDark
            light.strokeColor = Theme.brassDark
            light.lineWidth = 1
            light.glowWidth = index == 0 ? lampRadius : 0
        }

        innerLight.texture = MahjongRenderer.glowTexture(color: Theme.innerLight)
        innerLight.size = CGSize(width: inner.width * 1.5, height: inner.height * 1.5)
        innerLight.position = inner.center

        placeCornerBolts(in: bodyRect)
        placeDoorDetail(in: inner)
    }

    private func placeCornerBolts(in bodyRect: CGRect) {
        for bolt in cornerBolts { bolt.removeFromParent() }
        cornerBolts.removeAll()

        let radius = bodyRect.width * 0.025
        let inset = bodyRect.width * 0.045
        let corners = [
            CGPoint(x: bodyRect.minX + inset, y: bodyRect.maxY - inset),
            CGPoint(x: bodyRect.maxX - inset, y: bodyRect.maxY - inset),
            CGPoint(x: bodyRect.minX + inset, y: bodyRect.minY + inset),
            CGPoint(x: bodyRect.maxX - inset, y: bodyRect.minY + inset)
        ]
        for corner in corners {
            let bolt = SKShapeNode(circleOfRadius: radius)
            bolt.fillColor = Theme.brass
            bolt.strokeColor = Theme.brassDark
            bolt.lineWidth = 1
            bolt.position = corner
            bolt.zPosition = 7
            addChild(bolt)
            cornerBolts.append(bolt)
        }
    }

    // MARK: - 装饰细节

    /// 门板上的铆钉行与顶部刻槽，落在没有麻将牌的上下饰带里，增强机械感。
    private func placeDoorDetail(in inner: CGRect) {
        for rivet in doorRivets { rivet.removeFromParent() }
        doorRivets.removeAll()

        let radius = inner.width * 0.011
        let topY = inner.maxY - inner.height * 0.055
        let bottomY = inner.minY + inner.height * 0.055
        let count = 6
        for i in 0..<count {
            let t = CGFloat(i) / CGFloat(count - 1)
            let x = inner.minX + inner.width * 0.08 + t * inner.width * 0.84
            for y in [topY, bottomY] {
                let rivet = SKShapeNode(circleOfRadius: radius)
                rivet.fillColor = Theme.brass
                rivet.strokeColor = Theme.brassDark
                rivet.lineWidth = 0.5
                rivet.position = CGPoint(x: x, y: y)
                rivet.zPosition = 2
                addChild(rivet)
                doorRivets.append(rivet)
            }
        }

        // 顶部饰带内的一条刻线，像把手旁的凹槽。
        grooveLine?.removeFromParent()
        let line = SKShapeNode()
        let path = CGMutablePath()
        let ly = inner.maxY - inner.height * 0.105
        path.move(to: CGPoint(x: inner.minX + inner.width * 0.12, y: ly))
        path.addLine(to: CGPoint(x: inner.maxX - inner.width * 0.12, y: ly))
        line.path = path
        line.strokeColor = Theme.brassDark
        line.lineWidth = 1
        line.zPosition = 2
        addChild(line)
        grooveLine = line
    }

    // MARK: - 反馈

    func shake() {
        guard state != .unlocking else { return }
        state = .failed
        let distance = boardRect.width * 0.012
        let jitter = SKAction.sequence([
            .moveBy(x: distance, y: 0, duration: 0.05),
            .moveBy(x: -distance * 2, y: 0, duration: 0.06),
            .moveBy(x: distance * 2, y: 0, duration: 0.06),
            .moveBy(x: -distance, y: 0, duration: 0.05)
        ])
        run(jitter) { [weak self] in self?.state = .locked }
        setIndicators(activeCount: 3, color: Theme.danger)
        flashRed()
        run(.sequence([.wait(forDuration: Timing.redFlash), .run { [weak self] in
            self?.setIndicators(activeCount: 1, color: Theme.success)
        }]))
    }

    private func flashRed() {
        let overlay = SKSpriteNode(color: Theme.danger, size: body.size)
        overlay.alpha = 0.0
        overlay.position = body.position
        overlay.zPosition = 8
        addChild(overlay)
        overlay.run(.sequence([
            .fadeAlpha(to: 0.32, duration: 0.05),
            .fadeAlpha(to: 0.0, duration: Timing.redFlash)
        ])) { overlay.removeFromParent() }
    }

    /// 判定前的「核对中」节拍：锁盘转一圈，制造悬念后再揭晓对错。
    func analyze(completion: @escaping () -> Void) {
        guard state == .locked else {
            completion()
            return
        }
        state = .analyzing
        setIndicators(activeCount: 2, color: Theme.warning)
        lock.run(.rotate(byAngle: .pi * 2, duration: 0.42))
        run(.wait(forDuration: 0.45)) { [weak self] in
            self?.state = .locked
            self?.setIndicators(activeCount: 1, color: Theme.success)
            completion()
        }
    }

    /// 开门序列：把手 → 锁 → 门栓 → 门 → 内光。
    func unlock(completion: @escaping () -> Void) {
        guard state != .unlocking else { return }
        state = .unlocking
        setIndicators(activeCount: 3, color: Theme.success)

        handle.pull()
        lock.run(.sequence([
            .wait(forDuration: Timing.handleTurn * 0.6),
            .run { [weak self] in self?.lock.unlock() }
        ]))

        let boltDelay = Timing.handleTurn + Timing.lockClick * 0.4
        run(.sequence([
            .wait(forDuration: boltDelay),
            .run { [weak self] in self?.bolts.retract() }
        ]))

        let doorDelay = boltDelay + Timing.boltRetract * 0.7
        run(.sequence([
            .wait(forDuration: doorDelay),
            .run { [weak self] in
                self?.door.open {
                    self?.state = .opened
                    completion()
                }
            }
        ]))

        let lightDelay = doorDelay + Timing.doorOpen * 0.3
        run(.sequence([
            .wait(forDuration: lightDelay),
            .run { [weak self] in self?.bloomLight() }
        ]))
    }

    private func bloomLight() {
        innerLight.run(.group([
            .fadeAlpha(to: 0.95, duration: Timing.innerLight),
            .scale(to: 1.0, duration: Timing.innerLight)
        ]))
    }

    private func setIndicators(activeCount: Int, color: UIColor) {
        for (index, light) in indicatorLights.enumerated() {
            let active = index < activeCount
            light.fillColor = active ? color : Theme.metalDark
            light.glowWidth = active ? body.size.width * 0.01 : 0
        }
    }

    func reset() {
        removeAllActions()
        state = .locked
        door.reset()
        lock.reset()
        handle.reset()
        innerLight.removeAllActions()
        innerLight.alpha = 0
        innerLight.setScale(0.6)
        bolts.layout(in: innerRect)
        setIndicators(activeCount: 1, color: Theme.success)
    }
}
