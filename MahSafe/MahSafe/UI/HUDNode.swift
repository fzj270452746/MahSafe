//
//  HUDNode.swift
//  MahSafe
//
//  对局顶部信息栏：返回 / 标题 / 规则副标题 / 提示按钮 / 计时 / 提示横幅。
//

import SpriteKit
import UIKit

final class HUDNode: SKNode {

    var onBack: (() -> Void)?
    var onHint: (() -> Void)?
    var onUndo: (() -> Void)?

    private let headerPanel: SKSpriteNode
    private let headerOutline: SKShapeNode
    private let statusLamp: SKShapeNode
    private let centerDivider: SKShapeNode
    private let backButton: ButtonNode
    private let hintButton: ButtonNode
    private let undoButton: ButtonNode
    private let titleLabel: SKLabelNode
    private let subtitleLabel: SKLabelNode
    private let timerLabel: SKLabelNode
    private let moveLabel: SKLabelNode
    private let timeBarBG: SKSpriteNode
    private let timeBarFill: SKSpriteNode
    private let hintPanel: SKSpriteNode
    private let hintLabel: SKLabelNode
    private var hintWidth: CGFloat = 300
    private var timeLimit: TimeInterval = 0

    override init() {
        headerPanel = SKSpriteNode(color: .clear, size: .zero)
        headerOutline = SKShapeNode()
        statusLamp = SKShapeNode(circleOfRadius: 3)
        centerDivider = SKShapeNode()
        backButton = ButtonNode(title: "×", size: CGSize(width: 52, height: 52), style: .ghost)
        hintButton = ButtonNode(title: "CLUE", size: CGSize(width: 84, height: 46), style: .ghost)
        undoButton = ButtonNode(title: "UNDO", size: CGSize(width: 64, height: 46), style: .ghost)
        titleLabel = SKLabelNode(fontNamed: Theme.displayFont)
        subtitleLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        timerLabel = SKLabelNode(fontNamed: Theme.displayFont)
        moveLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        timeBarBG = SKSpriteNode(color: Theme.metalDark, size: CGSize(width: 1, height: 1))
        timeBarFill = SKSpriteNode(color: Theme.textGold, size: CGSize(width: 1, height: 1))
        hintPanel = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: 1))
        hintLabel = SKLabelNode(fontNamed: Theme.bodyFont)
        super.init()

        titleLabel.verticalAlignmentMode = .center
        titleLabel.horizontalAlignmentMode = .center
        subtitleLabel.verticalAlignmentMode = .center
        subtitleLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        timerLabel.horizontalAlignmentMode = .center
        moveLabel.verticalAlignmentMode = .center
        moveLabel.horizontalAlignmentMode = .center
        hintLabel.verticalAlignmentMode = .center
        hintLabel.horizontalAlignmentMode = .center
        hintLabel.numberOfLines = 0
        hintLabel.lineBreakMode = .byWordWrapping
        hintLabel.zPosition = 1

        headerPanel.zPosition = -2
        headerOutline.zPosition = -1
        centerDivider.zPosition = -1
        statusLamp.zPosition = 1
        addChild(headerPanel)
        addChild(headerOutline)
        addChild(centerDivider)
        addChild(statusLamp)
        addChild(backButton)
        addChild(hintButton)
        addChild(undoButton)
        addChild(titleLabel)
        addChild(subtitleLabel)
        addChild(timerLabel)
        addChild(moveLabel)
        addChild(timeBarBG)
        addChild(timeBarFill)
        addChild(hintPanel)
        hintPanel.addChild(hintLabel)
        hintPanel.isHidden = true

        timeBarFill.anchorPoint = CGPoint(x: 0, y: 0.5)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    func layout(in hudRect: CGRect, title: String, subtitle: String, timed: Bool, timeLimit: TimeInterval?) {
        let h = hudRect.height
        self.timeLimit = timeLimit ?? 0

        let panelSize = CGSize(width: hudRect.width * 0.96, height: h * 0.88)
        headerPanel.texture = TableSurfaces.rounded(size: panelSize,
                                                   top: Theme.panelRaised,
                                                   bottom: Theme.panel,
                                                   radius: h * 0.12)
        headerPanel.size = panelSize
        headerPanel.position = CGPoint(x: hudRect.midX, y: hudRect.midY)

        let outlineRect = CGRect(x: -panelSize.width / 2 + 5,
                                 y: -panelSize.height / 2 + 5,
                                 width: panelSize.width - 10,
                                 height: panelSize.height - 10)
        headerOutline.path = CGPath(roundedRect: outlineRect,
                                    cornerWidth: h * 0.08,
                                    cornerHeight: h * 0.08,
                                    transform: nil)
        headerOutline.position = headerPanel.position
        headerOutline.strokeColor = Theme.brassDark.withAlphaComponent(0.82)
        headerOutline.lineWidth = 1
        headerOutline.fillColor = .clear

        // 两行排布，横向分区，避免「标题过大压到按钮」与「步数/副标题叠住」：
        // 上行：返回 | 标题 | 提示
        // 下行：步数 | 副标题（或计时） | 撤销
        let row1Y = hudRect.midY + h * 0.20
        let row2Y = hudRect.midY - h * 0.28

        let square = h * 0.37
        backButton.setSize(CGSize(width: square, height: square), fontSize: h * 0.20)
        hintButton.setSize(CGSize(width: h * 0.66, height: h * 0.32), fontSize: h * 0.105)
        undoButton.setSize(CGSize(width: h * 0.60, height: h * 0.28), fontSize: h * 0.09)
        backButton.layout(at: CGPoint(x: hudRect.minX + h * 0.55, y: row1Y))
        hintButton.layout(at: CGPoint(x: hudRect.maxX - h * 0.55, y: row1Y))
        undoButton.layout(at: CGPoint(x: hudRect.maxX - h * 0.55, y: row2Y))

        let dividerPath = CGMutablePath()
        dividerPath.move(to: CGPoint(x: -hudRect.width * 0.17, y: 0))
        dividerPath.addLine(to: CGPoint(x: hudRect.width * 0.17, y: 0))
        centerDivider.path = dividerPath
        centerDivider.position = CGPoint(x: hudRect.midX, y: hudRect.midY - h * 0.04)
        centerDivider.strokeColor = Theme.brassDark.withAlphaComponent(0.65)
        centerDivider.lineWidth = 1

        statusLamp.path = CGPath(ellipseIn: CGRect(x: -h * 0.025, y: -h * 0.025,
                                                  width: h * 0.05, height: h * 0.05),
                                 transform: nil)
        statusLamp.position = CGPoint(x: hudRect.midX - hudRect.width * 0.19, y: row1Y)
        statusLamp.fillColor = Theme.success
        statusLamp.strokeColor = Theme.lacquerLight
        statusLamp.glowWidth = h * 0.025

        moveLabel.horizontalAlignmentMode = .left
        moveLabel.fontSize = h * 0.085
        moveLabel.fontColor = Theme.textDim
        moveLabel.position = CGPoint(x: hudRect.minX + h * 0.55, y: row2Y)
        moveLabel.text = "MOVES  00"

        titleLabel.text = title.uppercased()
        titleLabel.fontSize = h * 0.245
        titleLabel.fontColor = Theme.textLight
        titleLabel.position = CGPoint(x: hudRect.midX, y: row1Y)

        subtitleLabel.text = subtitle.uppercased()
        subtitleLabel.fontSize = h * 0.095
        subtitleLabel.fontColor = Theme.brassLight
        subtitleLabel.position = CGPoint(x: hudRect.midX, y: row2Y)

        // 限时关：副标题位置让给倒计时（规则名在开局横幅里已展示）。
        if timed {
            subtitleLabel.isHidden = true
            timerLabel.isHidden = false
            timerLabel.fontSize = h * 0.29
            timerLabel.fontColor = Theme.textGold
            timerLabel.position = CGPoint(x: hudRect.midX, y: row2Y)
            if let text = timerLabel.text, text.isEmpty {
                timerLabel.text = "00:00"
            }
        } else {
            subtitleLabel.isHidden = false
            timerLabel.isHidden = true
        }

        // 限时关的倒计时进度条，紧贴 HUD 下沿，随剩余时间变短。
        let barW = hudRect.width * 0.42
        let barH = h * 0.10
        timeBarBG.size = CGSize(width: barW, height: barH)
        timeBarBG.position = CGPoint(x: hudRect.midX, y: hudRect.minY - barH)
        timeBarBG.zPosition = 1
        timeBarBG.isHidden = !timed
        timeBarFill.size = CGSize(width: barW, height: barH)
        timeBarFill.position = CGPoint(x: hudRect.midX - barW / 2, y: hudRect.minY - barH)
        timeBarFill.zPosition = 2
        timeBarFill.isHidden = !timed

        // 提示横幅：位于 HUD 之下，按需弹出。
        let pw = hudRect.width * 0.88
        let ph = h * 1.6
        hintWidth = pw
        hintPanel.texture = TableSurfaces.control(size: CGSize(width: pw, height: ph),
                                                 top: Theme.panelRaised,
                                                 bottom: Theme.backgroundBottom,
                                                 border: Theme.brass,
                                                 cut: ph * 0.11)
        hintPanel.size = CGSize(width: pw, height: ph)
        hintPanel.position = CGPoint(x: hudRect.midX, y: hudRect.minY - ph * 0.5 - 8)
        hintPanel.zPosition = 20
        hintLabel.preferredMaxLayoutWidth = pw * 0.88
        hintLabel.fontSize = h * 0.26
        hintLabel.fontColor = Theme.textLight
        hintLabel.position = .zero
    }

    func refresh(timeRemaining: TimeInterval?, timed: Bool) {
        guard timed, let remaining = timeRemaining else { return }
        timerLabel.text = Format.clock(remaining)
        timerLabel.fontColor = remaining < 10 ? Theme.danger : Theme.textGold

        // 进度条随剩余时间收缩，末段变红提示紧张感。
        let fraction = timeLimit > 0 ? max(0, min(1, remaining / timeLimit)) : 0
        let fullW = timeBarBG.size.width
        timeBarFill.size = CGSize(width: fullW * CGFloat(fraction), height: timeBarBG.size.height)
        timeBarFill.color = fraction < 0.25 ? Theme.danger : Theme.textGold
    }

    /// 时间挑战模式：标题切换、副标题让位、左下角改显「已过 N 关」计数。
    func configureBlitz(cleared: Int = 0) {
        titleLabel.text = "One-minute"
        subtitleLabel.isHidden = true
        timerLabel.isHidden = false
        moveLabel.fontColor = Theme.textLight
        moveLabel.text = String(format: "OPENED  %02d", cleared)
    }

    /// 时间挑战每帧刷新：复用限时关的倒计时 + 进度条，另刷新已过关数。
    func refreshBlitz(timeRemaining: TimeInterval?, cleared: Int) {
        refresh(timeRemaining: timeRemaining, timed: true)
        moveLabel.text = String(format: "OPENED  %02d", cleared)
    }

    /// 是否显示撤销按钮（仅支持撤销的规则范型）。
    func setUndoVisible(_ visible: Bool) {
        undoButton.isHidden = !visible
    }

    /// 根据能否撤销刷新按钮可用态。
    func refreshUndo(canUndo: Bool) {
        undoButton.setEnabled(canUndo)
    }

    /// 刷新步数显示。
    func refreshMoves(_ moves: Int) {
        moveLabel.text = String(format: "MOVES  %02d", moves)
    }

    /// 刷新提示按钮上剩余的提示次数；耗尽则禁用按钮。
    func refreshHints(remaining: Int) {
        hintButton.setTitle(remaining > 0 ? "CLUE  \(remaining)" : "CLUE")
        hintButton.setEnabled(remaining > 0)
    }

    func showHint(_ text: String) {
        hintLabel.text = text
        hintLabel.isHidden = false
        hintLabel.alpha = 1
        hintPanel.isHidden = false
        hintPanel.removeAllActions()
        hintPanel.setScale(0.9)
        hintPanel.alpha = 0
        hintPanel.run(.group([
            .fadeIn(withDuration: Timing.overlayIn),
            .scale(to: 1.0, duration: Timing.overlayIn)
        ]))
    }

    func dismissHint() {
        hintPanel.run(.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.hintPanel.isHidden = true
        }
    }

    func target(at p: CGPoint) -> TapTarget? {
        if backButton.isEnabled && backButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onBack?() },
                             onPress: { [weak self] in self?.backButton.press() },
                             onRelease: { [weak self] in self?.backButton.release() })
        }
        if hintButton.isEnabled && hintButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onHint?() },
                             onPress: { [weak self] in self?.hintButton.press() },
                             onRelease: { [weak self] in self?.hintButton.release() })
        }
        if undoButton.isEnabled && undoButton.hitFrame.contains(p) {
            return TapTarget(action: { [weak self] in self?.onUndo?() },
                             onPress: { [weak self] in self?.undoButton.press() },
                             onRelease: { [weak self] in self?.undoButton.release() })
        }
        return nil
    }
}
