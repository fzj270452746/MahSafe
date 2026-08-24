//
//  GameScene.swift
//  MahSafe
//
//  SpriteKit 舞台：装配牌桌，并把触摸交给当前桌面。
//

import SpriteKit
import UIKit
import QuartzCore

final class GameScene: SKScene {

    // MARK: - 会话与输入

    private let session = TableFlow()
    private let input = InputController()

    // MARK: - 背景

    private var backgroundLayer = SKNode()

    // MARK: - 对局节点

    private var safe: SafeNode?
    private var hud: HUDNode?
    private var rack: TileRack?
    private var confirmButton: ButtonNode?
    private var instructionPanel: SKSpriteNode?
    private var instructionLabel: SKLabelNode?
    private var tileNodes: [[MahjongTile]] = []
    private var tileSceneCenters: [[CGPoint]] = []
    private var tileSize: CGSize = .zero
    private var gap: CGFloat = 0
    private var placeSelectedPos: GridPos?
    private var isAnalyzing = false

    // MARK: - 屏幕节点

    private var mainMenu: MainMenuNode?
    private var levelSelect: LevelSelectNode?
    private var dailyNode: DailyNode?
    private var blitzNode: BlitzNode?
    private var resultNode: ResultNode?
    private var blitzResultNode: BlitzResultNode?
    private var rulesReference: RulesReferenceNode?
    private var settingsNode: SettingsNode?
    private var statsNode: StatisticsNode?
    private var chapterIntro: ChapterIntroNode?
    private var onboarding: OnboardingNode?
    private var ruleBanner: RuleBannerNode?
    private var confirmDialog: ConfirmDialogNode?

    // MARK: - 交互与计时

    private var pressedAction: TapTarget?
    private var lastUpdateTime: TimeInterval = 0
    private var lastLayoutSize: CGSize = .zero
    private var lastSafeAreaInsets: UIEdgeInsets = .zero

    // MARK: - 生命周期

    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = .zero
        backgroundColor = Theme.backgroundBottom
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) 不支持")
    }

    override func didMove(to view: SKView) {
        MahjongRenderer.warmCache()
        buildBackground()

        input.onGesture = { [weak self] gesture in
            self?.handleGesture(gesture)
        }
        session.onChange = { [weak self] screen in
            self?.apply(screen)
        }

        lastLayoutSize = size
        lastSafeAreaInsets = safeAreaInsets
        session.showMenu()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size != lastLayoutSize, size.width > 1, size.height > 1 else { return }
        lastLayoutSize = size
        lastSafeAreaInsets = safeAreaInsets
        buildBackground()
        apply(session.screen)
    }

    func safeAreaInsetsDidChange() {
        let insets = safeAreaInsets
        guard insets != lastSafeAreaInsets, size.width > 1, size.height > 1 else { return }
        lastSafeAreaInsets = insets
        apply(session.screen)
    }

    private var safeAreaInsets: UIEdgeInsets {
        view?.safeAreaInsets ?? .zero
    }

    private var metrics: LayoutMetrics {
        LayoutMetrics(sceneSize: size, safeArea: safeAreaInsets)
    }

    // MARK: - 屏幕切换

    private func apply(_ screen: TableView) {
        switch screen {
        case .menu:
            teardownPlay()
            teardownOverlay()
            buildMainMenu()
        case .select:
            teardownPlay()
            teardownOverlay()
            buildLevelSelect()
        case .daily:
            teardownPlay()
            teardownOverlay()
            buildDaily()
        case .blitz:
            teardownPlay()
            teardownOverlay()
            buildBlitz()
        case .play:
            teardownPlay()
            teardownOverlay()
            buildPlay()
        case .result:
            // 保留打开中的保险箱，结算面板叠加其上。
            teardownOverlay()
            buildResult()
        case .blitzResult:
            // 保留打开中的保险箱，结算面板叠加其上（对齐 .result）。
            teardownOverlay()
            buildBlitzResult()
        case .rules:
            teardownPlay()
            teardownOverlay()
            buildRules()
        case .settings:
            teardownPlay()
            teardownOverlay()
            buildSettings()
        case .stats:
            teardownPlay()
            teardownOverlay()
            buildStats()
        }
    }

    private func teardownPlay() {
        safe?.removeFromParent()
        hud?.removeFromParent()
        rack?.removeFromParent()
        confirmButton?.removeFromParent()
        instructionPanel?.removeFromParent()
        ruleBanner?.removeFromParent()
        confirmDialog?.removeFromParent()
        safe = nil
        hud = nil
        rack = nil
        confirmButton = nil
        instructionPanel = nil
        instructionLabel = nil
        ruleBanner = nil
        confirmDialog = nil
        tileNodes = []
        tileSceneCenters = []
        placeSelectedPos = nil
    }

    private func teardownOverlay() {
        mainMenu?.removeFromParent()
        levelSelect?.removeFromParent()
        dailyNode?.removeFromParent()
        blitzNode?.removeFromParent()
        resultNode?.removeFromParent()
        blitzResultNode?.removeFromParent()
        rulesReference?.removeFromParent()
        settingsNode?.removeFromParent()
        statsNode?.removeFromParent()
        chapterIntro?.removeFromParent()
        onboarding?.removeFromParent()
        mainMenu = nil
        levelSelect = nil
        dailyNode = nil
        blitzNode = nil
        resultNode = nil
        blitzResultNode = nil
        rulesReference = nil
        settingsNode = nil
        statsNode = nil
        chapterIntro = nil
        onboarding = nil
    }

    // MARK: - 背景

    private func buildBackground() {
        backgroundLayer.removeFromParent()
        backgroundLayer = SKNode()

        let tex = TableSurfaces.vaultBackground(size: size)
        let bg = SKSpriteNode(texture: tex, size: size)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -20
        backgroundLayer.addChild(bg)

        let glow = SKSpriteNode(texture: MahjongRenderer.glowTexture(color: Theme.innerLight))
        glow.size = CGSize(width: size.width * 1.7, height: size.width * 1.7)
        glow.position = CGPoint(x: size.width / 2, y: size.height * 0.5)
        glow.alpha = 0.14
        glow.blendMode = .add
        glow.zPosition = -19
        backgroundLayer.addChild(glow)

        // 两侧黄铜导轨把全屏变成一座纵向保险库，而不是普通渐变背景。
        let railPath = CGMutablePath()
        let railInset = size.width * 0.035
        let innerInset = size.width * 0.055
        for x in [railInset, size.width - railInset] {
            railPath.move(to: CGPoint(x: x, y: size.height * 0.08))
            railPath.addLine(to: CGPoint(x: x, y: size.height * 0.92))
        }
        for x in [innerInset, size.width - innerInset] {
            railPath.move(to: CGPoint(x: x, y: size.height * 0.12))
            railPath.addLine(to: CGPoint(x: x, y: size.height * 0.88))
        }
        let rails = SKShapeNode(path: railPath)
        rails.strokeColor = Theme.brassDark.withAlphaComponent(0.38)
        rails.lineWidth = 1
        rails.zPosition = -18
        backgroundLayer.addChild(rails)

        let topSeal = SKShapeNode(circleOfRadius: size.width * 0.11)
        topSeal.position = CGPoint(x: size.width / 2, y: size.height * 0.94)
        topSeal.fillColor = .clear
        topSeal.strokeColor = Theme.brass.withAlphaComponent(0.13)
        topSeal.lineWidth = 1
        topSeal.zPosition = -18
        backgroundLayer.addChild(topSeal)

        // 漂浮的暖光尘埃，营造「暗金」氛围，贯穿所有界面。
        ParticleField.ambientDust(in: CGRect(origin: .zero, size: size),
                                  parent: backgroundLayer,
                                  count: 16)

        addChild(backgroundLayer)
    }

    // MARK: - 主菜单

    private func buildMainMenu() {
        let menu = MainMenuNode()
        menu.layout(in: size, safeArea: safeAreaInsets)
        menu.zPosition = 1
        menu.onPlay = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showSelect()
        }
        menu.onDaily = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showDaily()
        }
        menu.onBlitz = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showBlitz()
        }
        menu.onRules = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showRules()
        }
        menu.onSettings = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showSettings()
        }
        menu.onSoundToggle = { [weak self] in
            SaveManager.soundEnabled.toggle()
            AudioManager.shared.play(.click)
            self?.mainMenu?.refreshToggles()
        }
        menu.onHapticToggle = { [weak self] in
            SaveManager.hapticEnabled.toggle()
            self?.mainMenu?.refreshToggles()
        }
        menu.onReset = { [weak self] in
            self?.confirmReset()
        }
        addChild(menu)
        mainMenu = menu

        // 首次启动播放教学；之后不再弹出，可随时在「玩法说明」回看。
        if !SaveManager.hasSeenOnboarding {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let node = OnboardingNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 500
        node.onBegin = { [weak self] in
            AudioManager.shared.play(.click)
            SaveManager.markOnboardingSeen()
            self?.onboarding?.removeFromParent()
            self?.onboarding = nil
        }
        addChild(node)
        onboarding = node
    }

    // MARK: - 选关

    private func buildLevelSelect() {
        let select = LevelSelectNode()
        select.layout(in: size, safeArea: safeAreaInsets)
        select.zPosition = 1
        select.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showMenu()
        }
        select.onSelect = { [weak self] level in
            AudioManager.shared.play(.click)
            self?.session.start(level: level)
        }
        addChild(select)
        levelSelect = select
    }

    // MARK: - 每日保险箱

    private func buildDaily() {
        let node = DailyNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 1
        node.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showMenu()
        }
        node.onPlay = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.startDaily()
        }
        addChild(node)
        dailyNode = node
    }

    // MARK: - 时间挑战

    private func buildBlitz() {
        let node = BlitzNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 1
        node.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showMenu()
        }
        node.onPlay = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.startBlitz()
        }
        addChild(node)
        blitzNode = node
    }

    private func buildBlitzResult() {
        guard let outcome = session.lastBlitzOutcome else { return }
        let node = BlitzResultNode()
        node.layout(in: size, safeArea: safeAreaInsets, outcome: outcome)
        node.zPosition = 100
        node.onRetry = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.startBlitz()
        }
        node.onMenu = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showBlitz()
        }
        addChild(node)
        blitzResultNode = node
        node.playAnimation()
    }

    // MARK: - 对局

    private func buildPlay() {
        guard let game = session.game else { return }
        let m = metrics

        let safeNode = SafeNode()
        safeNode.layout(in: m.safeBodyRect)
        safeNode.zPosition = 0
        addChild(safeNode)
        safe = safeNode

        let hudNode = HUDNode()
        if session.isBlitzPlay {
            hudNode.layout(in: m.hudRect,
                           title: "One-minute",
                           subtitle: "",
                           timed: true,
                           timeLimit: BlitzRun.startTime)
            hudNode.configureBlitz()
        } else {
            hudNode.layout(in: m.hudRect,
                           title: game.level.title,
                           subtitle: game.rule.shortTitle,
                           timed: game.isTimed,
                           timeLimit: game.puzzle.timeLimit)
        }
        hudNode.zPosition = 10
        hudNode.onBack = { [weak self] in
            self?.backTapped()
        }
        hudNode.onHint = { [weak self] in
            self?.hintTapped()
        }
        hudNode.onUndo = { [weak self] in
            self?.undoTapped()
        }
        hudNode.setUndoVisible(game.supportsUndo)
        hudNode.refreshUndo(canUndo: false)
        hudNode.refreshHints(remaining: game.puzzle.hints.count - game.hintsUsed)
        if !session.isBlitzPlay {
            hudNode.refreshMoves(game.moves)
        }
        addChild(hudNode)
        hud = hudNode

        buildBoardContents(for: game, showBanner: true)
    }

    /// 建立牌面 + 指令 + 牌库/确认钮 + 规则横幅。blitz 换关时只重建这部分，保险箱与 HUD 复用。
    private func buildBoardContents(for game: GameState, showBanner: Bool) {
        guard let safeNode = safe else { return }
        let m = metrics

        clearBoardContents()
        buildTiles(in: safeNode, board: game.board)
        buildInstructionLabel(in: m.controlsRect, game: game)

        if game.family == .place, let rackTiles = game.puzzle.rack {
            buildRack(in: m.controlsRect, tiles: rackTiles)
        } else if game.family == .rearrange || game.family == .rotateTo {
            buildConfirmButton(in: m.controlsRect)
        }

        guard showBanner else { return }

        // 首次踏入某个章节时播放开场过场；每日 / 时间挑战不播放。
        var showsChapterIntro = false
        if !session.isDailyPlay && !session.isBlitzPlay {
            let chapter = LevelRepository.chapter(of: game.level.number)
            if !SaveManager.isChapterIntroduced(chapter.number) {
                SaveManager.markChapterIntroduced(chapter.number)
                showChapterIntro(chapter, mode: .intro, then: nil)
                showsChapterIntro = true
            }
        }
        // 没有章节过场时，用规则横幅提示本关玩法。
        if !showsChapterIntro {
            showRuleBanner(game.rule)
        }
    }

    /// 清空牌面与牌库，不触碰保险箱、HUD、规则横幅与确认弹窗。
    private func clearBoardContents() {
        instructionPanel?.removeFromParent()
        rack?.removeFromParent()
        confirmButton?.removeFromParent()
        instructionPanel = nil
        instructionLabel = nil
        rack = nil
        confirmButton = nil
        for row in tileNodes {
            for tile in row { tile.removeFromParent() }
        }
        tileNodes = []
        tileSceneCenters = []
        placeSelectedPos = nil
    }

    private func showRuleBanner(_ rule: RuleKind) {
        let node = RuleBannerNode()
        node.layout(in: size, safeArea: safeAreaInsets, rule: rule)
        node.zPosition = 60
        node.onDone = { [weak self] in
            self?.ruleBanner?.removeFromParent()
            self?.ruleBanner = nil
        }
        addChild(node)
        ruleBanner = node
        node.play()
    }

    /// 章节过场浮层。`then` 在淡出结束后执行（如用于延迟进入结算）。
    private func showChapterIntro(_ chapter: ChapterInfo, mode: ChapterIntroNode.Mode, then: (() -> Void)?) {
        let node = ChapterIntroNode()
        node.show(in: size, chapter: chapter, mode: mode)
        node.zPosition = 500
        node.onDone = { [weak self] in
            self?.chapterIntro?.removeFromParent()
            self?.chapterIntro = nil
            then?()
        }
        addChild(node)
        chapterIntro = node
        node.play()
    }

    private func buildTiles(in safeNode: SafeNode, board: PuzzleState) {
        let geo = metrics.tileGeometry(rows: board.rows, cols: board.cols, in: safeNode.boardRect)
        tileSize = geo.tileSize
        gap = geo.gap

        let cols = board.cols
        let rows = board.rows
        let gridW = CGFloat(cols) * tileSize.width + CGFloat(cols - 1) * gap
        let gridH = CGFloat(rows) * tileSize.height + CGFloat(rows - 1) * gap
        let originX = safeNode.boardRect.midX - gridW / 2
        let originY = safeNode.boardRect.midY - gridH / 2

        tileNodes = []
        tileSceneCenters = []
        for r in 0..<rows {
            var nodeRow: [MahjongTile] = []
            var centerRow: [CGPoint] = []
            for c in 0..<cols {
                let pos = GridPos(row: r, col: c)
                let tile = MahjongTile(state: board.tile(at: pos))
                tile.size = tileSize
                tile.layoutSubvisuals()

                let sceneX = originX + (CGFloat(c) + 0.5) * tileSize.width + CGFloat(c) * gap
                let sceneY = originY + (CGFloat(rows - 1 - r) + 0.5) * tileSize.height + CGFloat(rows - 1 - r) * gap
                let boardLocal = CGPoint(x: sceneX - safeNode.innerRect.midX,
                                         y: sceneY - safeNode.innerRect.midY)
                tile.position = boardLocal
                tile.zPosition = 1
                safeNode.board.addChild(tile)
                nodeRow.append(tile)
                centerRow.append(CGPoint(x: sceneX, y: sceneY))
            }
            tileNodes.append(nodeRow)
            tileSceneCenters.append(centerRow)
        }
    }

    private func buildInstructionLabel(in controlsRect: CGRect, game: GameState) {
        let panelSize = CGSize(width: controlsRect.width * 0.90,
                               height: controlsRect.height * 0.42)
        let panel = SKSpriteNode(texture: TableSurfaces.control(size: panelSize,
                                                               top: Theme.metalMid,
                                                               bottom: Theme.backgroundBottom,
                                                               border: Theme.brass,
                                                               cut: panelSize.height * 0.14),
                                 size: panelSize)
        panel.position = CGPoint(x: controlsRect.midX,
                                 y: controlsRect.maxY - controlsRect.height * 0.24)
        panel.zPosition = 20

        let accent = SKSpriteNode(color: Theme.brass, size: CGSize(width: 3, height: panelSize.height * 0.58))
        accent.position = CGPoint(x: -panelSize.width * 0.43, y: 0)
        accent.zPosition = 1
        panel.addChild(accent)

        let tag = SKLabelNode(fontNamed: Theme.headingFont)
        tag.text = "HOUSE NOTE"
        tag.fontSize = min(max(panelSize.height * 0.13, 10), 13)
        tag.fontColor = Theme.brassShine
        tag.horizontalAlignmentMode = .left
        tag.verticalAlignmentMode = .center
        tag.position = CGPoint(x: -panelSize.width * 0.39, y: panelSize.height * 0.25)
        tag.zPosition = 2
        panel.addChild(tag)

        let label = SKLabelNode(fontNamed: Theme.bodyFont)
        label.text = instruction(for: game)
        label.fontSize = min(max(panelSize.height * 0.22, 16), 20)
        label.fontColor = Theme.tileIvoryLight
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.preferredMaxLayoutWidth = panelSize.width * 0.78
        label.position = CGPoint(x: -panelSize.width * 0.39, y: -panelSize.height * 0.13)
        label.zPosition = 2
        panel.addChild(label)
        addChild(panel)
        instructionPanel = panel
        instructionLabel = label
    }

    private func instruction(for game: GameState) -> String {
        switch game.rule {
        case .dailyCipher:
            let found = min(game.board.tapped.count, game.puzzle.rows)
            return "Found: \(found)/\(game.puzzle.rows) · choose any row\nTap the number that breaks ±1."
        case .countOrder:
            return "Tap one tile per group,\nmost frequent first."
        case .uniquePair:
            return "Find the only matching pair.\nTap both tiles."
        case .uniqueSingle:
            return "Find the only tile that appears once."
        case .decoy:
            return "Find the tile that breaks the pattern."
        case .sequence:
            return "Follow the winding path\nand tap tiles in order."
        default:
            break
        }

        switch game.family {
        case .tapOrder: return "Tap tiles in the hidden order."
        case .rearrange: return "Swap two tiles, then pull the lever."
        case .rotateTo: return "Swipe to align tiles, then pull the lever."
        case .reveal: return "Hold a tile to inspect its back.\nFind the false mark."
        case .place: return "Select the empty socket.\nThen choose a tile below."
        case .multi: return multiInstruction(for: game)
        }
    }

    /// 组合规则按当前步展示具体提示，让玩家知道现在要做什么。
    private func multiInstruction(for game: GameState) -> String {
        guard case .multi(let steps) = game.puzzle.solution, !steps.isEmpty else {
            return "Follow each instruction in order."
        }
        let idx = min(game.board.stepCursor, steps.count - 1)
        return "Protocol \(idx + 1)/\(steps.count)  ·  \(steps[idx].hint)"
    }

    /// 组合规则推进一步后刷新指令文本。
    private func refreshInstruction() {
        guard let game = session.game else { return }
        instructionLabel?.removeAction(forKey: "dailyMistake")
        instructionLabel?.text = instruction(for: game)
    }

    private func buildRack(in controlsRect: CGRect, tiles: [MahjongType]) {
        let rackNode = TileRack()
        let rackRect = CGRect(x: controlsRect.minX + controlsRect.width * 0.04,
                              y: controlsRect.midY - controlsRect.height * 0.22,
                              width: controlsRect.width * 0.92,
                              height: controlsRect.height * 0.44)
        rackNode.layout(in: rackRect, rack: tiles)
        rackNode.zPosition = 10
        rackNode.onPick = { [weak self] type in
            self?.rackTapped(type)
        }
        addChild(rackNode)
        rack = rackNode
    }

    private func buildConfirmButton(in controlsRect: CGRect) {
        let button = ButtonNode(title: "Try the handle",
                                size: CGSize(width: controlsRect.width * 0.42,
                                             height: controlsRect.height * 0.30),
                                style: .primary)
        button.layout(at: CGPoint(x: controlsRect.midX, y: controlsRect.midY - controlsRect.height * 0.12))
        button.zPosition = 10
        addChild(button)
        confirmButton = button
    }

    // MARK: - 结算

    private func buildResult() {
        guard let result = session.lastResult else { return }
        let node = ResultNode()
        let hasNext = result.won && !result.isDaily
                        && result.level < LevelRepository.totalLevels
                        && SaveManager.isUnlocked(result.level + 1)
        node.layout(in: size, safeArea: safeAreaInsets, result: result, hasNext: hasNext)
        node.zPosition = 100
        node.onRetry = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.retry()
        }
        node.onNext = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.nextLevel()
        }
        node.onMenu = { [weak self] in
            AudioManager.shared.play(.click)
            if result.isDaily {
                self?.session.showDaily()
            } else {
                self?.session.showSelect()
            }
        }
        addChild(node)
        resultNode = node
        node.playAnimation()
    }

    // MARK: - 玩法说明 / 设置 / 统计

    private func buildRules() {
        let node = RulesReferenceNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 1
        node.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showMenu()
        }
        addChild(node)
        rulesReference = node
    }

    private func buildSettings() {
        let node = SettingsNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 1
        node.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.settingsNode?.cancelArmedReset()
            self?.session.showMenu()
        }
        node.onSoundToggle = { [weak self] in
            SaveManager.soundEnabled.toggle()
            AudioManager.shared.play(.click)
            self?.settingsNode?.refreshToggles()
        }
        node.onHapticToggle = { [weak self] in
            SaveManager.hapticEnabled.toggle()
            self?.settingsNode?.refreshToggles()
        }
        node.onMusicToggle = { [weak self] in
            SaveManager.musicEnabled.toggle()
            if SaveManager.musicEnabled {
                AudioManager.shared.startMusic()
            } else {
                AudioManager.shared.stopMusic()
            }
            self?.settingsNode?.refreshToggles()
        }
        node.onStatistics = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showStats()
        }
        node.onReset = { [weak self] in
            self?.confirmReset()
        }
        addChild(node)
        settingsNode = node
    }

    private func buildStats() {
        let node = StatisticsNode()
        node.layout(in: size, safeArea: safeAreaInsets)
        node.zPosition = 1
        node.onBack = { [weak self] in
            AudioManager.shared.play(.click)
            self?.session.showSettings()
        }
        addChild(node)
        statsNode = node
    }

    private func confirmReset() {
        SaveManager.resetAll()
        StatisticsManager.reset()
        DailyManager.reset()
        BlitzManager.reset()
        settingsNode?.refreshToggles()
        AudioManager.shared.play(.bolt)
    }

    // MARK: - 触摸路由

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        pressedAction = nil

        // 章节过场期间屏蔽一切输入，等淡出后再恢复。
        if chapterIntro != nil {
            return
        }

        if session.screen != .play {
            if let target = screenTarget(at: point) {
                pressedAction = target
                target.onPress?()
            }
            return
        }

        if let target = playUITarget(at: point) {
            pressedAction = target
            target.onPress?()
            return
        }

        // 确认弹窗出现时屏蔽棋盘手势，只响应弹窗按钮。
        if confirmDialog != nil {
            return
        }

        input.began(at: point, grid: grid(at: point), time: CACurrentMediaTime())
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        input.moved(to: point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }

        if let target = pressedAction {
            pressedAction = nil
            target.onRelease?()
            target.action()
            return
        }
        input.ended()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        pressedAction = nil
        input.cancelled()
    }

    // MARK: - 命中判定

    private func screenTarget(at point: CGPoint) -> TapTarget? {
        switch session.screen {
        case .menu:
            if let onboarding, let target = onboarding.target(at: point) { return target }
            return mainMenu?.target(at: point)
        case .select: return levelSelect?.target(at: point)
        case .daily: return dailyNode?.target(at: point)
        case .blitz: return blitzNode?.target(at: point)
        case .result: return resultNode?.target(at: point)
        case .blitzResult: return blitzResultNode?.target(at: point)
        case .rules: return rulesReference?.target(at: point)
        case .settings: return settingsNode?.target(at: point)
        case .stats: return statsNode?.target(at: point)
        case .play: return nil
        }
    }

    private func playUITarget(at point: CGPoint) -> TapTarget? {
        if let confirmDialog, let target = confirmDialog.target(at: point) { return target }
        if let hud, let target = hud.target(at: point) { return target }
        if let rack, let target = rack.target(at: point) { return target }
        if let confirmButton, confirmButton.isEnabled, confirmButton.hitFrame.contains(point) {
            return TapTarget(action: { [weak self] in self?.confirmTapped() },
                             onPress: { [weak self] in self?.confirmButton?.press() },
                             onRelease: { [weak self] in self?.confirmButton?.release() })
        }
        if let safe, safe.handleHitRect.contains(point), needsConfirm {
            return TapTarget(action: { [weak self] in self?.confirmTapped() },
                             onPress: nil, onRelease: nil)
        }
        return nil
    }

    private var needsConfirm: Bool {
        guard let game = session.game else { return false }
        return game.family == .rearrange || game.family == .rotateTo
    }

    private func grid(at point: CGPoint) -> GridPos? {
        guard !tileSceneCenters.isEmpty else { return nil }
        let half = tileSize.width / 2 + gap / 2
        for r in 0..<tileSceneCenters.count {
            for c in 0..<tileSceneCenters[r].count {
                let center = tileSceneCenters[r][c]
                if abs(point.x - center.x) <= half && abs(point.y - center.y) <= half {
                    return GridPos(row: r, col: c)
                }
            }
        }
        return nil
    }

    // MARK: - 手势 → 动作

    private func handleGesture(_ gesture: TileGesture) {
        guard let game = session.game, game.isComplete == false else { return }
        switch gesture {
        case .tap(let pos):
            tileTapped(pos)
        case .rotate(let pos, let steps):
            if game.family == .rotateTo || game.family == .multi {
                tileRotated(pos, steps: steps)
            }
        case .peekStart(let pos):
            if game.family == .reveal { peek(pos, flipped: true) }
        case .peekEnd(let pos):
            if game.family == .reveal { peek(pos, flipped: false) }
        }
    }

    private func tileTapped(_ pos: GridPos) {
        guard let game = session.game else { return }

        if game.family == .rearrange {
            let first = game.board.selected
            let firstNode = first.flatMap { node(at: $0) }
            AudioManager.shared.play(.tap)
            Haptics.tap()
            let outcome = game.apply(.tap(pos))
            if outcome == .swapped, let first {
                animateSwap(first, pos)
                firstNode?.setSelected(false)
            } else if case .selected = outcome {
                node(at: pos)?.setSelected(true)
            } else if case .nothing = outcome, game.board.selected == nil {
                firstNode?.setSelected(false)
            }
            refreshHUD()
            return
        }

        if game.family == .place {
            AudioManager.shared.play(.tap)
            Haptics.tap()
            let outcome = game.apply(.tap(pos))
            if case .selected = outcome {
                placeSelectedPos = pos
                node(at: pos)?.setSelected(true)
            } else {
                placeSelectedPos = nil
            }
            refreshHUD()
            return
        }

        AudioManager.shared.play(.tap)
        Haptics.tap()
        let outcome = game.apply(.tap(pos))
        handleOutcome(outcome, affected: pos)
    }

    private func tileRotated(_ pos: GridPos, steps: Int) {
        guard let game = session.game else { return }
        AudioManager.shared.play(.rotate)
        Haptics.rotate()
        let outcome = game.apply(.rotate(pos, steps: steps))
        syncAllTiles(animate: true)
        handleOutcome(outcome, affected: pos)
    }

    private func peek(_ pos: GridPos, flipped: Bool) {
        guard let game = session.game else { return }
        let state = game.board.tile(at: pos)
        if state.isFlipped != flipped {
            game.board.flip(pos)
            node(at: pos)?.apply(game.board.tile(at: pos), animate: true)
            Haptics.flip()
        }
    }

    private func rackTapped(_ type: MahjongType) {
        guard let game = session.game, let pos = placeSelectedPos else { return }
        AudioManager.shared.play(.tap)
        Haptics.tap()
        let outcome = game.apply(.place(pos, type))
        if case .progress = outcome {
            node(at: pos)?.apply(game.board.tile(at: pos), animate: true)
            node(at: pos)?.setSelected(false)
            placeSelectedPos = nil
        }
        handleOutcome(outcome, affected: pos)
    }

    private func confirmTapped() {
        guard !isAnalyzing, session.game != nil else { return }
        AudioManager.shared.play(.click)
        isAnalyzing = true
        // 拉把手后先「核对」半秒，锁盘转动，再揭晓对错。
        safe?.analyze { [weak self] in
            guard let self, let game = self.session.game else {
                self?.isAnalyzing = false
                return
            }
            self.isAnalyzing = false
            Haptics.correct()
            let outcome = game.apply(.confirm)
            self.handleOutcome(outcome, affected: nil)
        }
    }

    /// 对局中点击返回：有进度时先确认，避免误触丢失。
    private func backTapped() {
        guard let game = session.game else { return }
        AudioManager.shared.play(.click)
        if game.moves > 0 && !game.isComplete {
            showLeaveDialog()
        } else {
            leavePlay()
        }
    }

    /// 退出对局：时间挑战回时间挑战页，每日保险箱回每日页，普通关回选关。
    private func leavePlay() {
        if session.isBlitzPlay {
            session.showBlitz()
        } else if session.isDailyPlay {
            session.showDaily()
        } else {
            session.showSelect()
        }
    }

    private func showLeaveDialog() {
        guard confirmDialog == nil else { return }
        let node = ConfirmDialogNode()
        node.present(in: size, message: "Leave this table? The hand will be lost.", confirmTitle: "Leave table")
        node.zPosition = 400
        node.onCancel = { [weak self] in
            AudioManager.shared.play(.click)
            self?.confirmDialog?.removeFromParent()
            self?.confirmDialog = nil
        }
        node.onConfirm = { [weak self] in
            AudioManager.shared.play(.click)
            self?.confirmDialog?.removeFromParent()
            self?.confirmDialog = nil
            self?.leavePlay()
        }
        addChild(node)
        confirmDialog = node
    }

    private func hintTapped() {
        guard let game = session.game else { return }
        AudioManager.shared.play(.click)
        if let text = game.showNextHint() {
            hud?.showHint(text)
            if game.hintsUsed >= 2 {
                for pos in game.puzzle.hintGlowTargets {
                    node(at: pos)?.showHintGlow(true)
                }
            }
            refreshHUD()
        }
    }

    private func undoTapped() {
        guard let game = session.game else { return }
        guard game.undo() else { return }
        AudioManager.shared.play(.swap)
        Haptics.tap()
        placeSelectedPos = nil
        syncAllTiles(animate: true)
        refreshHUD()
    }

    /// 每次动作后刷新 HUD 上的步数、剩余提示、撤销可用态与组合规则指令。
    private func refreshHUD() {
        guard let game = session.game else { return }
        // 时间挑战左下角是「已过 N 关」计数，不由步数覆盖。
        if !session.isBlitzPlay {
            hud?.refreshMoves(game.moves)
        }
        hud?.refreshHints(remaining: game.puzzle.hints.count - game.hintsUsed)
        hud?.refreshUndo(canUndo: game.canUndo)
        refreshInstruction()
    }

    // MARK: - 结果处理

    private func handleOutcome(_ outcome: ActionOutcome, affected pos: GridPos?) {
        var showsDailyMistake = false
        switch outcome {
        case .nothing:
            break
        case .selected:
            break
        case .swapped:
            break
        case .progress(let progressPos):
            let target = progressPos ?? pos
            if let target {
                node(at: target)?.pulse()
                if session.game?.rule == .dailyCipher {
                    node(at: target)?.showSolved()
                }
            }
        case .completed:
            if let pos, session.game?.rule == .dailyCipher {
                node(at: pos)?.showSolved()
            }
            completeLevel()
        case .wrong(let wrongPos):
            wrongFeedback(wrongPos ?? pos)
            showsDailyMistake = session.game?.rule == .dailyCipher
        }
        refreshHUD()
        if showsDailyMistake {
            showDailyMistakeInstruction()
        }
    }

    private func showDailyMistakeInstruction() {
        guard let label = instructionLabel else { return }
        label.text = "That number still behaves.\nFind the one tile cheating the count."
        label.run(.sequence([
            .wait(forDuration: 1.6),
            .run { [weak self] in self?.refreshInstruction() }
        ]), withKey: "dailyMistake")
    }

    private func wrongFeedback(_ pos: GridPos?) {
        AudioManager.shared.play(.wrong)
        Haptics.wrong()
        if let pos {
            node(at: pos)?.flashRed()
            node(at: pos)?.shake()
        }
        safe?.shake()
    }

    private func completeLevel() {
        guard let game = session.game, game.isComplete else { return }
        // 时间挑战：过关不进入战役结算，而是加时换关，直到倒计时归零。
        if session.isBlitzPlay {
            completeBlitzChallenge()
            return
        }
        AudioManager.shared.play(.victory)
        Haptics.success()
        let stars = game.starRating()
        let chapterEnd = game.level.number % 10 == 0
        safe?.unlock { [weak self] in
            guard let self else { return }
            // 开箱瞬间的金色碎屑，给胜利一个明确的视觉收尾。
            let center = self.safe?.calculateAccumulatedFrame().center
                ?? CGPoint(x: self.size.width / 2, y: self.size.height * 0.55)
            ParticleField.confettiBurst(at: center, parent: self, count: 60)

            if chapterEnd && !self.session.isDailyPlay {
                let chapter = LevelRepository.chapter(of: game.level.number)
                self.showChapterIntro(chapter, mode: .complete) { [weak self] in
                    self?.session.finish(won: true, stars: stars, time: game.elapsed, timedOut: false)
                }
            } else {
                self.session.finish(won: true, stars: stars, time: game.elapsed, timedOut: false)
            }
        }
    }

    private func failLevel() {
        guard let game = session.game, !game.isComplete else { return }
        AudioManager.shared.play(.wrong)
        Haptics.wrong()
        session.finish(won: false, stars: 0, time: game.elapsed, timedOut: true)
    }

    /// 时间挑战过一关：快速碎屑收尾，加时换新关，不触发战役结算。
    private func completeBlitzChallenge() {
        AudioManager.shared.play(.victory)
        Haptics.success()
        // 换关不做整段开门动画（太慢），用快速金色碎屑给一个即时反馈。
        let center = safe?.calculateAccumulatedFrame().center
            ?? CGPoint(x: size.width / 2, y: size.height * 0.55)
        ParticleField.confettiBurst(at: center, parent: self, count: 36)

        session.advanceBlitz()
        guard let game = session.game else { return }
        buildBoardContents(for: game, showBanner: true)
        let run = session.blitz
        hud?.refreshBlitz(timeRemaining: run?.timeRemaining, cleared: run?.cleared ?? 0)
    }

    // MARK: - 同步与动画

    private func node(at pos: GridPos) -> MahjongTile? {
        guard pos.row >= 0, pos.row < tileNodes.count,
              pos.col >= 0, pos.col < tileNodes[pos.row].count else { return nil }
        return tileNodes[pos.row][pos.col]
    }

    private func syncAllTiles(animate: Bool) {
        guard let game = session.game else { return }
        for r in 0..<tileNodes.count {
            for c in 0..<tileNodes[r].count {
                let pos = GridPos(row: r, col: c)
                tileNodes[r][c].apply(game.board.tile(at: pos), animate: animate)
            }
        }
    }

    private func animateSwap(_ a: GridPos, _ b: GridPos) {
        guard let nodeA = node(at: a), let nodeB = node(at: b) else { return }
        let posA = nodeA.position
        let posB = nodeB.position
        tileNodes[a.row][a.col] = nodeB
        tileNodes[b.row][b.col] = nodeA
        nodeA.run(.move(to: posB, duration: Timing.tileSwap))
        nodeB.run(.move(to: posA, duration: Timing.tileSwap))
    }

    // MARK: - 主循环

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        input.update(time: CACurrentMediaTime())

        guard session.screen == .play, let game = session.game else { return }
        guard !game.isComplete else { return }

        // 时间挑战：总倒计时由 BlitzRun 管理，归零即结算；不走战役的关卡计时与星级。
        if session.isBlitzPlay, let run = session.blitz {
            if run.tick(dt) {
                hud?.refreshBlitz(timeRemaining: 0, cleared: run.cleared)
                session.endBlitz()
            } else {
                hud?.refreshBlitz(timeRemaining: run.timeRemaining, cleared: run.cleared)
            }
            return
        }

        game.tick(dt)
        hud?.refresh(timeRemaining: game.timeRemaining, timed: game.isTimed)
        if game.didTimeOut {
            failLevel()
        }
    }
}
