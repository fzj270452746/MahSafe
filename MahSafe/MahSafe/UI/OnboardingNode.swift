//
//  OnboardingNode.swift
//  MahSafe
//
//  首次启动的教学浮层：用三张卡片讲清目标、四种手势与提示/星级。
//  每次启动只在从未看过时出现一次，之后可随时在「玩法说明」里回看。
//

import SpriteKit
import UIKit

final class OnboardingNode: SKNode {

    var onBegin: (() -> Void)?

    private let dim: SKSpriteNode
    private let panel: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let glyphLabel: SKLabelNode
    private let bodyLabel: SKLabelNode
    private var dots: [SKShapeNode] = []
    private let nextButton: ButtonNode
    private let skipButton: ButtonNode

    private struct Page {
        let glyph: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(glyph: "🔐",
             title: "Open the Vault",
             body: "Each safe hides one correct answer. Study the tiles, then tap, rotate, flip or swap to match it before the safe seals."),
        Page(glyph: "🎮",
             title: "Four Ways to Play",
             body: "Tap to pick, swipe to rotate, long-press to peek behind a tile, and tap two tiles to swap them. The instruction bar tells you which move a puzzle wants."),
        Page(glyph: "⭐️",
             title: "Hints & Stars",
             body: "Stuck? Use a hint — three levels of help, and fewer hints means a higher star rating. Perfect runs earn special achievements.")
    ]

    private var index = 0

    override init() {
        dim = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        // 注意：不要用 SKLabelNode(fontNamed: nil)，它在渲染时会在
        // SKCLabelNode::rebuildFont() 里对字体做 CFRelease 触发崩溃。
        // 「👆」这类手势 emoji 在 AvenirNext 下回退成空白，换成 🎮 即可。
        glyphLabel = SKLabelNode(fontNamed: Theme.displayFont)
        bodyLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        nextButton = ButtonNode(title: "CONTINUE", size: .zero, style: .primary)
        skipButton = ButtonNode(title: "SKIP BRIEFING", size: .zero, style: .ghost)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        glyphLabel.horizontalAlignmentMode = .center
        glyphLabel.verticalAlignmentMode = .center
        bodyLabel.horizontalAlignmentMode = .center
        bodyLabel.verticalAlignmentMode = .center
        bodyLabel.numberOfLines = 0

        addChild(dim)
        addChild(panel)
        panel.addChild(glyphLabel)
        panel.addChild(titleLabel)
        panel.addChild(bodyLabel)
        glyphLabel.zPosition = 1
        titleLabel.zPosition = 1
        bodyLabel.zPosition = 1
        addChild(nextButton)
        addChild(skipButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        let w = size.width
        let h = size.height

        dim.texture = SKTexture(color: UIColor.black.withAlphaComponent(0.78))
        dim.size = size
        dim.position = CGPoint(x: w / 2, y: h / 2)
        dim.zPosition = 0

        let panelW = w * 0.86
        let panelH = h * 0.62
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 24)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: h * 0.52)
        panel.zPosition = 1

        let skipSize = CGSize(width: w * 0.32, height: h * 0.055)
        skipButton.setSize(skipSize, fontSize: w * 0.034)
        skipButton.layout(at: CGPoint(x: w / 2 + panelW / 2 - skipSize.width / 2 - w * 0.02,
                                      y: h * 0.52 + panelH / 2 + h * 0.055))
        skipButton.zPosition = 2

        nextButton.setSize(CGSize(width: w * 0.5, height: h * 0.065))
        nextButton.layout(at: CGPoint(x: w / 2, y: h * 0.52 - panelH / 2 + h * 0.06))
        nextButton.zPosition = 2

        // 三个圆点指示当前页。
        for dot in dots { dot.removeFromParent() }
        dots.removeAll()
        let dotY = h * 0.52 - panelH / 2 + h * 0.13
        for i in 0..<pages.count {
            let dot = SKShapeNode(circleOfRadius: w * 0.012)
            dot.fillColor = i == 0 ? Theme.brassLight : Theme.metalDark
            dot.strokeColor = i == 0 ? Theme.textGold : Theme.metalMid
            dot.lineWidth = 1
            dot.position = CGPoint(x: w / 2 + CGFloat(i - 1) * w * 0.06, y: dotY)
            dot.zPosition = 2
            addChild(dot)
            dots.append(dot)
        }

        reload()
    }

    private func reload() {
        let page = pages[index]
        let panelW = panel.size.width
        let panelH = panel.size.height

        glyphLabel.text = page.glyph
        glyphLabel.fontSize = panelW * 0.22
        glyphLabel.fontColor = Theme.textLight
        glyphLabel.position = CGPoint(x: 0, y: panelH * 0.30)

        titleLabel.text = page.title
        titleLabel.fontSize = panelW * 0.085
        titleLabel.fontColor = Theme.textGold
        titleLabel.position = CGPoint(x: 0, y: panelH * 0.10)

        bodyLabel.text = page.body
        bodyLabel.fontSize = panelW * 0.042
        bodyLabel.fontColor = Theme.textDim
        bodyLabel.preferredMaxLayoutWidth = panelW * 0.84
        bodyLabel.position = CGPoint(x: 0, y: -panelH * 0.16)

        nextButton.setTitle(index == pages.count - 1 ? "Open the table" : "Keep reading")

        for (i, dot) in dots.enumerated() {
            dot.fillColor = i == index ? Theme.brassLight : Theme.metalDark
            dot.strokeColor = i == index ? Theme.textGold : Theme.metalMid
        }
    }

    private func advance() {
        if index < pages.count - 1 {
            index += 1
            reload()
        } else {
            onBegin?()
        }
    }

    func target(at p: CGPoint) -> TapTarget? {
        if nextButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.advance() },
                             onPress: { [weak self] in self?.nextButton.press() },
                             onRelease: { [weak self] in self?.nextButton.release() })
        }
        if skipButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBegin?() },
                             onPress: { [weak self] in self?.skipButton.press() },
                             onRelease: { [weak self] in self?.skipButton.release() })
        }
        return nil
    }
}
