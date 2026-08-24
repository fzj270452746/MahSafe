//
//  GameState.swift
//  MahSafe
//
//  单局运行态：持有谜题 + 棋盘逻辑 + 对局指标（提示次数 / 步数 / 用时）。
//  规则判定委托给 RuleEngine，这里只负责把动作转译成结果并记账。
//

import Foundation

final class GameState {

    let level: Level
    let puzzle: Puzzle
    let board: PuzzleState

    private(set) var hintsUsed = 0
    private(set) var moves = 0
    private(set) var elapsed: TimeInterval = 0
    private(set) var isComplete = false

    private var undoStack: [PuzzleState.Snapshot] = []

    init(level: Level) {
        self.level = level
        self.puzzle = level.puzzle
        self.board = PuzzleState(puzzle: puzzle)
    }

    var rule: RuleKind { puzzle.rule }
    var family: InteractionFamily { puzzle.rule.family }
    var isTimed: Bool { puzzle.timeLimit != nil }
    var timeRemaining: TimeInterval? {
        puzzle.timeLimit.map { max(0, $0 - elapsed) }
    }
    var didTimeOut: Bool {
        puzzle.timeLimit.map { elapsed >= $0 } ?? false
    }

    /// 推进对局计时。
    func tick(_ dt: TimeInterval) {
        guard !isComplete else { return }
        elapsed += dt
    }

    /// 把玩家动作交给规则引擎，返回结果并顺手记账步数。
    /// 撤销仅对「会改动牌面」的动作开放（交换 / 旋转 / 补牌）。
    @discardableResult
    func apply(_ action: PlayerAction) -> ActionOutcome {
        let before = board.makeSnapshot()
        let outcome = RuleEngine.outcome(of: action, puzzle: puzzle, state: board)

        switch outcome {
        case .selected, .swapped, .progress, .wrong:
            moves += 1
        case .completed:
            moves += 1
            isComplete = true
        case .nothing:
            break
        }

        if shouldRecordUndo(action, outcome) {
            undoStack.append(before)
            if undoStack.count > 40 {
                undoStack.removeFirst()
            }
        }
        return outcome
    }

    /// 该动作是否真的改变了牌面，值得进撤销栈。
    private func shouldRecordUndo(_ action: PlayerAction, _ outcome: ActionOutcome) -> Bool {
        switch family {
        case .rearrange:
            if case .tap = action, outcome == .swapped { return true }
            return false
        case .rotateTo:
            if case .rotate = action { return true }
            return false
        case .place:
            if case .place = action, case .progress = outcome { return true }
            return false
        case .multi:
            if case .rotate = action { return true }
            if case .place = action, case .progress = outcome { return true }
            return false
        default:
            return false
        }
    }

    /// 支持撤销的规则范型（点击 / 翻面类不开放，避免误退进度）。
    var supportsUndo: Bool {
        family == .rearrange || family == .rotateTo || family == .place || family == .multi
    }

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    /// 回退最近一次牌面改动。返回是否真的回退了。
    @discardableResult
    func undo() -> Bool {
        guard let snapshot = undoStack.popLast() else { return false }
        board.restore(snapshot)
        if moves > 0 { moves -= 1 }
        return true
    }

    /// 逐级提示。返回本次提示文本，用完则返回 nil。
    func showNextHint() -> String? {
        guard hintsUsed < puzzle.hints.count else { return nil }
        let text = puzzle.hints[hintsUsed]
        hintsUsed += 1
        return text
    }

    /// 三星评分：基础三星，用时超过三星/二星阈值各扣一星，每用一次提示再扣一星，下限一星。
    func starRating() -> Int {
        var stars = 3
        if let par = puzzle.parTimes {
            if elapsed > par[0] { stars -= 1 }
            if elapsed > par[1] { stars -= 1 }
        }
        stars -= hintsUsed
        return min(max(stars, 1), 3)
    }
}
