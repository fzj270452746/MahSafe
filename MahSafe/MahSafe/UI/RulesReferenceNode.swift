//
//  RulesReferenceNode.swift
//  MahSafe
//
//  玩法说明：把「四种操作、三级提示、星级与限时、全部 12 种规则」分页讲清楚。
//  内容是静态文案，按页重排，避免一次性堆满屏幕。
//

import SpriteKit
import UIKit

// MARK: - 内容模型

struct RulesSection {
    let heading: String
    let body: [String]
}

struct RulesPage {
    let title: String
    let sections: [RulesSection]
}

// MARK: - 节点

final class RulesReferenceNode: SKNode {

    var onBack: (() -> Void)?

    private let backButton: ButtonNode
    private let prevButton: ButtonNode
    private let nextButton: ButtonNode
    private let panel: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let pageTitleLabel: SKLabelNode
    private let pageIndicatorLabel: SKLabelNode
    private var contentLabels: [SKLabelNode] = []

    private var page = 0
    private var layoutSize: CGSize = .zero
    private var safeArea: UIEdgeInsets = .zero

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        prevButton = ButtonNode(title: "‹", size: CGSize(width: 52, height: 52), style: .ghost)
        nextButton = ButtonNode(title: "›", size: CGSize(width: 52, height: 52), style: .ghost)
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        pageTitleLabel = SKLabelNode(fontNamed: Theme.headingFont)
        pageIndicatorLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        pageTitleLabel.horizontalAlignmentMode = .left
        pageTitleLabel.verticalAlignmentMode = .top
        pageIndicatorLabel.horizontalAlignmentMode = .center
        pageIndicatorLabel.verticalAlignmentMode = .center

        addChild(backButton)
        addChild(titleLabel)
        addChild(panel)
        panel.addChild(pageTitleLabel)
        addChild(prevButton)
        addChild(nextButton)
        addChild(pageIndicatorLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    // MARK: - 布局

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        layoutSize = size
        self.safeArea = safeArea

        let w = size.width
        let h = size.height

        titleLabel.text = "House rules"
        titleLabel.fontSize = w * 0.068
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.07)
        backButton.layout(at: CGPoint(x: w * 0.07, y: h - safeArea.top - h * 0.07))

        let panelW = w * 0.90
        let panelTop = h - safeArea.top - h * 0.13
        let panelBottom = safeArea.bottom + h * 0.10
        let panelH = panelTop - panelBottom
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 20)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: (panelTop + panelBottom) / 2)
        panel.zPosition = 0

        prevButton.layout(at: CGPoint(x: w * 0.12, y: panelBottom * 0.55))
        nextButton.layout(at: CGPoint(x: w * 0.88, y: panelBottom * 0.55))
        pageIndicatorLabel.fontSize = w * 0.034
        pageIndicatorLabel.fontColor = Theme.textDim
        pageIndicatorLabel.position = CGPoint(x: w / 2, y: panelBottom * 0.55)

        page = 0
        reload()
    }

    private func reload() {
        let pages = Self.pages
        guard pages.indices.contains(page) else { return }
        let current = pages[page]

        for label in contentLabels { label.removeFromParent() }
        contentLabels.removeAll()

        prevButton.setEnabled(page > 0)
        nextButton.setEnabled(page < pages.count - 1)
        pageIndicatorLabel.text = "\(page + 1) / \(pages.count)"

        let panelW = panel.size.width
        let panelH = panel.size.height
        let insetX = panelW * 0.07
        let insetTop = panelH * 0.10

        pageTitleLabel.text = current.title
        pageTitleLabel.fontSize = panelW * 0.056
        pageTitleLabel.fontColor = Theme.textGold
        pageTitleLabel.position = CGPoint(x: -panelW / 2 + insetX, y: panelH / 2 - insetTop)
        pageTitleLabel.zPosition = 1

        // 从页面标题往下逐段排布标题 + 正文。
        var cursorY = panelH / 2 - insetTop - panelW * 0.10
        let lineHeight = panelW * 0.045
        let bodyWidth = panelW - insetX * 2

        for section in current.sections {
            cursorY = Self.place(section.heading,
                                 at: cursorY,
                                 font: "AvenirNext-DemiBold",
                                 size: panelW * 0.044,
                                 color: Theme.textLight,
                                 width: bodyWidth,
                                 parent: panel,
                                 labels: &contentLabels)
            cursorY -= lineHeight * 0.35

            for line in section.body {
                cursorY = Self.place(line,
                                     at: cursorY,
                                     font: "AvenirNext-Medium",
                                     size: panelW * 0.036,
                                     color: Theme.textDim,
                                     width: bodyWidth,
                                     parent: panel,
                                     labels: &contentLabels)
            }
            cursorY -= lineHeight * 0.7
        }
    }

    /// 在指定 y 处放置一个多行标签，返回下一行的起始 y。
    private static func place(_ text: String,
                              at y: CGFloat,
                              font: String,
                              size: CGFloat,
                              color: UIColor,
                              width: CGFloat,
                              parent: SKNode,
                              labels: inout [SKLabelNode]) -> CGFloat {
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .top
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = width
        label.lineBreakMode = .byWordWrapping
        label.position = CGPoint(x: -width / 2, y: y)
        label.zPosition = 1
        parent.addChild(label)
        labels.append(label)

        // 估算占高：按最坏情况（每行不足一个词）取整，留足间距。
        let lines = max(1, Int(ceil(Self.estimatedWidth(text, size: size) / width)))
        return y - CGFloat(lines) * (size * 1.35)
    }

    /// 粗略估算单行文本宽度（中文按全宽计，英文按字符计）。
    private static func estimatedWidth(_ text: String, size: CGFloat) -> CGFloat {
        var width: CGFloat = 0
        for scalar in text.unicodeScalars {
            if scalar.value > 0x2E80 {
                width += size
            } else {
                width += size * 0.55
            }
        }
        return width
    }

    // MARK: - 命中

    func target(at p: CGPoint) -> TapTarget? {
        if backButton.isEnabled && backButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.backButton.press() },
                             onRelease: { [weak self] in self?.backButton.release() })
        }
        if prevButton.isEnabled && prevButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in
                guard let self else { return }
                self.page = max(0, self.page - 1)
                self.reload()
            }, onPress: { [weak self] in self?.prevButton.press() },
               onRelease: { [weak self] in self?.prevButton.release() })
        }
        if nextButton.isEnabled && nextButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in
                guard let self else { return }
                self.page = min(Self.pages.count - 1, self.page + 1)
                self.reload()
            }, onPress: { [weak self] in self?.nextButton.press() },
               onRelease: { [weak self] in self?.nextButton.release() })
        }
        return nil
    }
}

// MARK: - 静态内容

extension RulesReferenceNode {

    static let pages: [RulesPage] = [
        RulesPage(title: "The Vault", sections: [
            RulesSection(heading: "Your Goal", body: [
                "Every safe holds a mahjong board hiding a secret. Solve the rule shown in the HUD to open it.",
                "There are 100 safes across 10 chapters. New rules are introduced a few at a time, so you always know what to do."
            ]),
            RulesSection(heading: "Four Moves", body: [
                "Tap — select a tile to answer a puzzle.",
                "Swipe — drag across a tile to rotate it 90°.",
                "Hold — long-press a tile to peek at its hidden back.",
                "Swap — tap two tiles to exchange their positions."
            ]),
            RulesSection(heading: "Submitting", body: [
                "Tap-order puzzles check as you go. Transform puzzles (swap / rotate) need you to pull the safe handle, or press Confirm, to submit your answer."
            ])
        ]),

        RulesPage(title: "Hints & Stars", sections: [
            RulesSection(heading: "Three Levels of Help", body: [
                "The HUD hint button gives up to three hints per level.",
                "Hint 1 explains the rule. Hint 2 points out what to look for. Hint 3 lights up the exact tiles."
            ]),
            RulesSection(heading: "Earning Stars", body: [
                "Every level starts at 3 stars.",
                "Use a hint and you lose a star. Beat the time targets and you keep them.",
                "Slower than the two-star or three-star par time costs you a star each."
            ]),
            RulesSection(heading: "Timed Safes", body: [
                "Chapter 9 safes tick down in real time. Open them before the clock runs out — or the safe slams shut and you retry."
            ])
        ]),

        RulesPage(title: "Find the Odd One", sections: [
            RulesSection(heading: "The Lone Tile", body: [
                "Every tile appears in pairs — except one. Tap the tile that appears exactly once."
            ]),
            RulesSection(heading: "The Only Pair", body: [
                "Every tile appears once — except a single identical pair. Tap both tiles of that pair."
            ]),
            RulesSection(heading: "The Impostor", body: [
                "One tile breaks a visible pattern (for example, the only non-sequence tile). Spot it and tap it."
            ])
        ]),

        RulesPage(title: "Count & Sequence", sections: [
            RulesSection(heading: "Count & Click", body: [
                "Count how many times each tile type appears on the board, then tap one tile of each type from most frequent to least frequent."
            ]),
            RulesSection(heading: "The Winding Path", body: [
                "The tiles hide a path. Tap them in the order the path winds across the board."
            ])
        ]),

        RulesPage(title: "Transform the Board", sections: [
            RulesSection(heading: "Mirror Image", body: [
                "The board must end up as the mirror of its current layout. Swap tiles to match the reflection, then submit."
            ]),
            RulesSection(heading: "The Shuffle", body: [
                "The tiles are scrambled from a hidden order. Swap them back into the correct arrangement, then submit."
            ]),
            RulesSection(heading: "Set Upright", body: [
                "Some tiles lie on their side. Swipe each tilted tile until every one stands upright, then submit."
            ]),
            RulesSection(heading: "Point Inward", body: [
                "Each tile should point toward the center of the board. Rotate the arrows until all point inward, then submit."
            ])
        ]),

        RulesPage(title: "Peek & Place", sections: [
            RulesSection(heading: "Hidden Marks", body: [
                "Every tile hides a mark on its back. Long-press to peek, find the tile whose mark is different, and tap it."
            ]),
            RulesSection(heading: "The Gap", body: [
                "One tile is missing from the board. Tap the gap, then pick the correct tile from the rack below."
            ]),
            RulesSection(heading: "The Substitute", body: [
                "One tile on the board is wrong. Tap it, then choose the correct replacement from the rack."
            ])
        ]),

        RulesPage(title: "The Chain", sections: [
            RulesSection(heading: "Multi-Rule Safes", body: [
                "Late chapters chain several rules into one safe. The HUD shows you each step as you reach it.",
                "Complete each sub-task in order — the safe only opens once every link of the chain is solved."
            ]),
            RulesSection(heading: "Tips", body: [
                "Use moves deliberately: fewer moves and no hints keep all three stars.",
                "Stuck? A hint costs a star but never locks the level."
            ])
        ])
    ]
}
