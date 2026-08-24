//
//  Level.swift
//  MahSafe
//
//  关卡元数据。谜题本体由 PuzzleGenerator 按需生成。
//

import Foundation

struct Level {
    let number: Int
    private let puzzleOverride: Puzzle?
    private let titleOverride: String?

    init(number: Int) {
        self.number = number
        puzzleOverride = nil
        titleOverride = nil
    }

    init(dailyPuzzle: Puzzle) {
        number = 0
        puzzleOverride = dailyPuzzle
        titleOverride = "Today's Hand"
    }

    init(blitzPuzzle: Puzzle) {
        number = 0
        puzzleOverride = blitzPuzzle
        titleOverride = "One-Minute"
    }

    var chapter: Int {
        if let puzzleOverride { return puzzleOverride.chapter }
        return (number - 1) / 10 + 1
    }

    var rule: RuleKind {
        if let puzzleOverride { return puzzleOverride.rule }
        return PuzzleGenerator.rule(for: number)
    }

    var isTimed: Bool {
        if let puzzleOverride { return puzzleOverride.timeLimit != nil }
        return chapter == 9
    }

    var title: String {
        titleOverride ?? "Table \(number)"
    }

    var puzzle: Puzzle {
        return puzzleOverride ?? PuzzleGenerator.make(level: number)
    }
}

struct ChapterInfo {
    let number: Int
    let title: String
    let subtitle: String
    let range: ClosedRange<Int>
}
