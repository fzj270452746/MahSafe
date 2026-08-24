//
//  RuleKind.swift
//  MahSafe
//
//  谜题规则分类。family 决定玩家如何操作、何时判定答案。
//

import Foundation

/// 交互范型：它决定一套规则走「即时判定」还是「拉把手统一判定」。
enum InteractionFamily {
    case tapOrder     // 按顺序点击
    case rearrange    // 交换到目标排列，拉把手判定
    case rotateTo     // 旋转到目标方向，拉把手判定
    case reveal       // 翻面探查，点击目标牌即时判定
    case place        // 从牌库补牌，即时判定
    case multi        // 多步组合
}

enum RuleKind: String, CaseIterable {
    case dailyCipher

    case uniqueSingle
    case uniquePair
    case decoy
    case countOrder
    case sequence

    case mirror
    case swap

    case rotation
    case direction

    case flip
    case missing
    case replacement

    case multi

    var family: InteractionFamily {
        switch self {
        case .dailyCipher, .uniqueSingle, .uniquePair, .decoy, .countOrder, .sequence:
            return .tapOrder
        case .mirror, .swap:
            return .rearrange
        case .rotation, .direction:
            return .rotateTo
        case .flip:
            return .reveal
        case .missing, .replacement:
            return .place
        case .multi:
            return .multi
        }
    }

    /// 提示第一级：点破规律类型。
    var hintText: String {
        switch self {
        case .dailyCipher:
            return "Rows count by ±1.\nTap each break in any order."
        case .uniqueSingle:
            return "Only one tile appears exactly once. Find it."
        case .uniquePair:
            return "Only one pair of identical tiles exists. Tap both."
        case .decoy:
            return "One tile breaks the pattern. Find the impostor."
        case .countOrder:
            return "Count each tile group.\nTap one tile per group, most frequent first."
        case .sequence:
            return "The tiles form a sequence. Follow the winding path."
        case .mirror:
            return "The safe must show its own mirror image. Swap tiles to match it."
        case .swap:
            return "Swap tiles until the arrangement matches the hidden order."
        case .rotation:
            return "Every tile must stand upright. Rotate the tilted ones."
        case .direction:
            return "Point every tile toward the center of the board."
        case .flip:
            return "Flip tiles to reveal their backs. Find the odd one."
        case .missing:
            return "One tile is missing. Complete the pattern."
        case .replacement:
            return "One tile is wrong. Replace it with the correct one."
        case .multi:
            return "Several rules chain together. Solve them in order."
        }
    }

    /// 章节展示用短标题。
    var shortTitle: String {
        switch self {
        case .dailyCipher: return "Four-Band Cipher"
        case .uniqueSingle: return "The Lone Tile"
        case .uniquePair: return "The Only Pair"
        case .decoy: return "The Impostor"
        case .countOrder: return "Count & Click"
        case .sequence: return "Winding Path"
        case .mirror: return "Mirror Image"
        case .swap: return "The Shuffle"
        case .rotation: return "Set Upright"
        case .direction: return "Point Inward"
        case .flip: return "Hidden Marks"
        case .missing: return "The Gap"
        case .replacement: return "The Substitute"
        case .multi: return "The Chain"
        }
    }
}
