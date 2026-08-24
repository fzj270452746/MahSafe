//
//  BlitzNode.swift
//  MahSafe
//
//  快局入口：说明玩法、展示最好成绩，并提供开始按钮。
//

import SpriteKit
import UIKit

final class BlitzNode: SKNode {

    var onBack: (() -> Void)?
    var onPlay: (() -> Void)?

    private let backButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let panel: SKSpriteNode
    private let safeLabel: SKLabelNode
    private let bestLabel: SKLabelNode
    private let statusLabel: SKLabelNode
    private let cancelButton: ButtonNode
    private let playButton: ButtonNode

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        safeLabel = SKLabelNode(fontNamed: Theme.displayFont)
        bestLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        cancelButton = ButtonNode(title: "Back to tables", size: .zero, style: .ghost)
        playButton = ButtonNode(title: "Deal", size: .zero, style: .primary)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        safeLabel.horizontalAlignmentMode = .center
        safeLabel.verticalAlignmentMode = .center
        bestLabel.horizontalAlignmentMode = .center
        bestLabel.verticalAlignmentMode = .center
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.numberOfLines = 3
        statusLabel.lineBreakMode = .byWordWrapping

        addChild(backButton)
        addChild(titleLabel)
        addChild(panel)
        panel.addChild(safeLabel)
        panel.addChild(bestLabel)
        panel.addChild(statusLabel)
        panel.addChild(cancelButton)
        panel.addChild(playButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        let w = size.width
        let h = size.height

        titleLabel.text = "One-minute"
        titleLabel.fontSize = w * 0.068
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.07)
        backButton.layout(at: CGPoint(x: w * 0.07, y: h - safeArea.top - h * 0.07))

        let panelW = w * 0.84
        let panelH = h * 0.39
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 22)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: h * 0.50)

        safeLabel.text = "Keep the table moving"
        safeLabel.fontSize = panelW * 0.082
        safeLabel.fontColor = Theme.textGold
        safeLabel.position = CGPoint(x: 0, y: panelH * 0.28)
        safeLabel.zPosition = 2

        let best = BlitzManager.bestCount
        bestLabel.text = best > 0 ? "Best run  \(best)" : "No run on the ledger"
        bestLabel.fontSize = panelW * 0.055
        bestLabel.fontColor = Theme.textLight
        bestLabel.position = CGPoint(x: 0, y: panelH * 0.10)
        bestLabel.zPosition = 2

        statusLabel.text = "Start with 60 seconds.\nEvery table opened adds five more.\nSee how long your hands hold up."
        statusLabel.fontSize = panelW * 0.034
        statusLabel.fontColor = Theme.textDim
        statusLabel.preferredMaxLayoutWidth = panelW * 0.9
        statusLabel.position = CGPoint(x: 0, y: -panelH * 0.14)
        statusLabel.zPosition = 2

        let buttonSize = CGSize(width: panelW * 0.40, height: h * 0.06)
        let buttonY = -panelH * 0.34
        cancelButton.setSize(buttonSize, fontSize: panelW * 0.042)
        cancelButton.layout(at: CGPoint(x: -panelW * 0.22, y: buttonY))
        cancelButton.zPosition = 2
        playButton.setSize(buttonSize, fontSize: panelW * 0.042)
        playButton.layout(at: CGPoint(x: panelW * 0.22, y: buttonY))
        playButton.zPosition = 2
    }

    func target(at p: CGPoint) -> TapTarget? {
        if backButton.isEnabled && backButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.backButton.press() },
                             onRelease: { [weak self] in self?.backButton.release() })
        }
        let pointInPanel = panel.convert(p, from: self)
        if cancelButton.isEnabled && cancelButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.cancelButton.press() },
                             onRelease: { [weak self] in self?.cancelButton.release() })
        }
        if playButton.isEnabled && playButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onPlay?() },
                             onPress: { [weak self] in self?.playButton.press() },
                             onRelease: { [weak self] in self?.playButton.release() })
        }
        return nil
    }
}
