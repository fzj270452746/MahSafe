//
//  ButtonNode.swift
//  MahSafe
//
//  可点按钮。只负责「画出来 + 按下去的手感」，命中与回调由 GameScene 统一驱动。
//

import SpriteKit
import UIKit

/// 一个可点目标：点下去要执行的动作，以及可选的按下 / 松开视觉。
struct TapTarget {
    let action: () -> Void
    var onPress: (() -> Void)? = nil
    var onRelease: (() -> Void)? = nil
}

final class ButtonNode: SKNode {

    enum Style {
        case primary   // 黄铜主按钮
        case secondary // 金属次按钮
        case ghost     // 透明描边按钮
    }

    private let shadow: SKSpriteNode
    private let background: SKSpriteNode
    private let label: SKLabelNode
    private let decoration: SKShapeNode
    private let style: Style
    private(set) var size: CGSize
    private(set) var isEnabled = true

    init(title: String, size: CGSize, style: Style = .primary, fontSize: CGFloat? = nil) {
        self.style = style
        self.size = size
        self.shadow = SKSpriteNode(color: .clear, size: size)
        self.background = SKSpriteNode(color: .clear, size: size)
        self.label = SKLabelNode(fontNamed: Theme.headingFont)
        self.decoration = SKShapeNode()
        super.init()

        shadow.zPosition = -1
        shadow.alpha = style == .ghost ? 0.28 : 0.6
        addChild(shadow)

        background.zPosition = 0
        addChild(background)

        label.text = title
        label.fontName = Theme.headingFont
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        addChild(label)

        decoration.zPosition = 0.5
        addChild(decoration)

        applyAppearance(fontSize: fontSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    // MARK: - 外观

    private func applyAppearance(fontSize: CGFloat?) {
        guard size.width > 0, size.height > 0 else { return }
        background.texture = Self.backgroundTexture(style: style, size: size)
        background.size = size
        shadow.texture = TableSurfaces.control(size: size,
                                              top: UIColor.black.withAlphaComponent(0.75),
                                              bottom: UIColor.black.withAlphaComponent(0.92),
                                              border: .clear,
                                              cut: size.height * 0.18)
        shadow.size = size
        shadow.position = CGPoint(x: 0, y: -size.height * 0.07)

        label.fontSize = fontSize ?? size.height * 0.34
        label.fontColor = Self.labelColor(style: style)
        rebuildDecoration()
    }

    /// 布局时调整尺寸（会按新尺寸重建纹理与字号）。
    func setSize(_ newSize: CGSize, fontSize: CGFloat? = nil) {
        size = newSize
        applyAppearance(fontSize: fontSize)
    }

    func setTitle(_ title: String) {
        label.text = title
    }

    func setTitleColor(_ color: UIColor) {
        label.fontColor = color
    }

    private func rebuildDecoration() {
        let path = CGMutablePath()
        let inset = size.height * 0.30
        let diamond = max(2, size.height * 0.055)
        for x in [-size.width / 2 + inset, size.width / 2 - inset] {
            path.move(to: CGPoint(x: x, y: diamond))
            path.addLine(to: CGPoint(x: x + diamond, y: 0))
            path.addLine(to: CGPoint(x: x, y: -diamond))
            path.addLine(to: CGPoint(x: x - diamond, y: 0))
            path.closeSubpath()
        }
        decoration.path = path
        decoration.fillColor = style == .primary ? Theme.brassDark : Theme.brass
        decoration.strokeColor = .clear
        decoration.alpha = style == .ghost ? 0.45 : 0.8
    }

    // MARK: - 布局与命中

    func layout(at position: CGPoint) {
        self.position = position
    }

    var hitFrame: CGRect {
        CGRect(x: position.x - size.width / 2,
               y: position.y - size.height / 2,
               width: size.width,
               height: size.height)
    }

    // MARK: - 手感

    func press() {
        guard isEnabled else { return }
        background.removeAllActions()
        label.removeAllActions()
        decoration.removeAllActions()
        let press = SKAction.group([
            .scale(to: 0.96, duration: 0.06),
            .moveTo(y: -size.height * 0.025, duration: 0.06)
        ])
        background.run(press)
        label.run(press)
        decoration.run(press)
    }

    func release() {
        guard isEnabled else { return }
        let release = SKAction.group([
            .scale(to: 1.0, duration: 0.10),
            .moveTo(y: 0, duration: 0.10)
        ])
        background.run(release)
        label.run(release)
        decoration.run(release)
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        alpha = enabled ? 1.0 : 0.35
    }

    // MARK: - 纹理

    private static func backgroundTexture(style: Style, size: CGSize) -> SKTexture {
        switch style {
        case .primary:
            return TableSurfaces.control(size: size,
                                        top: Theme.brassShine,
                                        bottom: Theme.brassDark,
                                        border: Theme.brassLight,
                                        cut: size.height * 0.18)
        case .secondary:
            return TableSurfaces.control(size: size,
                                        top: Theme.metalLight,
                                        bottom: Theme.metalDark,
                                        border: Theme.brass.withAlphaComponent(0.82),
                                        cut: size.height * 0.18)
        case .ghost:
            return TableSurfaces.control(size: size,
                                        top: Theme.panelRaised,
                                        bottom: Theme.panel,
                                        border: Theme.panelBorder,
                                        cut: size.height * 0.18)
        }
    }

    private static func labelColor(style: Style) -> UIColor {
        switch style {
        case .primary: return Theme.textDark
        case .secondary: return Theme.textLight
        case .ghost: return Theme.textLight
        }
    }
}
