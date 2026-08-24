//
//  LevelRepository.swift
//  MahSafe
//
//  关卡目录：10 个章节、100 个关卡。负责把章节信息与关卡号对应起来。
//

import Foundation

enum LevelRepository {

    static let totalLevels = 100
    static let levelsPerChapter = 10

    static let chapters: [ChapterInfo] = [
        ChapterInfo(number: 1, title: "The Loose Tile", subtitle: "Tap & repeat", range: 1...10),
        ChapterInfo(number: 2, title: "East Wind Turns", subtitle: "Sequence", range: 11...20),
        ChapterInfo(number: 3, title: "One Seat Empty", subtitle: "Gaps & impostors", range: 21...30),
        ChapterInfo(number: 4, title: "The Crooked Wall", subtitle: "Rotation", range: 31...40),
        ChapterInfo(number: 5, title: "Across the Lacquer", subtitle: "Reflection", range: 41...50),
        ChapterInfo(number: 6, title: "Marks on the Back", subtitle: "Flip & direction", range: 51...60),
        ChapterInfo(number: 7, title: "The Dealer's Cut", subtitle: "Swap & replace", range: 61...70),
        ChapterInfo(number: 8, title: "Three Hands Deep", subtitle: "Chained rules", range: 71...80),
        ChapterInfo(number: 9, title: "Tea Gone Cold", subtitle: "Timed", range: 81...90),
        ChapterInfo(number: 10, title: "Last Table Standing", subtitle: "All rules", range: 91...100)
    ]

    static func level(_ number: Int) -> Level {
        Level(number: number)
    }

    static func chapter(of level: Int) -> ChapterInfo {
        let index = (level - 1) / levelsPerChapter
        return chapters[min(max(index, 0), chapters.count - 1)]
    }
}
