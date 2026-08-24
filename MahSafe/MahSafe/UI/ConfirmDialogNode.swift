//
//  ConfirmDialogNode.swift
//  MahSafe
//
//  通用确认弹窗：一句提示 + 两个按钮（继续 / 确认）。
//  用于「中途退出会丢失进度」这类不可逆操作，避免误触。
//

import SpriteKit
import UIKit

final class ConfirmDialogNode: SKNode {

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    private let dim: SKSpriteNode
    private let panel: SKSpriteNode
    private let messageLabel: SKLabelNode
    private let cancelButton: ButtonNode
    private let confirmButton: ButtonNode

    override init() {
        dim = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        panel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        messageLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        cancelButton = ButtonNode(title: "Keep Playing", size: .zero, style: .secondary)
        confirmButton = ButtonNode(title: "Leave", size: .zero, style: .ghost)
        super.init()

        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.numberOfLines = 0

        addChild(dim)
        addChild(panel)
        panel.addChild(messageLabel)
        panel.addChild(cancelButton)
        panel.addChild(confirmButton)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    /// 弹出弹窗。message 为提示文案，confirmTitle 为确认按钮文字。
    func present(in size: CGSize, message: String, confirmTitle: String) {
        let w = size.width
        let h = size.height

        dim.texture = SKTexture(color: UIColor.black.withAlphaComponent(0.70))
        dim.size = size
        dim.position = CGPoint(x: w / 2, y: h / 2)
        dim.zPosition = 0

        let panelW = w * 0.78
        let panelH = h * 0.26
        panel.texture = TableSurfaces.rounded(size: CGSize(width: panelW, height: panelH),
                                             top: Theme.metalMid, bottom: Theme.metalDark, radius: 20)
        panel.size = CGSize(width: panelW, height: panelH)
        panel.position = CGPoint(x: w / 2, y: h * 0.5)
        panel.zPosition = 1

        messageLabel.text = message
        messageLabel.fontSize = panelW * 0.05
        messageLabel.fontColor = Theme.textLight
        messageLabel.preferredMaxLayoutWidth = panelW * 0.86
        messageLabel.position = CGPoint(x: 0, y: panelH * 0.18)
        messageLabel.zPosition = 2

        let buttonW = panelW * 0.42
        let buttonH = h * 0.06
        cancelButton.setSize(CGSize(width: buttonW, height: buttonH))
        cancelButton.layout(at: CGPoint(x: -panelW * 0.23, y: -panelH * 0.20))
        cancelButton.zPosition = 2
        confirmButton.setSize(CGSize(width: buttonW, height: buttonH))
        confirmButton.setTitle(confirmTitle)
        confirmButton.setTitleColor(Theme.danger)
        confirmButton.layout(at: CGPoint(x: panelW * 0.23, y: -panelH * 0.20))
        confirmButton.zPosition = 2
    }

    func target(at p: CGPoint) -> TapTarget? {
        let pointInPanel = panel.convert(p, from: self)
        if cancelButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onCancel?() },
                             onPress: { [weak self] in self?.cancelButton.press() },
                             onRelease: { [weak self] in self?.cancelButton.release() })
        }
        if confirmButton.hitFrame.contains(pointInPanel) {
            return TapTarget(action: { [weak self] in self?.onConfirm?() },
                             onPress: { [weak self] in self?.confirmButton.press() },
                             onRelease: { [weak self] in self?.confirmButton.release() })
        }
        return nil
    }
}
