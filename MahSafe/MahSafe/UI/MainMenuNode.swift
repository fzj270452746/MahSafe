//
//  MainMenuNode.swift
//  MahSafe
//
//  主菜单：夜场牌桌的入口与核心导航。
//

import SpriteKit
import UIKit

final class MainMenuNode: SKNode {

    var onPlay: (() -> Void)?
    var onDaily: (() -> Void)?
    var onBlitz: (() -> Void)?
    var onRules: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSoundToggle: (() -> Void)?
    var onHapticToggle: (() -> Void)?
    var onReset: (() -> Void)?

    private let cabinetPanel: SKSpriteNode
    private let cabinetBorder: SKShapeNode
    private let emblemGlow: SKSpriteNode
    private let emblemFrame: SKShapeNode
    private let emblemCross: SKShapeNode
    private let emblemTiles: [MahjongTile]
    private let eyebrowLabel: SKLabelNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private let progressLabel: SKLabelNode
    private let codeLabel: SKLabelNode
    private let divider: SKShapeNode
    private let playButton: ButtonNode
    private let dailyButton: ButtonNode
    private let blitzButton: ButtonNode
    private let rulesButton: ButtonNode
    private let settingsButton: ButtonNode
    private let soundButton: ButtonNode
    private let hapticButton: ButtonNode
    private let resetButton: ButtonNode

    override init() {
        cabinetPanel = SKSpriteNode(color: .clear, size: .zero)
        cabinetBorder = SKShapeNode()
        emblemGlow = SKSpriteNode(color: .clear, size: .zero)
        emblemFrame = SKShapeNode()
        emblemCross = SKShapeNode()
        emblemTiles = [MahjongType.character(8), .dragon(.red), .wind(.east)].map {
            MahjongTile(state: .face($0))
        }
        eyebrowLabel = SKLabelNode(fontNamed: Theme.headingFont)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        subtitleLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        progressLabel = SKLabelNode(fontNamed: Theme.headingFont)
        codeLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        divider = SKShapeNode()
        playButton = ButtonNode(title: "Open a table", size: .zero, style: .primary)
        dailyButton = ButtonNode(title: "Today's hand", size: .zero, style: .secondary)
        blitzButton = ButtonNode(title: "One-minute", size: .zero, style: .secondary)
        rulesButton = ButtonNode(title: "House rules", size: .zero, style: .secondary)
        settingsButton = ButtonNode(title: "Table drawer", size: .zero, style: .secondary)
        soundButton = ButtonNode(title: "Sound: On", size: .zero, style: .ghost)
        hapticButton = ButtonNode(title: "Haptics: On", size: .zero, style: .ghost)
        resetButton = ButtonNode(title: "Reset Progress", size: .zero, style: .ghost)
        super.init()

        eyebrowLabel.horizontalAlignmentMode = .center
        eyebrowLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        progressLabel.horizontalAlignmentMode = .center
        progressLabel.verticalAlignmentMode = .center
        codeLabel.horizontalAlignmentMode = .center
        codeLabel.verticalAlignmentMode = .center

        addChild(emblemGlow)
        addChild(emblemFrame)
        addChild(emblemCross)
        for tile in emblemTiles { addChild(tile) }
        addChild(eyebrowLabel)
        addChild(titleLabel)
        addChild(subtitleLabel)
        addChild(cabinetPanel)
        addChild(cabinetBorder)
        addChild(progressLabel)
        addChild(divider)
        addChild(playButton)
        addChild(dailyButton)
        addChild(blitzButton)
        addChild(rulesButton)
        addChild(settingsButton)
        addChild(soundButton)
        addChild(hapticButton)
        addChild(resetButton)
        addChild(codeLabel)

        soundButton.isHidden = true
        hapticButton.isHidden = true
        resetButton.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        let w = size.width
        let h = size.height

        let emblemCenter = CGPoint(x: w / 2, y: h * 0.80)
        let emblemRadius = w * 0.205
        emblemGlow.texture = MahjongRenderer.glowTexture(color: Theme.brassLight)
        emblemGlow.size = CGSize(width: emblemRadius * 3.0, height: emblemRadius * 3.0)
        emblemGlow.position = emblemCenter
        emblemGlow.alpha = 0.13
        emblemGlow.blendMode = .add

        let emblemPath = CGPath(ellipseIn: CGRect(x: -emblemRadius, y: -emblemRadius,
                                                  width: emblemRadius * 2, height: emblemRadius * 2),
                                transform: nil)
        emblemFrame.path = emblemPath
        emblemFrame.position = emblemCenter
        emblemFrame.fillColor = Theme.panel.withAlphaComponent(0.82)
        emblemFrame.strokeColor = Theme.brass
        emblemFrame.lineWidth = 2
        emblemFrame.glowWidth = 1

        let crossPath = CGMutablePath()
        crossPath.move(to: CGPoint(x: -emblemRadius * 1.15, y: 0))
        crossPath.addLine(to: CGPoint(x: emblemRadius * 1.15, y: 0))
        crossPath.move(to: CGPoint(x: 0, y: -emblemRadius * 1.15))
        crossPath.addLine(to: CGPoint(x: 0, y: emblemRadius * 1.15))
        emblemCross.path = crossPath
        emblemCross.position = emblemCenter
        emblemCross.strokeColor = Theme.brassDark.withAlphaComponent(0.75)
        emblemCross.lineWidth = 1

        let tileSide = w * 0.105
        for (index, tile) in emblemTiles.enumerated() {
            tile.size = CGSize(width: tileSide, height: tileSide)
            tile.layoutSubvisuals()
            tile.position = CGPoint(x: emblemCenter.x + CGFloat(index - 1) * tileSide * 1.08,
                                    y: emblemCenter.y + [ -tileSide * 0.06, tileSide * 0.035, -tileSide * 0.02 ][index])
            tile.zRotation = [ -0.035, 0.012, 0.045 ][index]
            tile.zPosition = 2
        }

        eyebrowLabel.text = "NO. 08  ·  NIGHT TABLE"
        eyebrowLabel.fontSize = w * 0.040
        eyebrowLabel.fontColor = Theme.brassLight
        eyebrowLabel.position = CGPoint(x: w / 2, y: h * 0.685)

        titleLabel.text = "Mah Safe"
        titleLabel.fontSize = w * 0.122
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h * 0.630)

        subtitleLabel.text = "Tiles, tells, and a stubborn brass lock"
        subtitleLabel.fontSize = w * 0.027
        subtitleLabel.fontColor = Theme.textDim
        subtitleLabel.position = CGPoint(x: w / 2, y: h * 0.585)

        let cabinetSize = CGSize(width: w * 0.88, height: h * 0.405)
        let cabinetCenter = CGPoint(x: w / 2, y: h * 0.342)
        cabinetPanel.texture = TableSurfaces.rounded(size: cabinetSize,
                                                    top: Theme.panelRaised,
                                                    bottom: Theme.backgroundBottom.withAlphaComponent(0.96),
                                                    radius: w * 0.035)
        cabinetPanel.size = cabinetSize
        cabinetPanel.position = cabinetCenter
        cabinetPanel.zPosition = -1

        let borderRect = CGRect(x: -cabinetSize.width / 2 + 8,
                                y: -cabinetSize.height / 2 + 8,
                                width: cabinetSize.width - 16,
                                height: cabinetSize.height - 16)
        cabinetBorder.path = CGPath(roundedRect: borderRect,
                                    cornerWidth: w * 0.022,
                                    cornerHeight: w * 0.022,
                                    transform: nil)
        cabinetBorder.position = cabinetCenter
        cabinetBorder.strokeColor = Theme.brassDark.withAlphaComponent(0.75)
        cabinetBorder.lineWidth = 1
        cabinetBorder.fillColor = .clear
        cabinetBorder.zPosition = -0.5

        // 总体进度一览：已开保险箱数 / 星数 / 成就数。
        let stats = StatisticsManager.load()
        let cleared = SaveManager.progress.stars.count
        let totalStars = SaveManager.progress.stars.values.reduce(0, +)
        progressLabel.text = "Tables  \(cleared)/100    ·    Stars  \(totalStars)    ·    Marks  \(stats.unlockedAchievements.count)"
        progressLabel.fontSize = w * 0.025
        progressLabel.fontColor = Theme.brassLight
        progressLabel.position = CGPoint(x: w / 2, y: h * 0.510)

        let linePath = CGMutablePath()
        linePath.move(to: CGPoint(x: -w * 0.31, y: 0))
        linePath.addLine(to: CGPoint(x: -w * 0.025, y: 0))
        linePath.move(to: CGPoint(x: w * 0.025, y: 0))
        linePath.addLine(to: CGPoint(x: w * 0.31, y: 0))
        divider.path = linePath
        divider.position = CGPoint(x: w / 2, y: h * 0.485)
        divider.strokeColor = Theme.brassDark
        divider.lineWidth = 1

        playButton.setSize(CGSize(width: w * 0.67, height: h * 0.068))
        playButton.layout(at: CGPoint(x: w / 2, y: h * 0.435))

        dailyButton.setSize(CGSize(width: w * 0.325, height: h * 0.057), fontSize: w * 0.024)
        dailyButton.layout(at: CGPoint(x: w / 2 - w * 0.175, y: h * 0.352))

        blitzButton.setSize(CGSize(width: w * 0.325, height: h * 0.057), fontSize: w * 0.024)
        blitzButton.layout(at: CGPoint(x: w / 2 + w * 0.175, y: h * 0.352))

        rulesButton.setSize(CGSize(width: w * 0.32, height: h * 0.055), fontSize: w * 0.025)
        settingsButton.setSize(CGSize(width: w * 0.32, height: h * 0.055), fontSize: w * 0.025)
        rulesButton.layout(at: CGPoint(x: w / 2 - w * 0.175, y: h * 0.275))
        settingsButton.layout(at: CGPoint(x: w / 2 + w * 0.175, y: h * 0.275))

        codeLabel.text = "House copy 08  ·  played offline"
        codeLabel.fontSize = w * 0.022
        codeLabel.fontColor = Theme.textDim.withAlphaComponent(0.72)
        codeLabel.position = CGPoint(x: w / 2, y: h * 0.194)

        refreshToggles()
    }

    func refreshToggles() {
        soundButton.setTitle(SaveManager.soundEnabled ? "Sound: On" : "Sound: Off")
        hapticButton.setTitle(SaveManager.hapticEnabled ? "Haptics: On" : "Haptics: Off")
    }

    func target(at p: CGPoint) -> TapTarget? {
        let candidates: [(ButtonNode, () -> Void)] = [
            (playButton, { [weak self] in self?.onPlay?() }),
            (dailyButton, { [weak self] in self?.onDaily?() }),
            (blitzButton, { [weak self] in self?.onBlitz?() }),
            (rulesButton, { [weak self] in self?.onRules?() }),
            (settingsButton, { [weak self] in self?.onSettings?() }),
            (soundButton, { [weak self] in self?.onSoundToggle?() }),
            (hapticButton, { [weak self] in self?.onHapticToggle?() }),
            (resetButton, { [weak self] in self?.onReset?() })
        ]
        for (button, action) in candidates {
            if !button.isHidden && button.isEnabled && button.hitFrame.contains(p) {
                return TapTarget(action: action,
                                 onPress: { button.press() },
                                 onRelease: { button.release() })
            }
        }
        return nil
    }
}
