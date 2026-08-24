//
//  DailyNode.swift
//  MahSafe
//
//  每日密码入口：显示今天日期、独立玩法、连续打卡与今日状态，
//  并提供一个开始按钮。
//

import SpriteKit
import UIKit

final class DailyNode: SKNode {

    var onBack: (() -> Void)?
    var onPlay: (() -> Void)?

    private let backButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let panel: SKSpriteNode
    private let dateLabel: SKLabelNode
    private let safeLabel: SKLabelNode
    private let streakLabel: SKLabelNode
    private let statusLabel: SKLabelNode
    private let cancelButton: ButtonNode
    private let playButton: ButtonNode

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        dateLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        safeLabel = SKLabelNode(fontNamed: Theme.displayFont)
        streakLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        statusLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        cancelButton = ButtonNode(title: "Back to tables", size: .zero, style: .ghost)
        playButton = ButtonNode(title: "Play today's hand", size: .zero, style: .primary)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        dateLabel.horizontalAlignmentMode = .center
        dateLabel.verticalAlignmentMode = .center
        safeLabel.horizontalAlignmentMode = .center
        safeLabel.verticalAlignmentMode = .center
        streakLabel.horizontalAlignmentMode = .center
        streakLabel.verticalAlignmentMode = .center
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.numberOfLines = 3
        statusLabel.lineBreakMode = .byWordWrapping
        dateLabel.zPosition = 2
        safeLabel.zPosition = 2
        streakLabel.zPosition = 2
        statusLabel.zPosition = 2

        addChild(backButton)
        addChild(titleLabel)
        addChild(panel)
        panel.addChild(dateLabel)
        panel.addChild(safeLabel)
        panel.addChild(streakLabel)
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

        titleLabel.text = "Today's hand"
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

        dateLabel.text = DailyManager.displayDate()
        dateLabel.isHidden = false
        dateLabel.alpha = 1
        dateLabel.fontSize = panelW * 0.05
        dateLabel.fontColor = Theme.textDim
        dateLabel.position = CGPoint(x: 0, y: panelH * 0.34)
        dateLabel.zPosition = 2

        safeLabel.text = "Four-band count"
        safeLabel.isHidden = false
        safeLabel.alpha = 1
        safeLabel.fontSize = panelW * 0.082
        safeLabel.fontColor = Theme.textGold
        safeLabel.position = CGPoint(x: 0, y: panelH * 0.16)
        safeLabel.zPosition = 2

        let streak = DailyManager.currentStreak
        let best = DailyManager.bestStreak
        streakLabel.text = streak > 0 ? "🔥 \(streak) days at the table" : "No run started"
        streakLabel.isHidden = false
        streakLabel.alpha = 1
        streakLabel.fontSize = panelW * 0.045
        streakLabel.fontColor = Theme.textLight
        streakLabel.position = CGPoint(x: 0, y: 0)
        streakLabel.zPosition = 2

        let statusText: String
        if let time = DailyManager.bestTodayTime {
            statusText = "Finished today in \(Format.clock(time))"
        } else {
            statusText = "Still waiting to be dealt"
        }
        statusLabel.text = "Each row steps up or down by 1.\nTap the one number that cheats · any row order.\nBest run: \(best)   ·   " + statusText
        statusLabel.isHidden = false
        statusLabel.alpha = 1
        statusLabel.fontSize = min(max(panelW * 0.038, 13), 16)
        statusLabel.fontColor = Theme.textLight
        statusLabel.preferredMaxLayoutWidth = panelW * 0.86
        statusLabel.position = CGPoint(x: 0, y: -panelH * 0.15)
        statusLabel.zPosition = 2

        let buttonSize = CGSize(width: panelW * 0.40, height: h * 0.06)
        let buttonY = -panelH * 0.34
        cancelButton.setSize(buttonSize, fontSize: panelW * 0.042)
        cancelButton.layout(at: CGPoint(x: -panelW * 0.22, y: buttonY))
        cancelButton.zPosition = 2
        playButton.setSize(buttonSize, fontSize: panelW * 0.038)
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
