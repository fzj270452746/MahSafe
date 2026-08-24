//
//  BlitzManager.swift
//  MahSafe
//
//  快局存档：记录单局最好通关数与累计通关数。
//  只存这两个数，不参与主线星级 / 解锁 / 成就，保持玩法独立。
//

import Foundation

enum BlitzManager {

    private static let bestKey = "mahsafe.blitz.bestCount"
    private static let totalKey = "mahsafe.blitz.totalCleared"

    /// 单局最好成绩（60s 内完成的挑战次数）。
    static var bestCount: Int {
        UserDefaults.standard.integer(forKey: bestKey)
    }

    /// 历史累计完成的挑战次数。
    static var totalCleared: Int {
        UserDefaults.standard.integer(forKey: totalKey)
    }

    /// 记录一次时间挑战的完成数，刷新最好成绩并累计。
    static func recordRun(count: Int) {
        guard count > 0 else { return }
        let previous = bestCount
        if count > previous {
            UserDefaults.standard.set(count, forKey: bestKey)
        }
        UserDefaults.standard.set(totalCleared + count, forKey: totalKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: bestKey)
        UserDefaults.standard.removeObject(forKey: totalKey)
    }
}
