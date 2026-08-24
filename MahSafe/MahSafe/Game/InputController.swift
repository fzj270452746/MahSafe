//
//  InputController.swift
//  MahSafe
//
//  手势识别器：把一段触摸轨迹分类为「点按 / 滑动旋转 / 长按翻面」。
//  只产出抽象的 TileGesture，不关心具体规则；由 GameScene 决定是否采纳。
//

import Foundation
import CoreGraphics

enum TileGesture {
    case tap(GridPos)
    case rotate(GridPos, steps: Int)   // +1 顺时针 90°，-1 逆时针
    case peekStart(GridPos)            // 长按开始（翻面探查）
    case peekEnd(GridPos)              // 长按结束（翻回）
}

final class InputController {

    var onGesture: ((TileGesture) -> Void)?

    private var active = false
    private var startPoint = CGPoint.zero
    private var startGrid: GridPos?
    private var startTime: TimeInterval = 0
    private var resolved = false
    private var peeking = false

    private let moveThreshold: CGFloat = 16
    private let longPressDuration: TimeInterval = 0.30

    func began(at point: CGPoint, grid: GridPos?, time: TimeInterval) {
        active = true
        resolved = false
        peeking = false
        startPoint = point
        startGrid = grid
        startTime = time
    }

    /// 手指滑动超过阈值 → 判定为滑动旋转（以主方向为准）。
    func moved(to point: CGPoint) {
        guard active, !resolved, !peeking, let grid = startGrid else { return }
        let dx = point.x - startPoint.x
        let dy = point.y - startPoint.y
        guard hypot(dx, dy) > moveThreshold else { return }
        resolved = true
        let steps: Int
        if abs(dx) >= abs(dy) {
            steps = dx > 0 ? 1 : -1
        } else {
            steps = dy > 0 ? 1 : -1
        }
        onGesture?(.rotate(grid, steps: steps))
    }

    /// 按住超时且未移动 → 判定为长按翻面（只触发一次）。
    func update(time: TimeInterval) {
        guard active, !resolved, !peeking, let grid = startGrid else { return }
        guard time - startTime >= longPressDuration else { return }
        peeking = true
        onGesture?(.peekStart(grid))
    }

    func ended() {
        if peeking, let grid = startGrid {
            onGesture?(.peekEnd(grid))
        } else if !resolved, let grid = startGrid {
            onGesture?(.tap(grid))
        }
        reset()
    }

    func cancelled() {
        if peeking, let grid = startGrid {
            onGesture?(.peekEnd(grid))
        }
        reset()
    }

    private func reset() {
        active = false
        resolved = false
        peeking = false
        startGrid = nil
    }
}
