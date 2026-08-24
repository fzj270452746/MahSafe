//
//  PuzzleGenerator.swift
//  MahSafe
//
//  关卡生成器。以 level 作为种子，确定性地产出 100 个关卡。
//  每个谜题的答案都由构造方式保证唯一，无需暴力求解。
//

import Foundation

enum PuzzleGenerator {

    // MARK: - 入口

    static func make(level: Int) -> Puzzle {
        var rng = SeededGenerator(seed: UInt64(level) &* 0x9E37_79B9 &+ 0x51ED_270B)
        let rule = rule(for: level)
        switch rule {
        case .dailyCipher: return makeDailyCipher(seed: UInt64(level))
        case .uniquePair: return makeUniquePair(level: level, rule: rule, rng: &rng)
        case .uniqueSingle: return makeUniqueSingle(level: level, rule: rule, rng: &rng)
        case .countOrder: return makeCountOrder(level: level, rule: rule, rng: &rng)
        case .sequence: return makeSequence(level: level, rule: rule, rng: &rng)
        case .missing: return makeMissing(level: level, rule: rule, rng: &rng)
        case .decoy: return makeDecoy(level: level, rule: rule, rng: &rng)
        case .rotation: return makeRotation(level: level, rule: rule, rng: &rng)
        case .mirror: return makeMirror(level: level, rule: rule, rng: &rng)
        case .swap: return makeSwap(level: level, rule: rule, rng: &rng)
        case .direction: return makeDirection(level: level, rule: rule, rng: &rng)
        case .flip: return makeFlip(level: level, rule: rule, rng: &rng)
        case .replacement: return makeReplacement(level: level, rule: rule, rng: &rng)
        case .multi: return makeMulti(level: level, rule: rule, rng: &rng)
        }
    }

    // MARK: - 章节 → 规则映射

    static func rule(for level: Int) -> RuleKind {
        let chapter = (level - 1) / 10 + 1
        let slot = level % 10
        switch chapter {
        case 1:
            if level <= 3 { return .uniquePair }
            if level <= 6 { return .uniqueSingle }
            return .countOrder
        case 2:
            return .sequence
        case 3:
            return slot < 6 ? .missing : .decoy
        case 4:
            return .rotation
        case 5:
            return .mirror
        case 6:
            return slot < 5 ? .flip : .direction
        case 7:
            return slot < 5 ? .swap : .replacement
        case 8:
            return .multi
        case 9:
            // 限时章节：轮换使用前面的规则，加上时间压力。
            let cycle: [RuleKind] = [.uniqueSingle, .sequence, .countOrder, .rotation,
                                     .mirror, .direction, .decoy, .missing, .swap, .flip]
            return cycle[max(0, level - 81) % cycle.count]
        case 10:
            // 综合章节：更难的规则组合。
            let cycle: [RuleKind] = [.multi, .swap, .direction, .rotation, .mirror,
                                     .uniqueSingle, .countOrder, .decoy, .missing, .multi]
            return cycle[max(0, level - 91) % cycle.count]
        default:
            return .uniqueSingle
        }
    }

    static func chapter(for level: Int) -> Int {
        (level - 1) / 10 + 1
    }

    // MARK: - 每日密码

    /// 每日模式专属谜题：四条独立数字序列各被篡改一张牌，四行可按任意顺序破解。
    /// 它只由日期种子决定，不复用或映射任何主线关卡。
    static func makeDailyCipher(seed: UInt64) -> Puzzle {
        var rng = SeededGenerator(seed: seed ^ 0xD411_C1F3_2026_0816)
        let rows = 4
        let cols = 5
        let suits: [MahjongSuit] = [.character, .bamboo, .dot]
        var grid: [[TileState]] = []
        var targets: [GridPos] = []

        for row in 0..<rows {
            let suit = suits[(row + rng.int(suits.count)) % suits.count]
            let ascending = rng.bool()
            let start = ascending ? 1 + rng.int(5) : 5 + rng.int(5)
            let expectedRanks = (0..<cols).map { ascending ? start + $0 : start - $0 }
            let corruptCol = 1 + rng.int(cols - 2)
            let validRanks = Set(expectedRanks)
            let replacementRanks = (1...9).filter { !validRanks.contains($0) }
            let corruptRank = replacementRanks[rng.int(replacementRanks.count)]

            let tiles = expectedRanks.enumerated().map { column, rank in
                let displayedRank = column == corruptCol ? corruptRank : rank
                return TileState.face(numberedTile(suit: suit, rank: displayedRank))
            }
            grid.append(tiles)
            targets.append(GridPos(row: row, col: corruptCol))
        }

        let firstTarget = grid[targets[0].row][targets[0].col].type
        return Puzzle(level: 0,
                      chapter: 0,
                      rule: .dailyCipher,
                      rows: rows,
                      cols: cols,
                      grid: grid,
                      solution: .tapOrder(targets),
                      timeLimit: nil,
                      parTimes: [40, 75],
                      hints: [
                        "Each row should count up or down by one.",
                        "Exactly one number breaks each row. You may solve the rows in any order.",
                        "One corrupt tile is \(firstTarget.englishName)."
                      ],
                      hintGlowTargets: targets,
                      rack: nil)
    }

    private static func numberedTile(suit: MahjongSuit, rank: Int) -> MahjongType {
        switch suit {
        case .character: return .character(rank)
        case .bamboo: return .bamboo(rank)
        case .dot: return .dot(rank)
        case .wind, .dragon: return .character(rank)
        }
    }

    // MARK: - 网格尺寸

    private static func gridSize(level: Int, rule: RuleKind) -> (rows: Int, cols: Int) {
        if level == 1 { return (2, 2) }
        let chapter = (level - 1) / 10 + 1

        switch rule {
        case .dailyCipher:
            return (4, 5)
        case .sequence, .direction:
            return (3, 3)
        case .uniquePair, .missing, .decoy, .replacement, .multi:
            return (3, 3)
        case .swap:
            return (3, 3)
        case .rotation, .mirror:
            return level % 2 == 0 ? (3, 3) : (4, 3)
        case .uniqueSingle, .countOrder, .flip:
            if chapter >= 9 { return (4, 4) }
            return level % 2 == 0 ? (3, 3) : (4, 3)
        }
    }

    // MARK: - 组装

    private static func assemble(level: Int,
                                 rule: RuleKind,
                                 rows: Int,
                                 cols: Int,
                                 grid: [[TileState]],
                                 solution: PuzzleSolution,
                                 hints: [String],
                                 glowTargets: [GridPos],
                                 rack: [MahjongType]?,
                                 rng: inout SeededGenerator) -> Puzzle {
        let timed = chapter(for: level) == 9
        let timeLimit: TimeInterval? = timed ? timeLimit(level: level) : nil

        let parTimes: [TimeInterval]?
        if let limit = timeLimit {
            parTimes = [limit * 0.55, limit * 0.8]
        } else {
            let cells = Double(rows * cols)
            let threeStar = cells * 2.6 + 8
            parTimes = [threeStar, threeStar * 2.2]
        }

        return Puzzle(level: level,
                      chapter: chapter(for: level),
                      rule: rule,
                      rows: rows,
                      cols: cols,
                      grid: grid,
                      solution: solution,
                      timeLimit: timeLimit,
                      parTimes: parTimes,
                      hints: hints,
                      hintGlowTargets: glowTargets,
                      rack: rack)
    }

    private static func timeLimit(level: Int) -> TimeInterval {
        // 后期关卡时间更紧，但仍给足思考空间。
        TimeInterval(90 - (level - 81) * 4)
    }

    // MARK: - 通用工具

    private static func positions(rows: Int, cols: Int) -> [GridPos] {
        var list: [GridPos] = []
        for r in 0..<rows {
            for c in 0..<cols {
                list.append(GridPos(row: r, col: c))
            }
        }
        return list
    }

    private static func snakeOrder(rows: Int, cols: Int) -> [GridPos] {
        var list: [GridPos] = []
        for r in 0..<rows {
            let colsRange = r % 2 == 0 ? (0..<cols).map { $0 } : (0..<cols).reversed()
            for c in colsRange {
                list.append(GridPos(row: r, col: c))
            }
        }
        return list
    }

    private static func numberedTiles(_ rng: inout SeededGenerator) -> [MahjongType] {
        MahjongType.all.filter(\.isNumbered)
    }

    private static func grid<T>(_ values: [T], rows: Int, cols: Int) -> [[T]] {
        var result: [[T]] = []
        var index = 0
        for _ in 0..<rows {
            var row: [T] = []
            for _ in 0..<cols {
                row.append(values[index])
                index += 1
            }
            result.append(row)
        }
        return result
    }

    private static func flatGrid(_ grid: [[TileState]]) -> [TileState] {
        grid.flatMap { $0 }
    }

    // MARK: - 唯一对子

    private static func makeUniquePair(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        let cellCount = rows * cols

        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let pairType = pool[rngCopy.int(pool.count)]
        var others = pool.filter { $0 != pairType }
        others.shuffle(using: &rngCopy)
        let need = cellCount - 2
        let distinct = Array(others.prefix(need))

        // 平铺：前两个位置放对子，其余放互不相同的牌。
        var flat: [MahjongType] = [pairType, pairType] + distinct
        flat.shuffle(using: &rng)

        var stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)

        let pairPositions = positions(rows: rows, cols: cols).filter { stateGrid[$0.row][$0.col].type == pairType }

        let hints = [rule.hintText,
                     "The pair shares the same symbol.",
                     "Tap the two \(pairType.englishName) tiles."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .tapOrder(pairPositions),
                        hints: hints,
                        glowTargets: pairPositions,
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 唯一单牌

    private static func makeUniqueSingle(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        let cellCount = rows * cols

        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let counts = uniqueCounts(n: cellCount, rng: &rngCopy)
        var flat: [MahjongType] = []
        for (i, count) in counts.enumerated() {
            let tile: MahjongType
            if i == 0 {
                tile = pool[rngCopy.int(pool.count)]
            } else {
                var candidate = pool[rngCopy.int(pool.count)]
                while flat.contains(candidate) {
                    candidate = pool[rngCopy.int(pool.count)]
                }
                tile = candidate
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rngCopy)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let uniqueType = flat.frequency().first { $0.value == 1 }!.key
        let target = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == uniqueType }!

        let hints = [rule.hintText,
                     "Count the tiles. One symbol shows up only once.",
                     "Tap the \(uniqueType.englishName)."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .tapOrder([target]),
                        hints: hints,
                        glowTargets: [target],
                        rack: nil,
                        rng: &rng)
    }

    private static func uniqueCounts(n: Int, rng: inout SeededGenerator) -> [Int] {
        var counts: [Int] = [1]
        var remaining = n - 1
        if remaining % 2 == 1 {
            counts.append(3)
            remaining -= 3
        }
        while remaining > 0 {
            counts.append(2)
            remaining -= 2
        }
        return counts
    }

    // MARK: - 重复次数顺序

    private static func makeCountOrder(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        let cellCount = rows * cols

        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let counts = countPartition(n: cellCount)

        var flat: [MahjongType] = []
        for count in counts {
            var tile = pool[rngCopy.int(pool.count)]
            while flat.contains(tile) {
                tile = pool[rngCopy.int(pool.count)]
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rngCopy)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)

        // 按出现次数从多到少排列类型，得出点击顺序（每类点一张）。
        let freq = flat.frequency()
        let orderedTypes = freq.sorted { $0.value > $1.value }.map(\.key)
        let hint3 = orderedTypes.map { "\($0.englishName) (×\(freq[$0]!))" }.joined(separator: " → ")

        let hints = [rule.hintText,
                     "Tap one tile of each group, most frequent first.",
                     "Order: \(hint3)"]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .countOrder(orderedTypes),
                        hints: hints,
                        glowTargets: orderedTypes.prefix(1).flatMap { type in
                            positions(rows: rows, cols: cols).filter { stateGrid[$0.row][$0.col].type == type }
                        },
                        rack: nil,
                        rng: &rng)
    }

    /// 把 n 拆成互不相同的正整数（和为 n），用于重复次数分组。
    private static func countPartition(n: Int) -> [Int] {
        var parts: [Int] = []
        var acc = 0
        var v = 1
        while acc + v <= n {
            parts.append(v)
            acc += v
            v += 1
        }
        if parts.isEmpty {
            parts.append(n)
        } else {
            parts[parts.count - 1] += n - acc
        }
        return parts
    }

    // MARK: - 蛇形顺序

    private static func makeSequence(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let suit = [MahjongSuit.character, .bamboo, .dot][rngCopy.int(3)]
        let ranks = (1...9).map { rank -> MahjongType in
            switch suit {
            case .character: return .character(rank)
            case .bamboo: return .bamboo(rank)
            case .dot: return .dot(rank)
            default: return .character(rank)
            }
        }

        let snake = snakeOrder(rows: rows, cols: cols)
        var stateGrid = grid(ranks.map { TileState.face($0) }, rows: rows, cols: cols)

        // 把数字牌按蛇形摆放：第 i 个蛇形位置放 rank i+1。
        var index = 0
        for pos in snake {
            stateGrid[pos.row][pos.col] = TileState.face(ranks[index])
            index += 1
        }

        let hints = [rule.hintText,
                     "Start at one end of the winding path.",
                     "Tap 1, then 2, 3… up to 9."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .tapOrder(snake),
                        hints: hints,
                        glowTargets: [snake[0]],
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 缺失牌

    private static func makeMissing(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let suit = [MahjongSuit.character, .bamboo, .dot][rngCopy.int(3)]

        func tile(_ rank: Int) -> MahjongType {
            switch suit {
            case .character: return .character(rank)
            case .bamboo: return .bamboo(rank)
            case .dot: return .dot(rank)
            default: return .character(rank)
            }
        }

        // 行平移模式：cell = 1 + row + col。
        let missing = GridPos(row: 2, col: 2)
        let answer = tile(1 + missing.row + missing.col)

        var stateGrid: [[TileState]] = []
        for r in 0..<rows {
            var row: [TileState] = []
            for c in 0..<cols {
                let pos = GridPos(row: r, col: c)
                if pos == missing {
                    row.append(TileState.empty(type: answer))
                } else {
                    row.append(TileState.face(tile(1 + r + c)))
                }
            }
            stateGrid.append(row)
        }

        let rack = buildRack(answer: answer, rng: &rngCopy)
        let hints = [rule.hintText,
                     "Each cell grows by one going right and down.",
                     "Place the \(answer.englishName) in the gap."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .place([missing: answer]),
                        hints: hints,
                        glowTargets: [missing],
                        rack: rack,
                        rng: &rng)
    }

    private static func buildRack(answer: MahjongType, rng: inout SeededGenerator) -> [MahjongType] {
        var candidates = MahjongType.all.filter(\.isNumbered).filter { $0 != answer }
        candidates.shuffle(using: &rng)
        var rack = Array(candidates.prefix(5))
        rack.append(answer)
        rack.shuffle(using: &rng)
        return rack
    }

    // MARK: - 干扰项

    private static func makeDecoy(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let suits: [MahjongSuit] = [.character, .bamboo, .dot]
        let mainSuit = suits[rngCopy.int(suits.count)]
        var oddSuit = suits[rngCopy.int(suits.count)]
        while oddSuit == mainSuit {
            oddSuit = suits[rngCopy.int(suits.count)]
        }

        func tile(_ suit: MahjongSuit, _ rank: Int) -> MahjongType {
            switch suit {
            case .character: return .character(rank)
            case .bamboo: return .bamboo(rank)
            case .dot: return .dot(rank)
            default: return .character(rank)
            }
        }

        var flat: [MahjongType] = []
        for i in 0..<(rows * cols - 1) {
            flat.append(tile(mainSuit, 1 + i % 9))
        }
        let oddPos = GridPos(row: rngCopy.int(rows), col: rngCopy.int(cols))
        flat.insert(tile(oddSuit, 5), at: min(oddPos.row * cols + oddPos.col, flat.count))
        flat.shuffle(using: &rngCopy)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let oddType = tile(oddSuit, 5)
        let target = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == oddType }!

        let hints = [rule.hintText,
                     "Most tiles share the same suit. One doesn't.",
                     "Tap the \(oddType.englishName)."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .tapOrder([target]),
                        hints: hints,
                        glowTargets: [target],
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 旋转

    private static func makeRotation(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let flat = pool.shuffled(using: &rngCopy).prefix(rows * cols)

        let tilted = min(rows * cols, 3 + (level - 31) / 2)
        var rotations: [Int] = Array(repeating: 0, count: rows * cols)
        for i in 0..<tilted {
            rotations[i] = 1 + rngCopy.int(3)
        }
        rotations.shuffle(using: &rngCopy)

        var stateGrid: [[TileState]] = []
        var index = 0
        for r in 0..<rows {
            var row: [TileState] = []
            for _ in 0..<cols {
                row.append(TileState.face(flat[index], rotation: rotations[index]))
                index += 1
            }
            stateGrid.append(row)
        }

        let targetRotations = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        let tiltedPositions = positions(rows: rows, cols: cols).filter { stateGrid[$0.row][$0.col].rotation != 0 }
        let hints = [rule.hintText,
                     "Swipe a tile to spin it by 90°.",
                     "Rotate every tilted tile back to upright."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .rotateTo(targetRotations),
                        hints: hints,
                        glowTargets: tiltedPositions,
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 镜像

    private static func makeMirror(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let flat = pool.shuffled(using: &rngCopy).prefix(rows * cols)
        let initialGrid = grid(Array(flat).map { TileState.face($0) }, rows: rows, cols: cols)

        // 目标 = 每行水平镜像。
        let target: [[MahjongType]] = initialGrid.map { row in
            row.map { $0.type }.reversed()
        }

        let hints = [rule.hintText,
                     "Swap tiles so each row reads as its mirror.",
                     "Reflect every row left-to-right."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: initialGrid,
                        solution: .rearrange(target),
                        hints: hints,
                        glowTargets: [],
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 交换排序

    private static func makeSwap(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let suit = [MahjongSuit.character, .bamboo, .dot][rngCopy.int(3)]
        let ordered = (1...9).map { rank -> MahjongType in
            switch suit {
            case .character: return .character(rank)
            case .bamboo: return .bamboo(rank)
            case .dot: return .dot(rank)
            default: return .character(rank)
            }
        }
        let target = grid(ordered, rows: rows, cols: cols)

        // 初始 = 目标经过若干次随机交换打乱。
        var flat = ordered
        let swaps = 4 + rngCopy.int(3)
        for _ in 0..<swaps {
            let a = rngCopy.int(flat.count)
            let b = rngCopy.int(flat.count)
            flat.swapAt(a, b)
        }
        let initialGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)

        let hints = [rule.hintText,
                     "Arrange the tiles from 1 to 9, row by row.",
                     "Sort them back into ascending order."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: initialGrid,
                        solution: .rearrange(target),
                        hints: hints,
                        glowTargets: [],
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 指向中心

    private static func makeDirection(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)
        let flat = pool.shuffled(using: &rngCopy).prefix(rows * cols)

        let targetRotations: [[Int]] = (0..<rows).map { r in
            (0..<cols).map { c in requiredDirection(row: r, col: c, rows: rows, cols: cols) }
        }

        var stateGrid: [[TileState]] = []
        var index = 0
        for r in 0..<rows {
            var row: [TileState] = []
            for c in 0..<cols {
                var t = TileState.face(flat[index])
                t.showsArrow = true
                t.rotation = rngCopy.int(4)
                row.append(t)
                index += 1
            }
            stateGrid.append(row)
        }

        let hints = [rule.hintText,
                     "Each arrow should aim at the center tile.",
                     "Rotate every arrow to face the middle."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .rotateTo(targetRotations),
                        hints: hints,
                        glowTargets: positions(rows: rows, cols: cols).filter { $0 != GridPos(row: 1, col: 1) },
                        rack: nil,
                        rng: &rng)
    }

    private static func requiredDirection(row: Int, col: Int, rows: Int, cols: Int) -> Int {
        let cr = Double(rows - 1) / 2
        let cc = Double(cols - 1) / 2
        let dr = cr - Double(row)
        let dc = cc - Double(col)
        if abs(dr) < 0.001 && abs(dc) < 0.001 { return 0 }
        if abs(dr) >= abs(dc) {
            return dr > 0 ? 2 : 0
        } else {
            return dc > 0 ? 1 : 3
        }
    }

    // MARK: - 翻面

    private static func makeFlip(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let (rows, cols) = gridSize(level: level, rule: rule)
        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)

        let marks = BackMark.allCases
        let commonMark = marks[rngCopy.int(marks.count)]
        var oddMark = marks[rngCopy.int(marks.count)]
        while oddMark == commonMark {
            oddMark = marks[rngCopy.int(marks.count)]
        }

        let flat = pool.shuffled(using: &rngCopy).prefix(rows * cols)
        let oddIndex = rngCopy.int(rows * cols)

        var stateGrid: [[TileState]] = []
        var index = 0
        for r in 0..<rows {
            var row: [TileState] = []
            for _ in 0..<cols {
                let mark = index == oddIndex ? oddMark : commonMark
                row.append(TileState.back(flat[index], mark: mark))
                index += 1
            }
            stateGrid.append(row)
        }

        let oddPos = GridPos(row: oddIndex / cols, col: oddIndex % cols)
        let hints = [rule.hintText,
                     "Long-press a tile to look at its back.",
                     "Tap the tile showing a \(oddMark.englishName)."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .revealTarget(oddPos, oddMark),
                        hints: hints,
                        glowTargets: [oddPos],
                        rack: nil,
                        rng: &rng)
    }

    // MARK: - 替换

    private static func makeReplacement(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let suit = [MahjongSuit.character, .bamboo, .dot][rngCopy.int(3)]
        func tile(_ rank: Int) -> MahjongType {
            switch suit {
            case .character: return .character(rank)
            case .bamboo: return .bamboo(rank)
            case .dot: return .dot(rank)
            default: return .character(rank)
            }
        }

        let wrongPos = GridPos(row: 2, col: 2)
        let answer = tile(1 + wrongPos.row + wrongPos.col)
        var wrongType = tile(1 + wrongPos.row + wrongPos.col + 2)
        if wrongType == answer { wrongType = tile(1) }

        var stateGrid: [[TileState]] = []
        for r in 0..<rows {
            var row: [TileState] = []
            for c in 0..<cols {
                let pos = GridPos(row: r, col: c)
                if pos == wrongPos {
                    row.append(TileState.face(wrongType))
                } else {
                    row.append(TileState.face(tile(1 + r + c)))
                }
            }
            stateGrid.append(row)
        }

        let rack = buildRack(answer: answer, rng: &rngCopy)
        let hints = [rule.hintText,
                     "One tile doesn't fit the pattern. Swap it out.",
                     "Replace it with the \(answer.englishName)."]
        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .place([wrongPos: answer]),
                        hints: hints,
                        glowTargets: [wrongPos],
                        rack: rack,
                        rng: &rng)
    }

    // MARK: - 多步组合

    private static func makeMulti(level: Int, rule: RuleKind, rng: inout SeededGenerator) -> Puzzle {
        let rows = 3
        let cols = 3
        var rngCopy = rng
        let pool = numberedTiles(&rngCopy)

        // 第一步：找出唯一牌。
        let counts = uniqueCounts(n: rows * cols, rng: &rngCopy)
        var flat: [MahjongType] = []
        for (i, count) in counts.enumerated() {
            var tile = pool[rngCopy.int(pool.count)]
            while flat.contains(tile) {
                tile = pool[rngCopy.int(pool.count)]
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rngCopy)
        let uniqueType = flat.frequency().first { $0.value == 1 }!.key

        // 第二步：把某个位置的牌旋转到位。
        let rotatePos = GridPos(row: rngCopy.int(rows), col: rngCopy.int(cols))
        let rotateTarget = 0

        var stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let tapTarget = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == uniqueType }!
        var rotated = stateGrid[rotatePos.row][rotatePos.col]
        rotated.rotation = 1 + rngCopy.int(3)
        stateGrid[rotatePos.row][rotatePos.col] = rotated

        let steps: [PuzzleStep]
        let hints: [String]
        if level >= 91 {
            // 综合关卡：三步。
            let secondTarget = positions(rows: rows, cols: cols).first {
                $0 != tapTarget && stateGrid[$0.row][$0.col].type != uniqueType
            }!
            steps = [
                PuzzleStep(kind: .tap(tapTarget), hint: "Tap the \(uniqueType.englishName)."),
                PuzzleStep(kind: .rotate(rotatePos, to: rotateTarget), hint: "Rotate the \(stateGrid[rotatePos.row][rotatePos.col].type.englishName) upright."),
                PuzzleStep(kind: .tap(secondTarget), hint: "Tap any remaining tile.")
            ]
            hints = [rule.hintText,
                     "Complete each instruction in order.",
                     "Tap the \(uniqueType.englishName), then set the tilted tile upright."]
        } else {
            steps = [
                PuzzleStep(kind: .tap(tapTarget), hint: "Tap the \(uniqueType.englishName)."),
                PuzzleStep(kind: .rotate(rotatePos, to: rotateTarget), hint: "Rotate the \(stateGrid[rotatePos.row][rotatePos.col].type.englishName) upright.")
            ]
            hints = [rule.hintText,
                     "Do the two steps in order.",
                     "Tap the \(uniqueType.englishName), then set the tilted tile upright."]
        }

        rng = rngCopy
        return assemble(level: level, rule: rule, rows: rows, cols: cols,
                        grid: stateGrid,
                        solution: .multi(steps),
                        hints: hints,
                        glowTargets: [tapTarget],
                        rack: nil,
                        rng: &rng)
    }
}
