//
//  BlitzRun.swift
//  MahSafe
//
//  一分钟快局的运行态：持有全局倒计时与已过关数，
//  当前那一关的棋盘与规则仍交给 GameState。每过一关加时并换一张全新挑战。
//

import Foundation

final class BlitzRun {

    static let startTime: TimeInterval = 60
    static let clearBonus: TimeInterval = 5

    private(set) var timeRemaining: TimeInterval
    private(set) var cleared = 0
    private(set) var current: GameState

    private var seed: UInt64

    init() {
        seed = UInt64.random(in: 0 ... .max)
        timeRemaining = BlitzRun.startTime
        current = GameState(level: Level(blitzPuzzle: BlitzGenerator.makeChallenge(difficulty: 0, seed: seed)))
    }

    var isOver: Bool { timeRemaining <= 0 }

    /// 推进全局倒计时。返回是否在本帧归零。
    @discardableResult
    func tick(_ dt: TimeInterval) -> Bool {
        guard !isOver else { return true }
        timeRemaining -= dt
        return isOver
    }

    /// 完成当前挑战：+1 过关数、加时、换下一张全新挑战。
    func advance() {
        cleared += 1
        timeRemaining += BlitzRun.clearBonus
        seed = seed &* 0x9E37_79B9 &+ 0x51ED_270B
        current = GameState(level: Level(blitzPuzzle: BlitzGenerator.makeChallenge(difficulty: cleared, seed: seed)))
    }
}
