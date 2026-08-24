//
//  BlitzResultNode.swift
//  MahSafe
//
//  时间挑战结算：显示本次完成数、最好成绩，并提供再来一局 / 返回入口。
//

import SpriteKit
import UIKit

final class BlitzResultNode: SKNode {

    var onRetry: (() -> Void)?
    var onMenu: (() -> Void)?

    private let dim: SKSpriteNode
    private let panel: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let clearedLabel: SKLabelNode
    private let clearedCaption: SKLabelNode
    private let bestLabel: SKLabelNode
    private let retryButton: ButtonNode
    private let menuButton: ButtonNode

    override init() {
        dim = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        clearedLabel = SKLabelNode(fontNamed: Theme.displayFont)
        clearedCaption = SKLabelNode(fontNamed: "AvenirNext-Medium")
        bestLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        retryButton = ButtonNode(title: "PLAY AGAIN", size: .zero, style: .primary)
        menuButton = ButtonNode(title: "MENU", size: .zero, style: .ghost)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        clearedLabel.horizontalAlignmentMode = .center
        clearedLabel.verticalAlignmentMode = .center
        clearedCaption.horizontalAlignmentMode = .center
        clearedCaption.verticalAlignmentMode = .center
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.verticalAlignmentMode = .center

        addChild(dim)
        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(clearedLabel)
        panel.addChild(clearedCaption)
        panel.addChild(bestLabel)
        panel.addChild(retryButton)
        panel.addChild(menuButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets, outcome: TableFlow.BlitzOutcome) {
        let w = size.width
        let h = size.height

        dim.texture = SKTexture(color: UIColor.black.withAlphaComponent(0.72))
        dim.size = size
        dim.position = CGPoint(x: w / 2, y: h / 2)
        dim.zPosition = 0

        let panelW = w * 0.84
        let panelH = h * 0.52
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 22)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: h * 0.51)
        panel.zPosition = 1

        titleLabel.text = "The tea is cold"
        titleLabel.fontSize = panelW * 0.10
        titleLabel.fontColor = Theme.textGold
        titleLabel.position = CGPoint(x: 0, y: panelH * 0.32)
        titleLabel.zPosition = 2

        clearedLabel.text = "\(outcome.cleared)"
        clearedLabel.fontSize = panelW * 0.22
        clearedLabel.fontColor = Theme.textLight
        clearedLabel.position = CGPoint(x: 0, y: panelH * 0.10)
        clearedLabel.zPosition = 2

        clearedCaption.text = "TABLES OPENED"
        clearedCaption.fontSize = panelW * 0.042
        clearedCaption.fontColor = Theme.textDim
        clearedCaption.position = CGPoint(x: 0, y: panelH * 0.005)
        clearedCaption.zPosition = 2

        bestLabel.text = outcome.isNewBest ? "★ New mark" : "Best run  \(BlitzManager.bestCount)"
        bestLabel.fontSize = panelW * 0.048
        bestLabel.fontColor = outcome.isNewBest ? Theme.textGold : Theme.brassLight
        bestLabel.position = CGPoint(x: 0, y: -panelH * 0.13)
        bestLabel.zPosition = 2

        let buttonSize = CGSize(width: panelW * 0.34, height: h * 0.056)
        let buttonFontSize = panelW * 0.038
        retryButton.setSize(buttonSize, fontSize: buttonFontSize)
        retryButton.layout(at: CGPoint(x: -panelW * 0.20, y: -panelH * 0.30))
        retryButton.zPosition = 2
        menuButton.setSize(buttonSize, fontSize: buttonFontSize)
        menuButton.layout(at: CGPoint(x: panelW * 0.20, y: -panelH * 0.30))
        menuButton.zPosition = 2
    }

    func playAnimation() {
        titleLabel.setScale(0.6)
        titleLabel.alpha = 0
        titleLabel.run(.group([
            .fadeIn(withDuration: Timing.overlayIn),
            .scale(to: 1.0, duration: Timing.overlayIn)
        ]))
        clearedLabel.setScale(0.6)
        clearedLabel.alpha = 0
        clearedLabel.run(.group([
            .fadeIn(withDuration: Timing.overlayIn),
            .scale(to: 1.0, duration: Timing.overlayIn)
        ]))
    }

    func target(at p: CGPoint) -> TapTarget? {
        let pointInPanel = panel.convert(p, from: self)
        if retryButton.isEnabled && retryButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onRetry?() },
                             onPress: { [weak self] in self?.retryButton.press() },
                             onRelease: { [weak self] in self?.retryButton.release() })
        }
        if menuButton.isEnabled && menuButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onMenu?() },
                             onPress: { [weak self] in self?.menuButton.press() },
                             onRelease: { [weak self] in self?.menuButton.release() })
        }
        return nil
    }
}
