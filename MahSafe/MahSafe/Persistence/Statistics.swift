//
//  Statistics.swift
//  MahSafe
//
//  对局统计与成就系统。与 SaveManager（星级/解锁）分工明确：
//  这里只记录「累计发生了什么」，不重复存关卡星级。
//  统计体用 JSON 编码整体落盘，成就目录是纯函数判定，方便在结算后即时比对。
//

import Foundation

// MARK: - 统计体

struct PlayerStatistics: Codable {
    var levelsCleared = 0          // 通关关卡数（≥1 星）
    var perfectClears = 0          // 三星通关次数
    var totalStars = 0             // 累计获得星数
    var totalMoves = 0             // 累计有效步数
    var totalHintsUsed = 0         // 累计使用提示次数
    var totalAttempts = 0          // 累计开局次数（含失败）
    var totalTime: TimeInterval = 0// 累计用时（仅成功局）
    var noHintClears = 0           // 未用提示通关次数
    var timedClears = 0            // 限时关通关次数
    var fastClearCount = 0         // 25 秒内通关次数
    var bestTimes: [Int: Double] = [:]   // level -> 最快用时
    var chapterCleared: Set<Int> = []    // 已满星通关的章节号
    var unlockedAchievements: Set<String> = []  // 已解锁成就 id

    /// 三星率，用于统计页展示；无通关时返回 0 避免除零。
    var perfectRate: Double {
        guard levelsCleared > 0 else { return 0 }
        return Double(perfectClears) / Double(levelsCleared)
    }
}

// MARK: - 成就定义

/// 单项成就。判定是「当前统计 → 是否满足」的纯函数，不依赖外部状态。
struct Achievement {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let isUnlocked: (PlayerStatistics) -> Bool
}

/// 成就目录。所有成就集中定义，统计页按此渲染。
enum AchievementCatalog {

    /// 进度类：按通关数量。
    private static func progress(_ id: String, _ title: String, _ detail: String,
                                 _ symbol: String, _ count: Int) -> Achievement {
        Achievement(id: id, title: title, detail: detail, symbol: symbol) { $0.levelsCleared >= count }
    }

    /// 星数类：按累计星数。
    private static func star(_ id: String, _ title: String, _ detail: String,
                             _ symbol: String, _ count: Int) -> Achievement {
        Achievement(id: id, title: title, detail: detail, symbol: symbol) { $0.totalStars >= count }
    }

    static let all: [Achievement] = {
        var list: [Achievement] = []

        // 通关进度
        list.append(progress("clear_1", "First Crack", "Open your first safe.", "🔓", 1))
        list.append(progress("clear_10", "A Seat Saved", "Open 10 tables.", "🗝️", 10))
        list.append(progress("clear_25", "Quarter Night", "Open 25 tables.", "🛡️", 25))
        list.append(progress("clear_50", "Half the House", "Open 50 tables.", "⚜️", 50))
        list.append(progress("clear_100", "Last Call", "Open all 100 tables.", "👑", 100))

        // 星数累计
        list.append(star("star_1", "A Glimmer", "Earn your first star.", "⭐", 1))
        list.append(star("star_30", "Thirty on the Tray", "Collect 30 stars.", "🥉", 30))
        list.append(star("star_90", "The Brass Stack", "Collect 90 stars.", "🥈", 90))
        list.append(star("star_180", "Under the Lamp", "Collect 180 stars.", "🥇", 180))
        list.append(star("star_300", "The House Remembers", "Collect all 300 stars.", "💎", 300))

        // 三星成就
        list.append(Achievement(id: "perfect_1", title: "Clean Hand", detail: "Earn 3 stars on any table.",
                                symbol: "✨") { $0.perfectClears >= 1 })
        list.append(Achievement(id: "perfect_10", title: "Ten Clean Hands", detail: "Earn 3 stars on 10 tables.",
                                symbol: "🌟") { $0.perfectClears >= 10 })
        list.append(Achievement(id: "perfect_50", title: "Quiet Mastery", detail: "Earn 3 stars on 50 tables.",
                                symbol: "🏵️") { $0.perfectClears >= 50 })

        // 技巧类
        list.append(Achievement(id: "nohint_1", title: "No Peeking", detail: "Open a table without hints.",
                                symbol: "🧠") { $0.noHintClears >= 1 })
        list.append(Achievement(id: "nohint_25", title: "Hands in Your Pockets", detail: "Open 25 tables without hints.",
                                symbol: "🎯") { $0.noHintClears >= 25 })
        list.append(Achievement(id: "fast_1", title: "Quick Count", detail: "Open a table in under 25 seconds.",
                                symbol: "⚡") { $0.fastClearCount >= 1 })
        list.append(Achievement(id: "fast_10", title: "Before the Tea Cools", detail: "Open 10 tables in under 25 seconds.",
                                symbol: "🚀") { $0.fastClearCount >= 10 })
        list.append(Achievement(id: "timed_1", title: "Against the Bell", detail: "Open a timed table.",
                                symbol: "⏱️") { $0.timedClears >= 1 })
        list.append(Achievement(id: "timed_10", title: "Last Sip", detail: "Open all 10 timed tables.",
                                symbol: "🕰️") { $0.timedClears >= 10 })

        // 章节成就：把某一章 10 关全部通关。
        for chapter in LevelRepository.chapters {
            let n = chapter.number
            list.append(Achievement(id: "chapter_\(n)",
                                    title: "\(chapter.title) Master",
                                    detail: "Clear every level in Chapter \(n).",
                                    symbol: "🏆") { $0.chapterCleared.contains(n) })
        }

        return list
    }()

    static func byID(_ id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}

// MARK: - 统计管理器

enum StatisticsManager {

    private static let key = "mahsafe.statistics.v1"

    static func load() -> PlayerStatistics {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(PlayerStatistics.self, from: data) else {
            return PlayerStatistics()
        }
        return decoded
    }

    private static func save(_ stats: PlayerStatistics) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 记录一次对局。返回本次「新解锁」的成就，供结算页展示。
    @discardableResult
    static func record(won: Bool, level: Int, stars: Int, time: TimeInterval,
                       moves: Int, hintsUsed: Int) -> [Achievement] {
        var stats = load()
        stats.totalAttempts += 1

        guard won else {
            save(stats)
            return []
        }

        stats.levelsCleared += 1
        stats.totalStars += stars
        stats.totalMoves += moves
        stats.totalHintsUsed += hintsUsed
        stats.totalTime += time
        if stars >= 3 { stats.perfectClears += 1 }
        if hintsUsed == 0 { stats.noHintClears += 1 }
        if Level(number: level).isTimed { stats.timedClears += 1 }
        if time <= 25 { stats.fastClearCount += 1 }

        let previous = stats.bestTimes[level] ?? .infinity
        stats.bestTimes[level] = min(previous, time)

        // 重新核算已满星通关的章节（依赖 SaveManager 里的星级）。
        for chapter in LevelRepository.chapters where chapterIsCleared(chapter.number) {
            stats.chapterCleared.insert(chapter.number)
        }

        let newly = newAchievements(afterApplying: &stats)
        save(stats)
        return newly
    }

    /// 一整个章节（10 关）是否都至少拿到 1 星。
    private static func chapterIsCleared(_ chapter: Int) -> Bool {
        let range = LevelRepository.chapters[chapter - 1].range
        return range.allSatisfy { SaveManager.stars(for: $0) > 0 }
    }

    /// 计算新解锁的成就，并把 id 写回统计体。
    private static func newAchievements(afterApplying stats: inout PlayerStatistics) -> [Achievement] {
        var newly: [Achievement] = []
        for achievement in AchievementCatalog.all {
            guard !stats.unlockedAchievements.contains(achievement.id) else { continue }
            if achievement.isUnlocked(stats) {
                stats.unlockedAchievements.insert(achievement.id)
                newly.append(achievement)
            }
        }
        return newly
    }

    /// 重置全部统计（随「重置进度」一起清空）。
    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
