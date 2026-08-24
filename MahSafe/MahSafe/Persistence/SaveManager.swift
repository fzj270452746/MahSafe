//
//  SaveManager.swift
//  MahSafe
//
//  本地进度存档。用 UserDefaults 存星级与解锁进度，
//  不引入数据库，也不做成单例 —— 只在启动时 load 一次到内存。
//

import Foundation

struct GameProgress {
    var highestUnlocked: Int = 1
    var stars: [Int: Int] = [:]   // level -> 星数 1...3
    var introducedChapters: Set<Int> = []   // 已展示过开场过场的章节
    var onboardingSeen: Bool = false
}

enum SaveManager {

    private static let unlockedKey = "mahsafe.highestUnlocked"
    private static let starsKey = "mahsafe.levelStars"
    private static let chaptersKey = "mahsafe.introducedChapters"
    private static let onboardingKey = "mahsafe.onboardingSeen"
    private static let soundKey = "mahsafe.soundEnabled"
    private static let hapticKey = "mahsafe.hapticEnabled"
    private static let musicKey = "mahsafe.musicEnabled"

    private(set) static var progress = GameProgress()

    static func load() {
        let defaults = UserDefaults.standard
        let unlocked = defaults.integer(forKey: unlockedKey)
        progress.highestUnlocked = unlocked > 0 ? unlocked : 1

        if let stored = defaults.dictionary(forKey: starsKey) as? [String: Int] {
            progress.stars = stored.reduce(into: [:]) { dict, pair in
                if let level = Int(pair.key) {
                    dict[level] = pair.value
                }
            }
        }

        if let chapters = defaults.array(forKey: chaptersKey) as? [Int] {
            progress.introducedChapters = Set(chapters)
        }

        progress.onboardingSeen = defaults.bool(forKey: onboardingKey)
    }

    static func save() {
        let defaults = UserDefaults.standard
        defaults.set(progress.highestUnlocked, forKey: unlockedKey)
        let stringified = progress.stars.reduce(into: [String: Int]()) { dict, pair in
            dict[String(pair.key)] = pair.value
        }
        defaults.set(stringified, forKey: starsKey)
        defaults.set(Array(progress.introducedChapters), forKey: chaptersKey)
        defaults.set(progress.onboardingSeen, forKey: onboardingKey)
    }

    // MARK: - 进度读写

    static func stars(for level: Int) -> Int {
        progress.stars[level] ?? 0
    }

    static func isUnlocked(_ level: Int) -> Bool {
        level <= progress.highestUnlocked
    }

    /// 通关后记录星级，并顺带解锁下一关。
    static func record(level: Int, stars: Int) {
        let current = progress.stars[level] ?? 0
        progress.stars[level] = max(current, stars)
        if level >= progress.highestUnlocked && level < LevelRepository.totalLevels {
            progress.highestUnlocked = level + 1
        }
        save()
    }

    static func resetAll() {
        progress = GameProgress()
        save()
    }

    // MARK: - 章节过场与引导

    static var hasSeenOnboarding: Bool {
        progress.onboardingSeen
    }

    static func markOnboardingSeen() {
        guard !progress.onboardingSeen else { return }
        progress.onboardingSeen = true
        save()
    }


    static func isChapterIntroduced(_ chapter: Int) -> Bool {
        progress.introducedChapters.contains(chapter)
    }

    /// 记录某个章节的开场过场已展示过（用于只播放一次）。
    static func markChapterIntroduced(_ chapter: Int) {
        guard !progress.introducedChapters.contains(chapter) else { return }
        progress.introducedChapters.insert(chapter)
        save()
    }

    // MARK: - 偏好

    static var soundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: soundKey)
        }
    }

    static var hapticEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: hapticKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hapticKey)
        }
    }

    static var musicEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: musicKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: musicKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: musicKey)
        }
    }
}
