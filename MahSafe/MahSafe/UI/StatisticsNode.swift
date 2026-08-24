//
//  StatisticsNode.swift
//  MahSafe
//
//  统计与成就页：上半屏累计数据，下半屏成就列表（分页）。
//  成就有锁定 / 解锁两种视觉，解锁的按目录顺序排在前面。
//

import SpriteKit
import UIKit

final class StatisticsNode: SKNode {

    var onBack: (() -> Void)?

    private let backButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let summaryPanel: SKSpriteNode
    private let achievementPanel: SKSpriteNode
    private let prevButton: ButtonNode
    private let nextButton: ButtonNode
    private let pageIndicatorLabel: SKLabelNode
    private var statLabels: [SKLabelNode] = []
    private var achievementRows: [SKNode] = []

    private var page = 0
    private var layoutSize: CGSize = .zero
    private var safeArea: UIEdgeInsets = .zero

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        summaryPanel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        achievementPanel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        prevButton = ButtonNode(title: "‹", size: CGSize(width: 44, height: 44), style: .ghost)
        nextButton = ButtonNode(title: "›", size: CGSize(width: 44, height: 44), style: .ghost)
        pageIndicatorLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        pageIndicatorLabel.horizontalAlignmentMode = .center
        pageIndicatorLabel.verticalAlignmentMode = .center

        addChild(backButton)
        addChild(titleLabel)
        addChild(summaryPanel)
        addChild(achievementPanel)
        addChild(prevButton)
        addChild(nextButton)
        addChild(pageIndicatorLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        layoutSize = size
        self.safeArea = safeArea

        let w = size.width
        let h = size.height

        titleLabel.text = "The ledger"
        titleLabel.fontSize = w * 0.064
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.065)
        backButton.layout(at: CGPoint(x: w * 0.07, y: h - safeArea.top - h * 0.065))

        // 上半屏：累计数据面板。
        let summaryW = w * 0.90
        let summaryTop = h - safeArea.top - h * 0.115
        let summaryH = h * 0.24
        summaryPanel.texture = TableSurfaces.rounded(size: CGSize(width: summaryW, height: summaryH),
                                                    top: Theme.metalMid, bottom: Theme.metalDark, radius: 18)
        summaryPanel.size = CGSize(width: summaryW, height: summaryH)
        summaryPanel.position = CGPoint(x: w / 2, y: summaryTop - summaryH / 2)

        // 下半屏：成就面板 + 分页。
        let achW = w * 0.90
        let achTop = summaryTop - summaryH - h * 0.025
        let achBottom = safeArea.bottom + h * 0.045
        let achH = achTop - achBottom
        achievementPanel.texture = TableSurfaces.rounded(size: CGSize(width: achW, height: achH),
                                                        top: Theme.metalMid, bottom: Theme.metalDark, radius: 18)
        achievementPanel.size = CGSize(width: achW, height: achH)
        achievementPanel.position = CGPoint(x: w / 2, y: (achTop + achBottom) / 2)

        prevButton.layout(at: CGPoint(x: w * 0.15, y: achBottom * 0.5))
        nextButton.layout(at: CGPoint(x: w * 0.85, y: achBottom * 0.5))
        pageIndicatorLabel.fontSize = w * 0.032
        pageIndicatorLabel.fontColor = Theme.textDim
        pageIndicatorLabel.position = CGPoint(x: w / 2, y: achBottom * 0.5)

        rebuildSummary()
        page = 0
        rebuildAchievements()
    }

    // MARK: - 累计数据

    private func rebuildSummary() {
        for label in statLabels { label.removeFromParent() }
        statLabels.removeAll()

        let s = StatisticsManager.load()
        let panelW = summaryPanel.size.width
        let panelH = summaryPanel.size.height

        let cells: [(String, String)] = [
            ("\(s.totalStars) / 300", "Stars kept"),
            ("\(s.levelsCleared) / 100", "Tables opened"),
            ("\(s.perfectClears)", "Clean hands"),
            ("\(Int(s.perfectRate * 100))%", "Clean rate"),
            (Format.clock(s.totalTime), "Time at table"),
            ("\(s.totalMoves)", "Moves made")
        ]

        let cols = 3
        let rows = 2
        let cellW = panelW / CGFloat(cols)
        let cellH = panelH / CGFloat(rows)

        for (i, (value, caption)) in cells.enumerated() {
            let col = i % cols
            let row = i / cols
            let cx = -panelW / 2 + (CGFloat(col) + 0.5) * cellW
            let cy = panelH / 2 - (CGFloat(row) + 0.5) * cellH

            let valueLabel = Self.makeLabel(value,
                                            font: "AvenirNext-DemiBold",
                                            size: panelW * 0.052,
                                            color: Theme.textGold)
            valueLabel.horizontalAlignmentMode = .center
            valueLabel.position = CGPoint(x: cx, y: cy + cellH * 0.14)
            summaryPanel.addChild(valueLabel)
            statLabels.append(valueLabel)

            let captionLabel = Self.makeLabel(caption,
                                              font: "AvenirNext-Medium",
                                              size: panelW * 0.032,
                                              color: Theme.textDim)
            captionLabel.horizontalAlignmentMode = .center
            captionLabel.position = CGPoint(x: cx, y: cy - cellH * 0.22)
            summaryPanel.addChild(captionLabel)
            statLabels.append(captionLabel)
        }
    }

    // MARK: - 成就

    private func rebuildAchievements() {
        for row in achievementRows { row.removeFromParent() }
        achievementRows.removeAll()

        let s = StatisticsManager.load()
        // 已解锁的排前面，锁定的排后面，各自按目录顺序。
        let all = AchievementCatalog.all
        let unlocked = all.filter { s.unlockedAchievements.contains($0.id) }
        let locked = all.filter { !s.unlockedAchievements.contains($0.id) }
        let ordered = unlocked + locked

        let perPage = 6
        let pageCount = max(1, Int(ceil(Double(ordered.count) / Double(perPage))))
        page = min(max(page, 0), pageCount - 1)
        prevButton.setEnabled(page > 0)
        nextButton.setEnabled(page < pageCount - 1)
        pageIndicatorLabel.text = "\(page + 1) / \(pageCount)"

        let panelW = achievementPanel.size.width
        let panelH = achievementPanel.size.height
        let start = page * perPage
        let slice = ordered.dropFirst(start).prefix(perPage)

        let rowH = panelH / CGFloat(perPage)
        let insetX = panelW * 0.08

        for (i, achievement) in slice.enumerated() {
            let y = panelH / 2 - (CGFloat(i) + 0.5) * rowH
            let isUnlocked = s.unlockedAchievements.contains(achievement.id)

            let symbolLabel = Self.makeLabel(isUnlocked ? achievement.symbol : "🔒",
                                             font: "AvenirNext-DemiBold",
                                             size: panelW * 0.055,
                                             color: isUnlocked ? Theme.textGold : Theme.metalLight)
            symbolLabel.horizontalAlignmentMode = .center
            symbolLabel.position = CGPoint(x: -panelW / 2 + insetX, y: y + rowH * 0.10)
            achievementPanel.addChild(symbolLabel)
            achievementRows.append(symbolLabel)

            let titleLabel = Self.makeLabel(achievement.title,
                                            font: "AvenirNext-DemiBold",
                                            size: panelW * 0.038,
                                            color: isUnlocked ? Theme.textLight : Theme.textDim)
            titleLabel.position = CGPoint(x: -panelW / 2 + insetX + panelW * 0.10, y: y + rowH * 0.10)
            achievementPanel.addChild(titleLabel)
            achievementRows.append(titleLabel)

            let detailLabel = Self.makeLabel(achievement.detail,
                                             font: "AvenirNext-Medium",
                                             size: panelW * 0.030,
                                             color: isUnlocked ? Theme.textDim : Theme.metalLight)
            detailLabel.alpha = isUnlocked ? 1.0 : 0.7
            detailLabel.position = CGPoint(x: -panelW / 2 + insetX + panelW * 0.10, y: y - rowH * 0.18)
            achievementPanel.addChild(detailLabel)
            achievementRows.append(detailLabel)

            // 行间分隔线，视觉上分组。
            if i > 0 {
                let divider = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -panelW / 2 + insetX, y: y + rowH / 2))
                path.addLine(to: CGPoint(x: panelW / 2 - insetX, y: y + rowH / 2))
                divider.path = path
                divider.strokeColor = Theme.panelBorder
                divider.lineWidth = 1
                divider.alpha = 0.5
                achievementPanel.addChild(divider)
                achievementRows.append(divider)
            }
        }
    }

    // MARK: - 工具

    private static func makeLabel(_ text: String, font: String, size: CGFloat, color: UIColor) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.zPosition = 1
        return label
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
                self.page -= 1
                self.rebuildAchievements()
            }, onPress: { [weak self] in self?.prevButton.press() },
               onRelease: { [weak self] in self?.prevButton.release() })
        }
        if nextButton.isEnabled && nextButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in
                guard let self else { return }
                self.page += 1
                self.rebuildAchievements()
            }, onPress: { [weak self] in self?.nextButton.press() },
               onRelease: { [weak self] in self?.nextButton.release() })
        }
        return nil
    }
}
