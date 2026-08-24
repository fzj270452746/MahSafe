//
//  PuzzleState.swift
//  MahSafe
//
//  对局中的可变棋盘与解题进度。GameScene 只通过它读写牌面，
//  规则引擎则读它判断对错。
//

import Foundation

final class PuzzleState {

    let puzzle: Puzzle
    private(set) var slots: [[TileState]]

    // 顺序点击类规则：已经正确点到的下标。
    private(set) var tapCursor = 0

    // 无序点击类规则（每日密码 / 找对子）：已点对的格子集合。
    private(set) var tapped: Set<GridPos> = []

    // 交换类规则：先选中的那张牌。
    var selected: GridPos?

    // 补牌类规则：已经正确填好的格子。
    private(set) var filled: Set<GridPos> = []

    // 组合规则：当前执行到第几步、各步是否完成。
    private(set) var stepCursor = 0
    private(set) var stepsDone: [Bool]

    init(puzzle: Puzzle) {
        self.puzzle = puzzle
        self.slots = puzzle.grid
        if case .multi(let steps) = puzzle.solution {
            stepsDone = Array(repeating: false, count: steps.count)
        } else {
            stepsDone = []
        }
    }

    var rows: Int { puzzle.rows }
    var cols: Int { puzzle.cols }

    func contains(_ pos: GridPos) -> Bool {
        pos.row >= 0 && pos.row < rows && pos.col >= 0 && pos.col < cols
    }

    func tile(at pos: GridPos) -> TileState {
        slots[pos.row][pos.col]
    }

    func update(_ tile: TileState, at pos: GridPos) {
        slots[pos.row][pos.col] = tile
    }

    // MARK: - 基本操作

    /// 交换两个格子的牌面。
    func swap(_ a: GridPos, _ b: GridPos) {
        let tmp = slots[a.row][a.col]
        slots[a.row][a.col] = slots[b.row][b.col]
        slots[b.row][b.col] = tmp
    }

    /// 顺时针旋转 steps 档（负数为逆时针）。
    func rotate(_ pos: GridPos, by steps: Int) {
        var t = slots[pos.row][pos.col]
        t.rotation = (t.rotation + steps + 4) % 4
        slots[pos.row][pos.col] = t
    }

    /// 翻面。
    func flip(_ pos: GridPos) {
        var t = slots[pos.row][pos.col]
        t.isFlipped.toggle()
        slots[pos.row][pos.col] = t
    }

    /// 把某格子的牌换成指定类型（用于补牌 / 替换）。
    func place(_ type: MahjongType, at pos: GridPos) {
        var t = slots[pos.row][pos.col]
        t.type = type
        t.isEmpty = false
        t.rotation = 0
        slots[pos.row][pos.col] = t
    }

    // MARK: - 进度

    func advanceTap() {
        tapCursor += 1
    }

    func resetTap() {
        tapCursor = 0
    }

    func markTapped(_ pos: GridPos) {
        tapped.insert(pos)
    }

    func markFilled(_ pos: GridPos) {
        filled.insert(pos)
    }

    func isFilled(_ pos: GridPos) -> Bool {
        filled.contains(pos)
    }

    func markStepDone(_ index: Int) {
        guard stepsDone.indices.contains(index) else { return }
        stepsDone[index] = true
    }

    func advanceStep() {
        stepCursor += 1
    }

    var allStepsDone: Bool {
        stepsDone.allSatisfy { $0 }
    }

    // MARK: - 快照（供撤销）

    /// 完整可恢复状态快照。slots 是值类型深拷贝，其余字段同理。
    struct Snapshot {
        let slots: [[TileState]]
        let tapCursor: Int
        let tapped: Set<GridPos>
        let selected: GridPos?
        let filled: Set<GridPos>
        let stepCursor: Int
        let stepsDone: [Bool]
    }

    func makeSnapshot() -> Snapshot {
        Snapshot(slots: slots,
                 tapCursor: tapCursor,
                 tapped: tapped,
                 selected: selected,
                 filled: filled,
                 stepCursor: stepCursor,
                 stepsDone: stepsDone)
    }

    func restore(_ snapshot: Snapshot) {
        slots = snapshot.slots
        tapCursor = snapshot.tapCursor
        tapped = snapshot.tapped
        selected = snapshot.selected
        filled = snapshot.filled
        stepCursor = snapshot.stepCursor
        stepsDone = snapshot.stepsDone
    }
}
