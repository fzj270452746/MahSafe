//
//  TileState.swift
//  MahSafe
//
//  棋盘坐标与单格逻辑状态。逻辑状态是唯一事实来源，
//  视觉节点只负责把它渲染出来。
//

import Foundation

struct GridPos: Hashable, CustomStringConvertible {
    let row: Int
    let col: Int

    var description: String { "(\(row),\(col))" }

    static func + (lhs: GridPos, rhs: GridPos) -> GridPos {
        GridPos(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
    }
}

struct TileState: Equatable {
    var type: MahjongType
    var rotation: Int = 0          // 0...3，每档 90°
    var isFlipped: Bool = false    // true = 显示牌背
    var backMark: BackMark? = nil  // 翻面后露出的记号
    var isEmpty: Bool = false      // 缺失牌谜题的凹槽
    var isLocked: Bool = false     // 装饰性锁定，不可操作
    var showsArrow: Bool = false   // 方向谜题显示指向箭头

    static func empty(type: MahjongType) -> TileState {
        TileState(type: type, isEmpty: true)
    }

    static func face(_ type: MahjongType, rotation: Int = 0) -> TileState {
        TileState(type: type, rotation: rotation)
    }

    static func back(_ type: MahjongType, mark: BackMark, rotation: Int = 0) -> TileState {
        TileState(type: type, rotation: rotation, isFlipped: false, backMark: mark)
    }
}
