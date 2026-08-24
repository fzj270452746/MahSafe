//
//  ChapterIntroNode.swift
//  MahSafe
//
//  章节过场：进入新章节 / 通关章节时整屏浮现标题，自动淡出。
//  纯展示层，动画结束回调由 GameScene 决定是否移除。
//

import SpriteKit
import UIKit

final class ChapterIntroNode: SKNode {

    enum Mode {
        case intro      // 首次进入章节
        case complete   // 通关整章
    }

    var onDone: (() -> Void)?

    private let dim: SKSpriteNode
    private let tagLabel: SKLabelNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private var content = SKNode()

    override init() {
        dim = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        tagLabel = SKLabelNode(fontNamed: Theme.headingFont)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        subtitleLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        super.init()

        tagLabel.horizontalAlignmentMode = .center
        tagLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        subtitleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.numberOfLines = 0
        tagLabel.zPosition = 1
        titleLabel.zPosition = 1
        subtitleLabel.zPosition = 1

        addChild(dim)
        addChild(content)
        content.addChild(tagLabel)
        content.addChild(titleLabel)
        content.addChild(subtitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func show(in size: CGSize, chapter: ChapterInfo, mode: Mode) {
        let w = size.width
        let h = size.height

        dim.texture = SKTexture(color: UIColor.black.withAlphaComponent(0.86))
        dim.size = size
        dim.position = CGPoint(x: w / 2, y: h / 2)
        dim.zPosition = 0

        let tagText = mode == .intro ? "CHAPTER \(chapter.number)" : "CHAPTER COMPLETE"
        tagLabel.text = tagText
        tagLabel.isHidden = false
        tagLabel.alpha = 1
        tagLabel.fontSize = w * 0.055
        tagLabel.fontColor = Theme.textGold
        tagLabel.position = CGPoint(x: w / 2, y: h * 0.60)

        titleLabel.text = chapter.title
        titleLabel.isHidden = false
        titleLabel.alpha = 1
        titleLabel.fontSize = w * 0.11
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h * 0.50)

        subtitleLabel.text = mode == .intro ? chapter.subtitle : "All safes in this chapter are open."
        subtitleLabel.isHidden = false
        subtitleLabel.alpha = 1
        subtitleLabel.fontSize = w * 0.045
        subtitleLabel.fontColor = Theme.textDim
        subtitleLabel.preferredMaxLayoutWidth = w * 0.8
        subtitleLabel.position = CGPoint(x: w / 2, y: h * 0.42)
    }

    /// 播放入场 → 停留 → 退场，结束后回调 onDone。
    func play() {
        content.alpha = 0
        content.setScale(0.96)
        dim.alpha = 0

        let appear = SKAction.group([
            .fadeIn(withDuration: 0.35),
            .scale(to: 1.0, duration: 0.35)
        ])
        let hold = SKAction.wait(forDuration: 1.5)
        let disappear = SKAction.group([
            .fadeOut(withDuration: 0.35),
            .scale(to: 1.04, duration: 0.35)
        ])
        dim.run(.fadeIn(withDuration: 0.35))
        content.run(.sequence([appear, hold, disappear])) { [weak self] in
            self?.onDone?()
        }
    }
}
