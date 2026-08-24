//
//  ResultNode.swift
//  MahSafe
//
//  结算面板：成功 / 失败标题、三星展示、用时，以及重试 / 下一关 / 菜单。
//

import SpriteKit
import UIKit

final class ResultNode: SKNode {

    var onRetry: (() -> Void)?
    var onNext: (() -> Void)?
    var onMenu: (() -> Void)?

    private let dim: SKSpriteNode
    private let panel: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let contextLabel: SKLabelNode
    private let timeLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let hintsLabel: SKLabelNode
    private let achievementLabel: SKLabelNode
    private var stars: [StarNode] = []
    private let retryButton: ButtonNode
    private let nextButton: ButtonNode
    private let menuButton: ButtonNode

    override init() {
        dim = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        contextLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        timeLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        hintsLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        achievementLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        retryButton = ButtonNode(title: "Deal again", size: .zero, style: .secondary)
        nextButton = ButtonNode(title: "Next table", size: .zero, style: .primary)
        menuButton = ButtonNode(title: "Table book", size: .zero, style: .ghost)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        contextLabel.horizontalAlignmentMode = .center
        contextLabel.verticalAlignmentMode = .center
        timeLabel.horizontalAlignmentMode = .center
        timeLabel.verticalAlignmentMode = .center
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.verticalAlignmentMode = .center
        hintsLabel.horizontalAlignmentMode = .center
        hintsLabel.verticalAlignmentMode = .center
        achievementLabel.horizontalAlignmentMode = .center
        achievementLabel.verticalAlignmentMode = .center
        achievementLabel.numberOfLines = 0

        addChild(dim)
        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(contextLabel)
        panel.addChild(timeLabel)
        panel.addChild(bestLabel)
        panel.addChild(hintsLabel)
        panel.addChild(achievementLabel)
        panel.addChild(retryButton)
        panel.addChild(nextButton)
        panel.addChild(menuButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets, result: TableFlow.LevelResult, hasNext: Bool) {
        let w = size.width
        let h = size.height

        dim.texture = SKTexture(color: UIColor.black.withAlphaComponent(0.72))
        dim.size = size
        dim.position = CGPoint(x: w / 2, y: h / 2)
        dim.zPosition = 0

        let panelW = w * 0.84
        let panelH = h * 0.56
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 22)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: h * 0.51)
        panel.zPosition = 1

        titleLabel.text = result.won ? "The lock gives" : "The lock holds"
        titleLabel.fontSize = panelW * 0.10
        titleLabel.fontColor = result.won ? Theme.textGold : Theme.textLight
        titleLabel.position = CGPoint(x: 0, y: panelH * 0.32)
        titleLabel.zPosition = 2

        contextLabel.text = result.isDaily ? "Today's hand · \(DailyManager.displayDate())" : ""
        contextLabel.fontSize = panelW * 0.04
        contextLabel.fontColor = Theme.textDim
        contextLabel.position = CGPoint(x: 0, y: panelH * 0.20)
        contextLabel.zPosition = 2

        timeLabel.text = "Table time  " + Format.clock(result.time)
        timeLabel.fontSize = panelW * 0.05
        timeLabel.fontColor = Theme.textDim
        timeLabel.position = CGPoint(x: 0, y: -panelH * 0.02)
        timeLabel.zPosition = 2

        // 刷新纪录时在用时下方给一行金色提示。
        bestLabel.text = result.isNewBest ? "★ New mark" : ""
        bestLabel.fontSize = panelW * 0.045
        bestLabel.fontColor = Theme.textGold
        bestLabel.position = CGPoint(x: 0, y: -panelH * 0.11)
        bestLabel.zPosition = 2

        // 用过的提示会扣星，结算时如实说明。
        hintsLabel.text = result.won && result.hintsUsed > 0 ? "Peeks used: \(result.hintsUsed)" : ""
        hintsLabel.fontSize = panelW * 0.038
        hintsLabel.fontColor = Theme.textDim
        hintsLabel.position = CGPoint(x: 0, y: -panelH * 0.17)
        hintsLabel.zPosition = 2

        rebuildAchievementLine(for: result, panelW: panelW, panelH: panelH)

        rebuildStars(in: panel, panelW: panelW, panelH: panelH, count: result.stars, won: result.won)

        let canOpenNext = result.won && hasNext
        let buttonHeight = h * 0.056
        let buttonFontSize = panelW * 0.038
        let secondaryY = canOpenNext ? -panelH * 0.44 : -panelH * 0.39
        retryButton.setSize(CGSize(width: panelW * 0.34, height: buttonHeight), fontSize: buttonFontSize)
        retryButton.layout(at: CGPoint(x: -panelW * 0.20, y: secondaryY))
        retryButton.zPosition = 2
        menuButton.setSize(CGSize(width: panelW * 0.34, height: buttonHeight), fontSize: buttonFontSize)
        menuButton.layout(at: CGPoint(x: panelW * 0.20, y: secondaryY))
        menuButton.zPosition = 2

        nextButton.setSize(CGSize(width: panelW * 0.72, height: buttonHeight), fontSize: panelW * 0.042)
        nextButton.layout(at: CGPoint(x: 0, y: -panelH * 0.33))
        nextButton.zPosition = 2
        nextButton.setEnabled(canOpenNext)
        nextButton.isHidden = !canOpenNext
    }

    /// 展示本局新解锁的成就（最多列两项，其余以 +N 收尾）。
    private func rebuildAchievementLine(for result: TableFlow.LevelResult, panelW: CGFloat, panelH: CGFloat) {
        let unlocked = result.newAchievements
        guard !unlocked.isEmpty else {
            achievementLabel.text = ""
            return
        }
        var text = unlocked.prefix(2).map { "\($0.symbol) \($0.title)" }.joined(separator: "   ")
        if unlocked.count > 2 {
            text += "   +\(unlocked.count - 2)"
        }
        achievementLabel.text = "New marks  ·  " + text
        achievementLabel.fontSize = panelW * 0.034
        achievementLabel.fontColor = Theme.textGold
        achievementLabel.preferredMaxLayoutWidth = panelW * 0.9
        achievementLabel.position = CGPoint(x: 0, y: -panelH * 0.23)
        achievementLabel.zPosition = 2
    }

    private func rebuildStars(in panel: SKNode, panelW: CGFloat, panelH: CGFloat, count: Int, won: Bool) {
        for star in stars { star.removeFromParent() }
        stars.removeAll()

        let starSize = panelW * 0.14
        for i in 0..<3 {
            let star = StarNode(size: starSize, filled: i < count)
            star.position = CGPoint(x: CGFloat(i - 1) * starSize * 1.5, y: panelH * 0.10)
            star.zPosition = 2
            panel.addChild(star)
            stars.append(star)
        }
    }

    func playAnimation() {
        titleLabel.setScale(0.6)
        titleLabel.alpha = 0
        titleLabel.run(.group([
            .fadeIn(withDuration: Timing.overlayIn),
            .scale(to: 1.0, duration: Timing.overlayIn)
        ]))
        for (i, star) in stars.enumerated() where star.isFilled {
            star.pop(delay: Timing.overlayIn + TimeInterval(i) * Timing.starStagger)
        }
    }

    func target(at p: CGPoint) -> TapTarget? {
        let pointInPanel = panel.convert(p, from: self)
        if retryButton.isEnabled && retryButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onRetry?() },
                             onPress: { [weak self] in self?.retryButton.press() },
                             onRelease: { [weak self] in self?.retryButton.release() })
        }
        if nextButton.isEnabled && nextButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onNext?() },
                             onPress: { [weak self] in self?.nextButton.press() },
                             onRelease: { [weak self] in self?.nextButton.release() })
        }
        if menuButton.isEnabled && menuButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onMenu?() },
                             onPress: { [weak self] in self?.menuButton.press() },
                             onRelease: { [weak self] in self?.menuButton.release() })
        }
        return nil
    }
}
