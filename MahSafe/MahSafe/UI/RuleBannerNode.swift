//
//  RuleBannerNode.swift
//  MahSafe
//
//  开局时的规则横幅：在 HUD 下方短暂滑出当前规则名与一句话提示，
//  帮助玩家快速进入状态，几秒后自动淡出。不拦截触摸。
//

import SpriteKit
import UIKit

final class RuleBannerNode: SKNode {

    var onDone: (() -> Void)?

    private let panel: SKSpriteNode
    private let titleLabel: SKLabelNode
    private let hintLabel: SKLabelNode

    override init() {
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        titleLabel = SKLabelNode(fontNamed: Theme.headingFont)
        hintLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        hintLabel.horizontalAlignmentMode = .center
        hintLabel.verticalAlignmentMode = .center
        hintLabel.numberOfLines = 0
        hintLabel.lineBreakMode = .byWordWrapping
        titleLabel.zPosition = 1
        hintLabel.zPosition = 1

        addChild(panel)
        panel.addChild(titleLabel)
        panel.addChild(hintLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets, rule: RuleKind) {
        let w = size.width
        let h = size.height

        let pw = w * 0.90
        let ph = h * 0.145
        panel.texture = TableSurfaces.control(size: CGSize(width: pw, height: ph),
                                             top: Theme.metalMid,
                                             bottom: Theme.backgroundBottom,
                                             border: Theme.brassLight,
                                             cut: ph * 0.12)
        panel.size = CGSize(width: pw, height: ph)

        // 紧贴 HUD 下沿（HUD 占顶部 14%）。
        let topY = h - safeArea.top - h * 0.14
        panel.position = CGPoint(x: w / 2, y: topY - ph / 2 - h * 0.012)
        panel.zPosition = 1

        titleLabel.isHidden = false
        titleLabel.alpha = 1
        titleLabel.text = rule.shortTitle
        titleLabel.fontSize = min(max(ph * 0.16, 13), 17)
        titleLabel.fontColor = Theme.brassShine
        titleLabel.position = CGPoint(x: 0, y: ph * 0.25)

        hintLabel.text = rule.hintText
        hintLabel.isHidden = false
        hintLabel.alpha = 1
        hintLabel.fontSize = min(max(ph * 0.18, 15), 19)
        hintLabel.fontColor = Theme.tileIvoryLight
        hintLabel.preferredMaxLayoutWidth = pw * 0.84
        hintLabel.position = CGPoint(x: 0, y: -ph * 0.12)
    }

    /// 滑入 → 停留 → 淡出，随后回调 onDone 由场景移除。
    func play() {
        panel.alpha = 0
        panel.setScale(0.92)
        let appear = SKAction.group([
            .fadeIn(withDuration: 0.28),
            .scale(to: 1.0, duration: 0.28)
        ])
        let hold = SKAction.wait(forDuration: 3.6)
        let disappear = SKAction.fadeOut(withDuration: 0.35)
        panel.run(.sequence([appear, hold, disappear])) { [weak self] in
            self?.onDone?()
        }
    }
}
