//
//  PuzzleValidator.swift
//  MahSafe
//
//  对生成出来的谜题做结构性校验，确保答案唯一且可解。
//  每个规则都有「答案由构造保证」的不变量，这里把它们显式化，
//  一旦生成器改坏能立刻暴露。
//

import Foundation

enum PuzzleValidator {

    static func validate(_ puzzle: Puzzle) -> Bool {
        switch puzzle.solution {
        case .tapOrder(let order):
            return validateTapOrder(order, puzzle: puzzle)
        case .countOrder(let types):
            return validateCountOrder(types, puzzle: puzzle)
        case .rearrange(let target):
            return validateRearrange(target, puzzle: puzzle)
        case .rotateTo(let target):
            return validateRotateTo(target, puzzle: puzzle)
        case .revealTarget(let pos, let mark):
            return puzzle.contains(pos) && puzzle.tile(at: pos).backMark == mark
        case .place(let mapping):
            return validatePlace(mapping, puzzle: puzzle)
        case .multi(let steps):
            return steps.count >= 1 && steps.allSatisfy { validateStep($0, puzzle: puzzle) }
        }
    }

    private static func validateTapOrder(_ order: [GridPos], puzzle: Puzzle) -> Bool {
        guard !order.isEmpty else { return false }
        let set = Set(order)
        // 答案格子互不相同，且都在棋盘内、都可操作。
        return set.count == order.count
            && order.allSatisfy { puzzle.contains($0) && !puzzle.tile(at: $0).isEmpty }
    }

    private static func validateCountOrder(_ types: [MahjongType], puzzle: Puzzle) -> Bool {
        // 类型互不相同，且每种都真实存在于棋盘。
        guard Set(types).count == types.count, !types.isEmpty else { return false }
        let present = Set(puzzle.grid.flatMap { $0 }.map(\.type))
        return types.allSatisfy { present.contains($0) }
    }

    private static func validateRearrange(_ target: [[MahjongType]], puzzle: Puzzle) -> Bool {
        guard target.count == puzzle.rows, target.allSatisfy({ $0.count == puzzle.cols }) else {
            return false
        }
        // 目标必须是初始排列的一个置换（牌型多重集一致）。
        let initial = puzzle.grid.flatMap { $0.map(\.type) }.sorted { typeKey($0) < typeKey($1) }
        let targetFlat = target.flatMap { $0 }.sorted { typeKey($0) < typeKey($1) }
        return initial == targetFlat
    }

    private static func validateRotateTo(_ target: [[Int]], puzzle: Puzzle) -> Bool {
        guard target.count == puzzle.rows, target.allSatisfy({ $0.count == puzzle.cols }) else {
            return false
        }
        return target.flatMap { $0 }.allSatisfy { (0...3).contains($0) }
    }

    private static func validatePlace(_ mapping: [GridPos: MahjongType], puzzle: Puzzle) -> Bool {
        guard !mapping.isEmpty else { return false }
        return mapping.allSatisfy { pos, _ in puzzle.contains(pos) }
            && puzzle.rack != nil
    }

    private static func validateStep(_ step: PuzzleStep, puzzle: Puzzle) -> Bool {
        switch step.kind {
        case .tap(let pos):
            return puzzle.contains(pos) && !puzzle.tile(at: pos).isEmpty
        case .rotate(let pos, let to):
            return puzzle.contains(pos) && (0...3).contains(to)
        case .rearrange(let target):
            return validateRearrange(target, puzzle: puzzle)
        case .place(let pos, _):
            return puzzle.contains(pos)
        }
    }

    /// 给类型一个稳定排序键，保证牌型多重集比较与顺序无关。
    private static func typeKey(_ type: MahjongType) -> String {
        type.englishName
    }

    /// 全量自检：生成 100 关并逐一校验，返回失败的关卡号。
    static func validateAllLevels() -> [Int] {
        var failures: [Int] = []
        for level in 1...100 {
            let puzzle = PuzzleGenerator.make(level: level)
            if !validate(puzzle) {
                failures.append(level)
            }
        }
        return failures
    }
}
