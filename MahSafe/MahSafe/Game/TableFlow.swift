//
//  TableFlow.swift
//  MahSafe
//
//  一张牌桌从入座到结算的流程与当前牌局。
//

import Foundation

enum TableView {
    case menu
    case select
    case daily
    case blitz
    case play
    case result
    case blitzResult
    case rules
    case settings
    case stats
}

final class TableFlow {

    struct LevelResult {
        let level: Int
        let stars: Int
        let time: TimeInterval
        let won: Bool
        let timedOut: Bool
        let hintsUsed: Int
        let newAchievements: [Achievement]
        let isDaily: Bool
        let isNewBest: Bool
    }

    struct BlitzOutcome {
        let cleared: Int
        let isNewBest: Bool
    }

    private(set) var screen: TableView = .menu
    private(set) var game: GameState?
    private(set) var lastResult: LevelResult?
    private(set) var lastBlitzOutcome: BlitzOutcome?
    private var isDaily = false
    private var isBlitz = false
    private var blitzRun: BlitzRun?

    /// 当前是否处于每日保险箱对局（用于界面判断是否播放章节过场等）。
    var isDailyPlay: Bool { isDaily }

    /// 当前是否处于时间挑战对局。
    var isBlitzPlay: Bool { isBlitz }

    /// 时间挑战的当前运行态（倒计时 / 已过关数 / 当前关卡）。
    var blitz: BlitzRun? { blitzRun }

    var onChange: ((TableView) -> Void)?

    func showMenu() {
        game = nil
        isDaily = false
        isBlitz = false
        blitzRun = nil
        transition(to: .menu)
    }

    func showSelect() {
        game = nil
        isDaily = false
        isBlitz = false
        blitzRun = nil
        transition(to: .select)
    }

    func showDaily() {
        game = nil
        isDaily = false
        isBlitz = false
        blitzRun = nil
        transition(to: .daily)
    }

    func showBlitz() {
        game = nil
        isDaily = false
        isBlitz = false
        blitzRun = nil
        transition(to: .blitz)
    }

    /// 开始今天的每日保险箱。
    func startDaily() {
        isDaily = true
        game = GameState(level: Level(dailyPuzzle: DailyManager.dailyPuzzle()))
        transition(to: .play)
    }

    /// 开始一局时间挑战：新建 BlitzRun，进入第一张随机挑战。
    func startBlitz() {
        isBlitz = true
        isDaily = false
        let run = BlitzRun()
        blitzRun = run
        game = run.current
        transition(to: .play)
    }

    /// 时间挑战完成当前关：加时、换下一关，仍停留在对局界面。
    func advanceBlitz() {
        guard let run = blitzRun else { return }
        run.advance()
        game = run.current
    }

    /// 时间挑战倒计时归零：记录成绩并进入结算。
    func endBlitz() {
        guard let run = blitzRun else { return }
        let previousBest = BlitzManager.bestCount
        BlitzManager.recordRun(count: run.cleared)
        lastBlitzOutcome = BlitzOutcome(cleared: run.cleared,
                                        isNewBest: run.cleared > 0 && run.cleared > previousBest)
        transition(to: .blitzResult)
    }

    func showRules() {
        game = nil
        transition(to: .rules)
    }

    func showSettings() {
        game = nil
        transition(to: .settings)
    }

    func showStats() {
        game = nil
        transition(to: .stats)
    }

    func start(level: Int) {
        isDaily = false
        game = GameState(level: LevelRepository.level(level))
        transition(to: .play)
    }

    func retry() {
        guard let game else { return }
        if isDaily {
            // 每日重试：按同一个日期种子重新生成专属谜题。
            self.game = GameState(level: Level(dailyPuzzle: DailyManager.dailyPuzzle()))
            transition(to: .play)
        } else {
            start(level: game.level.number)
        }
    }

    func nextLevel() {
        guard let result = lastResult, result.won else { return }
        // 每日保险箱没有「下一关」，通关后直接回每日页。
        guard !result.isDaily else {
            showDaily()
            return
        }
        let next = result.level + 1
        if next <= LevelRepository.totalLevels && SaveManager.isUnlocked(next) {
            start(level: next)
        } else {
            showSelect()
        }
    }

    /// 对局结束。主线写入星级与统计；每日模式只写入每日纪录。
    func finish(won: Bool, stars: Int, time: TimeInterval, timedOut: Bool) {
        guard let game else { return }
        var newAchievements: [Achievement] = []
        let previousBest: TimeInterval?

        if isDaily {
            // 每日模式只记录自己的时间与连续天数，不写入主线星级、解锁和关卡统计。
            previousBest = won ? DailyManager.bestTodayTime : nil
            if won {
                DailyManager.recordCompletion(time: time)
            }
        } else if won {
            previousBest = StatisticsManager.load().bestTimes[game.level.number]
            // 先写星级，统计里的「章节满星」判定依赖最新星级。
            SaveManager.record(level: game.level.number, stars: stars)
            newAchievements = StatisticsManager.record(won: true,
                                                       level: game.level.number,
                                                       stars: stars,
                                                       time: time,
                                                       moves: game.moves,
                                                       hintsUsed: game.hintsUsed)
        } else {
            previousBest = nil
            StatisticsManager.record(won: false,
                                     level: game.level.number,
                                     stars: 0,
                                     time: time,
                                     moves: game.moves,
                                     hintsUsed: game.hintsUsed)
        }

        let isNewBest = won && (previousBest == nil || time < previousBest!)

        let result = LevelResult(level: game.level.number,
                                 stars: stars,
                                 time: time,
                                 won: won,
                                 timedOut: timedOut,
                                 hintsUsed: game.hintsUsed,
                                 newAchievements: newAchievements,
                                 isDaily: isDaily,
                                 isNewBest: isNewBest)
        lastResult = result
        transition(to: .result)
    }

    private func transition(to screen: TableView) {
        self.screen = screen
        onChange?(screen)
    }
}
