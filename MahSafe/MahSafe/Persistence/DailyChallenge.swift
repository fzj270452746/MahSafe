//
//  DailyChallenge.swift
//  MahSafe
//
//  每日密码：按日期生成一局独立的「四段序列校验」谜题，并记录连续打卡。
//  每日谜题使用自己的日期种子，不映射主线关卡，也不改写主线进度。
//

import Foundation

enum DailyManager {

    private static let lastKey = "mahsafe.daily.lastCompleted"
    private static let streakKey = "mahsafe.daily.streak"
    private static let bestStreakKey = "mahsafe.daily.bestStreak"
    private static let bestTimeKey = "mahsafe.daily.bestTime"

    // MARK: - 日期

    /// 当天固定的专属谜题。同一自然日内布局与答案保持不变。
    static func dailyPuzzle() -> Puzzle {
        PuzzleGenerator.makeDailyCipher(seed: dailySeed())
    }

    static func dailyCipherID() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: Date())
    }

    private static func dailySeed() -> UInt64 {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let year = UInt64(parts.year ?? 0)
        let month = UInt64(parts.month ?? 0)
        let day = UInt64(parts.day ?? 0)
        return year &* 10_000 &+ month &* 100 &+ day
    }

    static func todayKey() -> String {
        formatter.string(from: Date())
    }

    static func yesterdayKey() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }

    static func displayDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f.string(from: Date())
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - 今日状态

    static var completedToday: Bool {
        UserDefaults.standard.string(forKey: lastKey) == todayKey()
    }

    /// 今日最好成绩（秒），未通关返回 nil。
    static var bestTodayTime: TimeInterval? {
        guard completedToday else { return nil }
        return UserDefaults.standard.double(forKey: bestTimeKey)
    }

    static var currentStreak: Int {
        let last = UserDefaults.standard.string(forKey: lastKey) ?? ""
        if last == todayKey() || last == yesterdayKey() {
            return UserDefaults.standard.integer(forKey: streakKey)
        }
        return 0
    }

    static var bestStreak: Int {
        UserDefaults.standard.integer(forKey: bestStreakKey)
    }

    // MARK: - 记录

    /// 记录一次今日通关，更新连续打卡与最好成绩。
    static func recordCompletion(time: TimeInterval) {
        let today = todayKey()
        let last = UserDefaults.standard.string(forKey: lastKey)

        // 今天已经通关：只可能刷新最好成绩。
        if last == today {
            let previous = UserDefaults.standard.double(forKey: bestTimeKey)
            if time < previous {
                UserDefaults.standard.set(time, forKey: bestTimeKey)
            }
            return
        }

        UserDefaults.standard.set(today, forKey: lastKey)
        UserDefaults.standard.set(time, forKey: bestTimeKey)

        // 昨天通关过 → 连击 +1；否则重新从 1 开始。
        var streak = 1
        if last == yesterdayKey() {
            streak = UserDefaults.standard.integer(forKey: streakKey) + 1
        }
        UserDefaults.standard.set(streak, forKey: streakKey)
        if streak > bestStreak {
            UserDefaults.standard.set(streak, forKey: bestStreakKey)
        }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: lastKey)
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: bestStreakKey)
        UserDefaults.standard.removeObject(forKey: bestTimeKey)
    }
}
