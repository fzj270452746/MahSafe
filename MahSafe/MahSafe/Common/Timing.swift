//
//  Timing.swift
//  MahSafe
//
//  动画与反馈时长。集中管理，方便统一调手感。
//

import Foundation

enum Timing {
    static let tileTap = 0.10
    static let tileSwap = 0.18
    static let tileRotate = 0.16
    static let tileFlip = 0.14
    static let selection = 0.12
    static let hintPulse = 0.35

    static let wrongShake = 0.42
    static let redFlash = 0.30
    static let correctGlow = 0.32

    // 开门序列：把手 → 锁 → 门栓 → 门 → 内光，依次推进。
    static let handleTurn = 0.35
    static let lockClick = 0.28
    static let boltRetract = 0.30
    static let doorOpen = 0.62
    static let innerLight = 0.55

    static let starPop = 0.36
    static let starStagger = 0.16
    static let overlayIn = 0.28
}
