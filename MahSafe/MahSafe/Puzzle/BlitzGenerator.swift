//
//  BlitzGenerator.swift
//  MahSafe
//
//  一分钟快局的随机牌桌生成器。
//  与战役的 PuzzleGenerator 完全独立：不映射任何固定关卡，按「难度 + 种子」
//  现场生成全新挑战，但复用同一套 RuleKind / Puzzle / RuleEngine 判定。
//

import Foundation

enum BlitzGenerator {

    static func makeChallenge(difficulty: Int, seed: UInt64) -> Puzzle {
        var rng = SeededGenerator(seed: seed &* 0x9E37_79B9 &+ 0x51ED_270B)
        let rule = blitzRule(difficulty: difficulty, rng: &rng)
        let (rows, cols) = blitzGridSize(rule: rule, difficulty: difficulty)

        switch rule {
        case .uniquePair: return makeUniquePair(rows: rows, cols: cols, rng: &rng)
        case .uniqueSingle: return makeUniqueSingle(rows: rows, cols: cols, rng: &rng)
        case .decoy: return makeDecoy(rows: rows, cols: cols, rng: &rng)
        case .countOrder: return makeCountOrder(rows: rows, cols: cols, rng: &rng)
        case .sequence: return makeSequence(rng: &rng)
        case .missing: return makeMissing(rng: &rng)
        case .replacement: return makeReplacement(rng: &rng)
        case .swap: return makeSwap(rng: &rng)
        case .rotation: return makeRotation(rows: rows, cols: cols, difficulty: difficulty, rng: &rng)
        case .mirror: return makeMirror(rows: rows, cols: cols, rng: &rng)
        case .direction: return makeDirection(rng: &rng)
        case .flip: return makeFlip(rows: rows, cols: cols, rng: &rng)
        case .multi: return makeMulti(rng: &rng)
        case .dailyCipher: return makeUniqueSingle(rows: 3, cols: 3, rng: &rng)
        }
    }

    // MARK: - 难度 → 规则 / 网格

    /// 难度分层：前期只用可秒答的点选规则，逐步开放全部 13 种规则。
    private static func blitzRule(difficulty: Int, rng: inout SeededGenerator) -> RuleKind {
        var pool: [RuleKind] = [.uniquePair, .uniqueSingle, .decoy]
        if difficulty >= 3 { pool += [.countOrder, .sequence, .missing, .replacement, .swap] }
        if difficulty >= 7 { pool += [.rotation, .mirror, .direction, .flip, .multi] }
        return pool[rng.int(pool.count)]
    }

    private static func blitzGridSize(rule: RuleKind, difficulty: Int) -> (rows: Int, cols: Int) {
        switch rule {
        case .uniquePair, .uniqueSingle, .countOrder, .decoy:
            if difficulty < 3 { return (2, 2) }
            if difficulty >= 10 { return (4, 3) }
            return (3, 3)
        case .rotation, .mirror:
            return difficulty >= 9 ? (4, 3) : (3, 3)
        default:
            return (3, 3)
        }
    }

    // MARK: - 组装

    private static func assemble(rule: RuleKind,
                                 rows: Int,
                                 cols: Int,
                                 grid: [[TileState]],
                                 solution: PuzzleSolution,
                                 hints: [String],
                                 glowTargets: [GridPos],
                                 rack: [MahjongType]?) -> Puzzle {
        Puzzle(level: 0,
               chapter: 0,
               rule: rule,
               rows: rows,
               cols: cols,
               grid: grid,
               solution: solution,
               timeLimit: nil,
               parTimes: nil,
               hints: hints,
               hintGlowTargets: glowTargets,
               rack: rack)
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
            let cs = r % 2 == 0 ? Array(0..<cols) : Array((0..<cols).reversed())
            for c in cs { list.append(GridPos(row: r, col: c)) }
        }
        return list
    }

    private static func numberedTile(_ suit: MahjongSuit, _ rank: Int) -> MahjongType {
        switch suit {
        case .character: return .character(rank)
        case .bamboo: return .bamboo(rank)
        case .dot: return .dot(rank)
        case .wind, .dragon: return .character(rank)
        }
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

    private static func buildRack(answer: MahjongType, rng: inout SeededGenerator) -> [MahjongType] {
        var candidates = MahjongType.all.filter(\.isNumbered).filter { $0 != answer }
        candidates.shuffle(using: &rng)
        var rack = Array(candidates.prefix(5))
        rack.append(answer)
        rack.shuffle(using: &rng)
        return rack
    }

    private static func uniqueCounts(n: Int) -> [Int] {
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

    private static func numberedPool() -> [MahjongType] {
        MahjongType.all.filter(\.isNumbered)
    }

    // MARK: - 唯一对子

    private static func makeUniquePair(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let cellCount = rows * cols
        let pool = numberedPool()
        let pairType = pool[rng.int(pool.count)]
        var others = pool.filter { $0 != pairType }
        others.shuffle(using: &rng)
        let need = cellCount - 2
        let distinct = Array(others.prefix(need))

        var flat: [MahjongType] = [pairType, pairType] + distinct
        flat.shuffle(using: &rng)
        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let pairPositions = positions(rows: rows, cols: cols).filter { stateGrid[$0.row][$0.col].type == pairType }

        let hints = [RuleKind.uniquePair.hintText,
                     "The pair shares the same symbol.",
                     "Tap the two \(pairType.englishName) tiles."]
        return assemble(rule: .uniquePair, rows: rows, cols: cols, grid: stateGrid,
                        solution: .tapOrder(pairPositions), hints: hints,
                        glowTargets: pairPositions, rack: nil)
    }

    // MARK: - 唯一单牌

    private static func makeUniqueSingle(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let cellCount = rows * cols
        let pool = numberedPool()
        let counts = uniqueCounts(n: cellCount)
        var flat: [MahjongType] = []
        for (i, count) in counts.enumerated() {
            let tile: MahjongType
            if i == 0 {
                tile = pool[rng.int(pool.count)]
            } else {
                var candidate = pool[rng.int(pool.count)]
                while flat.contains(candidate) {
                    candidate = pool[rng.int(pool.count)]
                }
                tile = candidate
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rng)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let uniqueType = flat.frequency().first { $0.value == 1 }!.key
        let target = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == uniqueType }!

        let hints = [RuleKind.uniqueSingle.hintText,
                     "Count the tiles. One symbol shows up only once.",
                     "Tap the \(uniqueType.englishName)."]
        return assemble(rule: .uniqueSingle, rows: rows, cols: cols, grid: stateGrid,
                        solution: .tapOrder([target]), hints: hints,
                        glowTargets: [target], rack: nil)
    }

    // MARK: - 干扰项

    private static func makeDecoy(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let suits: [MahjongSuit] = [.character, .bamboo, .dot]
        let mainSuit = suits[rng.int(suits.count)]
        var oddSuit = suits[rng.int(suits.count)]
        while oddSuit == mainSuit { oddSuit = suits[rng.int(suits.count)] }

        var flat: [MahjongType] = []
        for i in 0..<(rows * cols - 1) {
            flat.append(numberedTile(mainSuit, 1 + i % 9))
        }
        let oddPos = GridPos(row: rng.int(rows), col: rng.int(cols))
        flat.insert(numberedTile(oddSuit, 5), at: min(oddPos.row * cols + oddPos.col, flat.count))
        flat.shuffle(using: &rng)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let oddType = numberedTile(oddSuit, 5)
        let target = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == oddType }!

        let hints = [RuleKind.decoy.hintText,
                     "Most tiles share the same suit. One doesn't.",
                     "Tap the \(oddType.englishName)."]
        return assemble(rule: .decoy, rows: rows, cols: cols, grid: stateGrid,
                        solution: .tapOrder([target]), hints: hints,
                        glowTargets: [target], rack: nil)
    }

    // MARK: - 重复次数顺序

    private static func makeCountOrder(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let cellCount = rows * cols
        let pool = numberedPool()
        let counts = countPartition(n: cellCount)

        var flat: [MahjongType] = []
        for count in counts {
            var tile = pool[rng.int(pool.count)]
            while flat.contains(tile) {
                tile = pool[rng.int(pool.count)]
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rng)

        let stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let freq = flat.frequency()
        let orderedTypes = freq.sorted { $0.value > $1.value }.map(\.key)
        let hint3 = orderedTypes.map { "\($0.englishName) (×\(freq[$0]!))" }.joined(separator: " → ")

        let hints = [RuleKind.countOrder.hintText,
                     "Tap one tile of each group, most frequent first.",
                     "Order: \(hint3)"]
        return assemble(rule: .countOrder, rows: rows, cols: cols, grid: stateGrid,
                        solution: .countOrder(orderedTypes), hints: hints,
                        glowTargets: orderedTypes.prefix(1).flatMap { type in
                            positions(rows: rows, cols: cols).filter { stateGrid[$0.row][$0.col].type == type }
                        },
                        rack: nil)
    }

    // MARK: - 蛇形顺序

    private static func makeSequence(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let suit = [MahjongSuit.character, .bamboo, .dot][rng.int(3)]
        let ranks = (1...9).map { numberedTile(suit, $0) }
        let snake = snakeOrder(rows: rows, cols: cols)

        var stateGrid = grid(ranks.map { TileState.face($0) }, rows: rows, cols: cols)
        var index = 0
        for pos in snake {
            stateGrid[pos.row][pos.col] = TileState.face(ranks[index])
            index += 1
        }

        let hints = [RuleKind.sequence.hintText,
                     "Start at one end of the winding path.",
                     "Tap 1, then 2, 3… up to 9."]
        return assemble(rule: .sequence, rows: rows, cols: cols, grid: stateGrid,
                        solution: .tapOrder(snake), hints: hints,
                        glowTargets: [snake[0]], rack: nil)
    }

    // MARK: - 缺失牌

    private static func makeMissing(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let suit = [MahjongSuit.character, .bamboo, .dot][rng.int(3)]
        let missing = GridPos(row: 2, col: 2)
        let answer = numberedTile(suit, 1 + missing.row + missing.col)

        var stateGrid: [[TileState]] = []
        for r in 0..<rows {
            var row: [TileState] = []
            for c in 0..<cols {
                let pos = GridPos(row: r, col: c)
                if pos == missing {
                    row.append(TileState.empty(type: answer))
                } else {
                    row.append(TileState.face(numberedTile(suit, 1 + r + c)))
                }
            }
            stateGrid.append(row)
        }

        let rack = buildRack(answer: answer, rng: &rng)
        let hints = [RuleKind.missing.hintText,
                     "Each cell grows by one going right and down.",
                     "Place the \(answer.englishName) in the gap."]
        return assemble(rule: .missing, rows: rows, cols: cols, grid: stateGrid,
                        solution: .place([missing: answer]), hints: hints,
                        glowTargets: [missing], rack: rack)
    }

    // MARK: - 替换

    private static func makeReplacement(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let suit = [MahjongSuit.character, .bamboo, .dot][rng.int(3)]
        let wrongPos = GridPos(row: 2, col: 2)
        let answer = numberedTile(suit, 1 + wrongPos.row + wrongPos.col)
        var wrongType = numberedTile(suit, 1 + wrongPos.row + wrongPos.col + 2)
        if wrongType == answer { wrongType = numberedTile(suit, 1) }

        var stateGrid: [[TileState]] = []
        for r in 0..<rows {
            var row: [TileState] = []
            for c in 0..<cols {
                let pos = GridPos(row: r, col: c)
                if pos == wrongPos {
                    row.append(TileState.face(wrongType))
                } else {
                    row.append(TileState.face(numberedTile(suit, 1 + r + c)))
                }
            }
            stateGrid.append(row)
        }

        let rack = buildRack(answer: answer, rng: &rng)
        let hints = [RuleKind.replacement.hintText,
                     "One tile doesn't fit the pattern. Swap it out.",
                     "Replace it with the \(answer.englishName)."]
        return assemble(rule: .replacement, rows: rows, cols: cols, grid: stateGrid,
                        solution: .place([wrongPos: answer]), hints: hints,
                        glowTargets: [wrongPos], rack: rack)
    }

    // MARK: - 交换排序

    private static func makeSwap(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let suit = [MahjongSuit.character, .bamboo, .dot][rng.int(3)]
        let ordered = (1...9).map { numberedTile(suit, $0) }
        let target = grid(ordered, rows: rows, cols: cols)

        var flat = ordered
        let swaps = 4 + rng.int(3)
        for _ in 0..<swaps {
            let a = rng.int(flat.count)
            let b = rng.int(flat.count)
            flat.swapAt(a, b)
        }
        let initialGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)

        let hints = [RuleKind.swap.hintText,
                     "Arrange the tiles from 1 to 9, row by row.",
                     "Sort them back into ascending order."]
        return assemble(rule: .swap, rows: rows, cols: cols, grid: initialGrid,
                        solution: .rearrange(target), hints: hints,
                        glowTargets: [], rack: nil)
    }

    // MARK: - 旋转

    private static func makeRotation(rows: Int, cols: Int, difficulty: Int, rng: inout SeededGenerator) -> Puzzle {
        let pool = numberedPool()
        let flat = pool.shuffled(using: &rng).prefix(rows * cols)

        let tilted = min(rows * cols, difficulty >= 9 ? 4 : 3)
        var rotations: [Int] = Array(repeating: 0, count: rows * cols)
        for i in 0..<tilted {
            rotations[i] = 1 + rng.int(3)
        }
        rotations.shuffle(using: &rng)

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
        let hints = [RuleKind.rotation.hintText,
                     "Swipe a tile to spin it by 90°.",
                     "Rotate every tilted tile back to upright."]
        return assemble(rule: .rotation, rows: rows, cols: cols, grid: stateGrid,
                        solution: .rotateTo(targetRotations), hints: hints,
                        glowTargets: tiltedPositions, rack: nil)
    }

    // MARK: - 镜像

    private static func makeMirror(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let pool = numberedPool()
        let flat = pool.shuffled(using: &rng).prefix(rows * cols)
        let initialGrid = grid(Array(flat).map { TileState.face($0) }, rows: rows, cols: cols)
        let target: [[MahjongType]] = initialGrid.map { row in row.map { $0.type }.reversed() }

        let hints = [RuleKind.mirror.hintText,
                     "Swap tiles so each row reads as its mirror.",
                     "Reflect every row left-to-right."]
        return assemble(rule: .mirror, rows: rows, cols: cols, grid: initialGrid,
                        solution: .rearrange(target), hints: hints,
                        glowTargets: [], rack: nil)
    }

    // MARK: - 指向中心

    private static func makeDirection(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let pool = numberedPool()
        let flat = pool.shuffled(using: &rng).prefix(rows * cols)

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
                t.rotation = rng.int(4)
                row.append(t)
                index += 1
            }
            stateGrid.append(row)
        }

        let hints = [RuleKind.direction.hintText,
                     "Each arrow should aim at the center tile.",
                     "Rotate every arrow to face the middle."]
        return assemble(rule: .direction, rows: rows, cols: cols, grid: stateGrid,
                        solution: .rotateTo(targetRotations), hints: hints,
                        glowTargets: positions(rows: rows, cols: cols).filter { $0 != GridPos(row: 1, col: 1) },
                        rack: nil)
    }

    // MARK: - 翻面

    private static func makeFlip(rows: Int, cols: Int, rng: inout SeededGenerator) -> Puzzle {
        let pool = numberedPool()
        let marks = BackMark.allCases
        let commonMark = marks[rng.int(marks.count)]
        var oddMark = marks[rng.int(marks.count)]
        while oddMark == commonMark { oddMark = marks[rng.int(marks.count)] }

        let flat = pool.shuffled(using: &rng).prefix(rows * cols)
        let oddIndex = rng.int(rows * cols)

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
        let hints = [RuleKind.flip.hintText,
                     "Long-press a tile to look at its back.",
                     "Tap the tile showing a \(oddMark.englishName)."]
        return assemble(rule: .flip, rows: rows, cols: cols, grid: stateGrid,
                        solution: .revealTarget(oddPos, oddMark), hints: hints,
                        glowTargets: [oddPos], rack: nil)
    }

    // MARK: - 多步组合

    private static func makeMulti(rng: inout SeededGenerator) -> Puzzle {
        let rows = 3, cols = 3
        let pool = numberedPool()

        // 第一步：找出唯一牌。
        let counts = uniqueCounts(n: rows * cols)
        var flat: [MahjongType] = []
        for (i, count) in counts.enumerated() {
            var tile = pool[rng.int(pool.count)]
            while flat.contains(tile) {
                tile = pool[rng.int(pool.count)]
            }
            flat += Array(repeating: tile, count: count)
        }
        flat.shuffle(using: &rng)
        let uniqueType = flat.frequency().first { $0.value == 1 }!.key

        // 第二步：把某个位置的牌旋转到位。
        let rotatePos = GridPos(row: rng.int(rows), col: rng.int(cols))
        let rotateTarget = 0

        var stateGrid = grid(flat.map { TileState.face($0) }, rows: rows, cols: cols)
        let tapTarget = positions(rows: rows, cols: cols).first { stateGrid[$0.row][$0.col].type == uniqueType }!
        var rotated = stateGrid[rotatePos.row][rotatePos.col]
        rotated.rotation = 1 + rng.int(3)
        stateGrid[rotatePos.row][rotatePos.col] = rotated

        let steps = [
            PuzzleStep(kind: .tap(tapTarget), hint: "Tap the \(uniqueType.englishName)."),
            PuzzleStep(kind: .rotate(rotatePos, to: rotateTarget), hint: "Rotate the \(stateGrid[rotatePos.row][rotatePos.col].type.englishName) upright.")
        ]
        let hints = [RuleKind.multi.hintText,
                     "Do the two steps in order.",
                     "Tap the \(uniqueType.englishName), then set the tilted tile upright."]

        return assemble(rule: .multi, rows: rows, cols: cols, grid: stateGrid,
                        solution: .multi(steps), hints: hints,
                        glowTargets: [tapTarget], rack: nil)
    }
}
