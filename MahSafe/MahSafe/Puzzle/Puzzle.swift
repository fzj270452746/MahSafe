//
//  Puzzle.swift
//  MahSafe
//
//  单个谜题的完整描述：初始棋盘 + 规则 + 判定所需的解数据。
//  由 PuzzleGenerator 产出，规则引擎据此判分。
//

import Foundation

struct Puzzle {
    let level: Int
    let chapter: Int
    let rule: RuleKind
    let rows: Int
    let cols: Int

    /// 初始棋盘。可能包含空槽（missing）或翻面牌（flip）。
    let grid: [[TileState]]

    let solution: PuzzleSolution

    /// 限时关卡才有值，其余为 nil。
    let timeLimit: TimeInterval?

    /// 三星时间阈值（秒），按 [3星, 2星] 顺序。
    let parTimes: [TimeInterval]?

    /// 三级提示文本。
    let hints: [String]

    /// 提示二级要发光的格子。
    let hintGlowTargets: [GridPos]

    /// 补牌 / 替换类谜题的候选牌库（含干扰项），其余规则为 nil。
    let rack: [MahjongType]?
}

/// 规则相关的解数据。每种规则用其中一种 case。
enum PuzzleSolution {
    /// 需要点击的目标格子；大部分规则要求依次点击，每日密码与对子允许任意顺序。
    case tapOrder([GridPos])

    /// 重复次数规则：按出现次数从多到少，各点一张对应牌。
    case countOrder([MahjongType])

    /// 目标牌型排列（mirror/swap）。
    case rearrange([[MahjongType]])

    /// 每个格子的目标旋转步数（rotation/direction）。
    case rotateTo([[Int]])

    /// 需要翻面找出的目标牌与其背面记号（flip）。
    case revealTarget(GridPos, BackMark)

    /// 需要补入的正确牌（missing/replacement）。
    case place([GridPos: MahjongType])

    /// 多步组合。
    case multi([PuzzleStep])
}

struct PuzzleStep {
    enum Kind {
        case tap(GridPos)
        case rotate(GridPos, to: Int)
        case rearrange([[MahjongType]])
        case place(GridPos, MahjongType)
    }

    let kind: Kind
    let hint: String
}

extension Puzzle {
    /// 棋盘上所有非空、非锁定的可操作格子，按行优先顺序。
    func interactivePositions() -> [GridPos] {
        var list: [GridPos] = []
        for r in 0..<rows {
            for c in 0..<cols {
                let s = grid[r][c]
                if !s.isEmpty && !s.isLocked {
                    list.append(GridPos(row: r, col: c))
                }
            }
        }
        return list
    }

    func tile(at pos: GridPos) -> TileState {
        grid[pos.row][pos.col]
    }

    func contains(_ pos: GridPos) -> Bool {
        pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols
    }
}
