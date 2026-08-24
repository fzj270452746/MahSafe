//
//  LevelSelectNode.swift
//  MahSafe
//
//  选关：按章节分页，每页 10 关（2×5），显示星级与锁定状态。
//

import SpriteKit
import UIKit

final class LevelSelectNode: SKNode {

    var onBack: (() -> Void)?
    var onSelect: ((Int) -> Void)?

    private var chapter = 1
    private let backButton: ButtonNode
    private let prevButton: ButtonNode
    private let nextButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let chapterLabel: SKLabelNode
    private let chapterSubtitleLabel: SKLabelNode
    private let chapterProgressLabel: SKLabelNode
    private var levelButtons: [Int: ButtonNode] = [:]
    private var starRows: [Int: [StarNode]] = [:]
    private var bestTimeLabels: [Int: SKLabelNode] = [:]
    private var layoutSize: CGSize = .zero
    private var safeArea: UIEdgeInsets = .zero

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        prevButton = ButtonNode(title: "‹", size: CGSize(width: 52, height: 52), style: .ghost)
        nextButton = ButtonNode(title: "›", size: CGSize(width: 52, height: 52), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.headingFont)
        chapterLabel = SKLabelNode(fontNamed: Theme.displayFont)
        chapterSubtitleLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        chapterProgressLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        chapterLabel.horizontalAlignmentMode = .center
        chapterLabel.verticalAlignmentMode = .center
        chapterSubtitleLabel.horizontalAlignmentMode = .center
        chapterSubtitleLabel.verticalAlignmentMode = .center
        chapterProgressLabel.horizontalAlignmentMode = .center
        chapterProgressLabel.verticalAlignmentMode = .center

        addChild(backButton)
        addChild(prevButton)
        addChild(nextButton)
        addChild(titleLabel)
        addChild(chapterLabel)
        addChild(chapterSubtitleLabel)
        addChild(chapterProgressLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        layoutSize = size
        self.safeArea = safeArea

        let w = size.width
        let h = size.height

        titleLabel.text = "The table book"
        titleLabel.fontSize = w * 0.07
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.08)

        backButton.layout(at: CGPoint(x: w * 0.07, y: h - safeArea.top - h * 0.08))

        chapterLabel.fontSize = w * 0.055
        chapterLabel.fontColor = Theme.textGold
        chapterLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.17)
        chapterSubtitleLabel.fontSize = w * 0.035
        chapterSubtitleLabel.fontColor = Theme.textDim
        chapterSubtitleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.215)

        chapterProgressLabel.fontSize = w * 0.032
        chapterProgressLabel.fontColor = Theme.brassLight
        chapterProgressLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.255)

        prevButton.layout(at: CGPoint(x: w * 0.10, y: h - safeArea.top - h * 0.17))
        nextButton.layout(at: CGPoint(x: w * 0.90, y: h - safeArea.top - h * 0.17))

        reload()
    }

    func setChapter(_ n: Int) {
        chapter = min(max(n, 1), LevelRepository.chapters.count)
        reload()
    }

    private func reload() {
        for button in levelButtons.values { button.removeFromParent() }
        for row in starRows.values { for star in row { star.removeFromParent() } }
        for label in bestTimeLabels.values { label.removeFromParent() }
        levelButtons.removeAll()
        starRows.removeAll()
        bestTimeLabels.removeAll()

        let stats = StatisticsManager.load()

        let info = LevelRepository.chapters[chapter - 1]
        chapterLabel.text = "Room \(info.number)"
        chapterSubtitleLabel.text = info.subtitle
        prevButton.setEnabled(chapter > 1)
        nextButton.setEnabled(chapter < LevelRepository.chapters.count)

        // 章节维度的进度小结：通关数 + 累计星数。
        let cleared = info.range.filter { SaveManager.stars(for: $0) > 0 }.count
        let starSum = info.range.reduce(0) { $0 + SaveManager.stars(for: $1) }
        chapterProgressLabel.text = "Played \(cleared)/\(info.range.count)   ·   Stars \(starSum)/\(info.range.count * 3)"

        let w = layoutSize.width
        let h = layoutSize.height
        let cols = 5
        let rows = 2

        let cellW = w * 0.15
        let cellH = cellW * 0.88
        let gapX = w * 0.035
        let gapY = h * 0.035
        let gridCenterY = h * 0.46

        let totalW = CGFloat(cols) * cellW + CGFloat(cols - 1) * gapX
        let startX = w / 2 - totalW / 2 + cellW / 2
        let totalH = CGFloat(rows) * cellH + CGFloat(rows - 1) * gapY
        let startY = gridCenterY + totalH / 2 - cellH / 2

        for i in 0..<(cols * rows) {
            let level = (chapter - 1) * 10 + i + 1
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (cellW + gapX)
            let y = startY - CGFloat(row) * (cellH + gapY)

            let unlocked = SaveManager.isUnlocked(level)
            let button = ButtonNode(title: "\(level)",
                                    size: CGSize(width: cellW, height: cellH),
                                    style: unlocked ? .secondary : .ghost,
                                    fontSize: cellH * 0.5)
            button.layout(at: CGPoint(x: x, y: y))
            if !unlocked {
                button.setEnabled(false)
            }
            addChild(button)
            levelButtons[level] = button

            let starCount = SaveManager.stars(for: level)
            var stars: [StarNode] = []
            let starSize = cellW * 0.2
            for s in 0..<3 {
                let star = StarNode(size: starSize, filled: s < starCount)
                star.position = CGPoint(x: x + CGFloat(s - 1) * (starSize * 1.4),
                                        y: y - cellH * 0.66)
                star.alpha = unlocked ? 1.0 : 0.35
                addChild(star)
                stars.append(star)
            }
            starRows[level] = stars

            // 已通关的关卡，在数字下方补一行最快用时，一眼看到自己的成绩。
            if let best = stats.bestTimes[level], starCount > 0 {
                let timeLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
                timeLabel.text = Format.clock(best)
                timeLabel.fontSize = cellW * 0.16
                timeLabel.fontColor = Theme.textDim
                timeLabel.horizontalAlignmentMode = .center
                timeLabel.verticalAlignmentMode = .center
                timeLabel.position = CGPoint(x: x, y: y - cellH * 0.34)
                addChild(timeLabel)
                bestTimeLabels[level] = timeLabel
            }
        }
    }

    func target(at p: CGPoint) -> TapTarget? {
        if backButton.isEnabled && backButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.backButton.press() },
                             onRelease: { [weak self] in self?.backButton.release() })
        }
        if prevButton.isEnabled && prevButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.setChapter((self?.chapter ?? 1) - 1) },
                             onPress: { [weak self] in self?.prevButton.press() },
                             onRelease: { [weak self] in self?.prevButton.release() })
        }
        if nextButton.isEnabled && nextButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.setChapter((self?.chapter ?? 1) + 1) },
                             onPress: { [weak self] in self?.nextButton.press() },
                             onRelease: { [weak self] in self?.nextButton.release() })
        }
        for (level, button) in levelButtons.sorted(by: { $0.key < $1.key }) {
            if button.isEnabled && button.hitFrame.contains(p) {
                return TapTarget(action: { [weak self] in self?.onSelect?(level) },
                                 onPress: { button.press() },
                                 onRelease: { button.release() })
            }
        }
        return nil
    }
}
