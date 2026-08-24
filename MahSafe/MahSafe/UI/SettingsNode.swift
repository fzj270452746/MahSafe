//
//  SettingsNode.swift
//  MahSafe
//
//  设置页：音效 / 震动开关、统计入口、重置进度（二次确认）、关于信息。
//  重置用「再点一次确认」的原地二次确认，避免弹窗。
//

import SpriteKit
import UIKit

final class SettingsNode: SKNode {

    var onBack: (() -> Void)?
    var onSoundToggle: (() -> Void)?
    var onHapticToggle: (() -> Void)?
    var onMusicToggle: (() -> Void)?
    var onStatistics: (() -> Void)?
    var onReset: (() -> Void)?

    private let backButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let soundButton: ButtonNode
    private let musicButton: ButtonNode
    private let hapticButton: ButtonNode
    private let statisticsButton: ButtonNode
    private let resetButton: ButtonNode
    private let aboutLabel: SKLabelNode

    /// 是否处于「确认重置」待确认状态。
    private var armReset = false

    override init() {
        backButton = ButtonNode(title: "←", size: CGSize(width: 52, height: 52), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        soundButton = ButtonNode(title: "Sound: On", size: .zero, style: .secondary)
        musicButton = ButtonNode(title: "Music: On", size: .zero, style: .secondary)
        hapticButton = ButtonNode(title: "Haptics: On", size: .zero, style: .secondary)
        statisticsButton = ButtonNode(title: "Open the ledger", size: .zero, style: .secondary)
        resetButton = ButtonNode(title: "Clear the notebook", size: .zero, style: .ghost)
        aboutLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        super.init()

        titleLabel.horizontalAlignmentMode = .center
        titleLabel.verticalAlignmentMode = .center
        aboutLabel.horizontalAlignmentMode = .center
        aboutLabel.verticalAlignmentMode = .center
        aboutLabel.numberOfLines = 0

        addChild(backButton)
        addChild(titleLabel)
        addChild(soundButton)
        addChild(musicButton)
        addChild(hapticButton)
        addChild(statisticsButton)
        addChild(resetButton)
        addChild(aboutLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in size: CGSize, safeArea: UIEdgeInsets) {
        let w = size.width
        let h = size.height

        titleLabel.text = "Table drawer"
        titleLabel.fontSize = w * 0.068
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: w / 2, y: h - safeArea.top - h * 0.07)
        backButton.layout(at: CGPoint(x: w * 0.07, y: h - safeArea.top - h * 0.07))

        let buttonW = w * 0.62
        let buttonH = h * 0.062
        let gap = h * 0.022
        var y = h - safeArea.top - h * 0.18

        soundButton.setSize(CGSize(width: buttonW, height: buttonH))
        soundButton.layout(at: CGPoint(x: w / 2, y: y))
        y -= buttonH + gap

        musicButton.setSize(CGSize(width: buttonW, height: buttonH))
        musicButton.layout(at: CGPoint(x: w / 2, y: y))
        y -= buttonH + gap

        hapticButton.setSize(CGSize(width: buttonW, height: buttonH))
        hapticButton.layout(at: CGPoint(x: w / 2, y: y))
        y -= buttonH + gap

        statisticsButton.setSize(CGSize(width: buttonW, height: buttonH))
        statisticsButton.layout(at: CGPoint(x: w / 2, y: y))
        y -= buttonH + gap

        resetButton.setSize(CGSize(width: buttonW, height: buttonH))
        resetButton.setTitleColor(Theme.danger)
        resetButton.layout(at: CGPoint(x: w / 2, y: y))

        aboutLabel.text = "Mah Safe · v1.0\nA small tiles-and-locks puzzle for a quiet table."
        aboutLabel.fontSize = w * 0.032
        aboutLabel.fontColor = Theme.textDim
        aboutLabel.preferredMaxLayoutWidth = w * 0.8
        aboutLabel.position = CGPoint(x: w / 2, y: safeArea.bottom + h * 0.06)

        armReset = false
        refreshToggles()
    }

    func refreshToggles() {
        soundButton.setTitle(SaveManager.soundEnabled ? "Sound: On" : "Sound: Off")
        musicButton.setTitle(SaveManager.musicEnabled ? "Music: On" : "Music: Off")
        hapticButton.setTitle(SaveManager.hapticEnabled ? "Haptics: On" : "Haptics: Off")
    }

    /// 处理重置按钮：第一次按下进入待确认，第二次按下真正重置。
    private func handleReset() {
        if armReset {
            armReset = false
            resetButton.setTitle("Reset Progress")
            resetButton.setTitleColor(Theme.danger)
            onReset?()
        } else {
            armReset = true
            resetButton.setTitle("Tap again to confirm")
            resetButton.setTitleColor(Theme.warning)
        }
    }

    /// 离开页面时清掉待确认状态，避免误触。
    func cancelArmedReset() {
        armReset = false
        resetButton.setTitle("Reset Progress")
        resetButton.setTitleColor(Theme.danger)
    }

    func target(at p: CGPoint) -> TapTarget? {
        if backButton.isEnabled && backButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.backButton.press() },
                             onRelease: { [weak self] in self?.backButton.release() })
        }
        if soundButton.isEnabled && soundButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onSoundToggle?() },
                             onPress: { [weak self] in self?.soundButton.press() },
                             onRelease: { [weak self] in self?.soundButton.release() })
        }
        if musicButton.isEnabled && musicButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onMusicToggle?() },
                             onPress: { [weak self] in self?.musicButton.press() },
                             onRelease: { [weak self] in self?.musicButton.release() })
        }
        if hapticButton.isEnabled && hapticButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onHapticToggle?() },
                             onPress: { [weak self] in self?.hapticButton.press() },
                             onRelease: { [weak self] in self?.hapticButton.release() })
        }
        if statisticsButton.isEnabled && statisticsButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onStatistics?() },
                             onPress: { [weak self] in self?.statisticsButton.press() },
                             onRelease: { [weak self] in self?.statisticsButton.release() })
        }
        if resetButton.isEnabled && resetButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.handleReset() },
                             onPress: { [weak self] in self?.resetButton.press() },
                             onRelease: { [weak self] in self?.resetButton.release() })
        }
        return nil
    }
}
