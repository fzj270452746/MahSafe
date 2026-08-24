//
//  RuleEngine.swift
//  MahSafe
//
//  规则判定核心。把玩家的一个动作映射成「没反应 / 选中 / 前进 / 完成 / 错误」。
//  纯函数式，不持有状态，进度全部读写在 PuzzleState 上。
//

import Foundation

enum PlayerAction {
    case tap(GridPos)
    case rotate(GridPos, steps: Int)
    case flip(GridPos)
    case place(GridPos, MahjongType)
    case confirm
}

enum ActionOutcome: Equatable {
    case nothing
    case selected(GridPos)
    case swapped
    case progress(GridPos?)
    case completed
    case wrong(GridPos?)
}

enum RuleEngine {

    static func outcome(of action: PlayerAction, puzzle: Puzzle, state: PuzzleState) -> ActionOutcome {
        switch puzzle.solution {
        case .tapOrder(let order):
            return evaluateTapOrder(order, rule: puzzle.rule, action: action, state: state)
        case .countOrder(let types):
            return evaluateCountOrder(types, action: action, state: state)
        case .rearrange(let target):
            return evaluateRearrange(target, action: action, puzzle: puzzle, state: state)
        case .rotateTo(let target):
            return evaluateRotateTo(target, action: action, puzzle: puzzle, state: state)
        case .revealTarget(let pos, _):
            return evaluateReveal(pos, action: action)
        case .place(let mapping):
            return evaluatePlace(mapping, action: action, state: state)
        case .multi(let steps):
            return evaluateMulti(steps, action: action, state: state)
        }
    }

    // MARK: - 顺序点击

    private static func evaluateTapOrder(_ order: [GridPos],
                                         rule: RuleKind,
                                         action: PlayerAction,
                                         state: PuzzleState) -> ActionOutcome {
        guard case .tap(let pos) = action else { return .nothing }

        if rule == .dailyCipher {
            // 每一行都是独立的小谜题，四张异常牌可按任意顺序提交。
            // 已经找出的牌再次点击不处罚，避免明确的正确答案反而闪红。
            if state.tapped.contains(pos) {
                return .nothing
            }
            guard order.contains(pos) else {
                return .wrong(pos)
            }
            state.markTapped(pos)
            return state.tapped.count >= order.count ? .completed : .progress(pos)
        }

        if rule == .uniquePair {
            // 对子不区分先后，点到两张里任意一张未点过的即可。
            guard order.contains(pos), !state.tapped.contains(pos) else {
                return .wrong(pos)
            }
            state.markTapped(pos)
            return state.tapped.count >= order.count ? .completed : .progress(pos)
        }

        guard state.tapCursor < order.count else { return .completed }

        if pos == order[state.tapCursor] {
            state.advanceTap()
            return state.tapCursor >= order.count ? .completed : .progress(pos)
        }
        return .wrong(pos)
    }

    // 重复次数规则：按类型顺序点击，每个类型点一张代表即可。
    private static func evaluateCountOrder(_ types: [MahjongType], action: PlayerAction, state: PuzzleState) -> ActionOutcome {
        guard case .tap(let pos) = action else { return .nothing }
        guard state.tapCursor < types.count else { return .completed }

        if state.tile(at: pos).type == types[state.tapCursor] {
            state.advanceTap()
            return state.tapCursor >= types.count ? .completed : .progress(pos)
        }
        return .wrong(pos)
    }

    // MARK: - 翻面探查

    private static func evaluateReveal(_ target: GridPos, action: PlayerAction) -> ActionOutcome {
        guard case .tap(let pos) = action else { return .nothing }
        return pos == target ? .completed : .wrong(pos)
    }

    // MARK: - 交换到目标

    private static func evaluateRearrange(_ target: [[MahjongType]],
                                          action: PlayerAction,
                                          puzzle: Puzzle,
                                          state: PuzzleState) -> ActionOutcome {
        switch action {
        case .tap(let pos):
            if state.selected == nil {
                state.selected = pos
                return .selected(pos)
            } else if state.selected == pos {
                state.selected = nil
                return .nothing
            } else {
                state.swap(state.selected!, pos)
                state.selected = nil
                return .swapped
            }
        case .confirm:
            return typeGridMatches(state) == target ? .completed : .wrong(nil)
        default:
            return .nothing
        }
    }

    // MARK: - 旋转到目标

    private static func evaluateRotateTo(_ target: [[Int]],
                                         action: PlayerAction,
                                         puzzle: Puzzle,
                                         state: PuzzleState) -> ActionOutcome {
        switch action {
        case .rotate(let pos, let steps):
            state.rotate(pos, by: steps)
            return .nothing
        case .confirm:
            return rotationGridMatches(state) == target ? .completed : .wrong(nil)
        default:
            return .nothing
        }
    }

    // MARK: - 补牌 / 替换

    private static func evaluatePlace(_ mapping: [GridPos: MahjongType],
                                      action: PlayerAction,
                                      state: PuzzleState) -> ActionOutcome {
        switch action {
        case .tap(let pos):
            if mapping.keys.contains(pos) && !state.isFilled(pos) {
                state.selected = pos
                return .selected(pos)
            }
            return .nothing
        case .place(let pos, let type):
            guard let expected = mapping[pos], !state.isFilled(pos) else {
                return .nothing
            }
            if type == expected {
                state.place(type, at: pos)
                state.markFilled(pos)
                state.selected = nil
                let done = state.filled.count >= mapping.count
                return done ? .completed : .progress(pos)
            }
            return .wrong(pos)
        default:
            return .nothing
        }
    }

    // MARK: - 多步组合

    private static func evaluateMulti(_ steps: [PuzzleStep],
                                      action: PlayerAction,
                                      state: PuzzleState) -> ActionOutcome {
        let idx = state.stepCursor
        guard steps.indices.contains(idx) else { return .completed }
        let step = steps[idx]

        switch action {
        case .tap(let pos):
            if case .tap(let target) = step.kind, pos == target {
                return advanceMulti(idx, steps: steps, state: state, feedback: pos)
            }
            return .wrong(pos)

        case .rotate(let pos, let rotateSteps):
            state.rotate(pos, by: rotateSteps)
            if case .rotate(let target, let to) = step.kind, pos == target {
                if state.tile(at: pos).rotation == to {
                    return advanceMulti(idx, steps: steps, state: state, feedback: pos)
                }
            }
            return .nothing

        case .flip:
            return .nothing

        case .place(let pos, let type):
            if case .place(let target, let expected) = step.kind, pos == target, type == expected {
                state.place(type, at: pos)
                return advanceMulti(idx, steps: steps, state: state, feedback: pos)
            }
            return .wrong(pos)

        case .confirm:
            return .nothing
        }
    }

    private static func advanceMulti(_ idx: Int,
                                     steps: [PuzzleStep],
                                     state: PuzzleState,
                                     feedback: GridPos) -> ActionOutcome {
        state.markStepDone(idx)
        state.advanceStep()
        return state.stepCursor >= steps.count ? .completed : .progress(feedback)
    }

    // MARK: - 棋盘对比

    static func typeGridMatches(_ state: PuzzleState) -> [[MahjongType]] {
        state.slots.map { row in row.map { $0.type } }
    }

    static func rotationGridMatches(_ state: PuzzleState) -> [[Int]] {
        state.slots.map { row in row.map { $0.rotation } }
    }
}
