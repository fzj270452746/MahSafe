//
//  MahjongType.swift
//  MahSafe
//
//  麻将牌型：万 / 条 / 筒 / 风 / 箭，共 34 种。
//

import Foundation

enum MahjongSuit: String, CaseIterable {
    case character
    case bamboo
    case dot
    case wind
    case dragon

    var englishName: String {
        switch self {
        case .character: return "Characters"
        case .bamboo: return "Bamboo"
        case .dot: return "Dots"
        case .wind: return "Winds"
        case .dragon: return "Dragons"
        }
    }
}

enum MahjongType: Hashable {

    case character(Int)   // 1...9 万
    case bamboo(Int)      // 1...9 条
    case dot(Int)         // 1...9 筒
    case wind(Wind)
    case dragon(Dragon)

    enum Wind: Int, CaseIterable {
        case east, south, west, north
    }

    enum Dragon: Int, CaseIterable {
        case red, green, white
    }

    /// 全部 34 种牌，顺序稳定，供牌库与生成器取用。
    static let all: [MahjongType] = {
        var list: [MahjongType] = []
        list += (1...9).map { .character($0) }
        list += (1...9).map { .bamboo($0) }
        list += (1...9).map { .dot($0) }
        list += Wind.allCases.map { .wind($0) }
        list += Dragon.allCases.map { .dragon($0) }
        return list
    }()

    var suit: MahjongSuit {
        switch self {
        case .character: return .character
        case .bamboo: return .bamboo
        case .dot: return .dot
        case .wind: return .wind
        case .dragon: return .dragon
        }
    }

    var isHonor: Bool {
        suit == .wind || suit == .dragon
    }

    var isNumbered: Bool {
        !isHonor
    }

    /// 数字牌的 1...9 序号；字牌返回 nil。
    var rank: Int? {
        switch self {
        case .character(let n), .bamboo(let n), .dot(let n): return n
        default: return nil
        }
    }

    /// 渲染用的主符号。数字牌返回中文数字，字牌返回单字，白板返回空串。
    var symbolText: String {
        switch self {
        case .character(let n): return MahjongType.chineseNumeral(n)
        case .bamboo(let n): return MahjongType.chineseNumeral(n)
        case .dot(let n): return MahjongType.chineseNumeral(n)
        case .wind(let w):
            switch w {
            case .east: return "東"
            case .south: return "南"
            case .west: return "西"
            case .north: return "北"
            }
        case .dragon(let d):
            switch d {
            case .red: return "中"
            case .green: return "發"
            case .white: return ""
            }
        }
    }

    /// 用于提示文本的英文名，例如 "Three of Bamboo"、"East Wind"。
    var englishName: String {
        switch self {
        case .character(let n): return "\(MahjongType.ordinal(n)) of Characters"
        case .bamboo(let n): return "\(MahjongType.ordinal(n)) of Bamboo"
        case .dot(let n): return "\(MahjongType.ordinal(n)) of Dots"
        case .wind(let w):
            switch w {
            case .east: return "East Wind"
            case .south: return "South Wind"
            case .west: return "West Wind"
            case .north: return "North Wind"
            }
        case .dragon(let d):
            switch d {
            case .red: return "Red Dragon"
            case .green: return "Green Dragon"
            case .white: return "White Dragon"
            }
        }
    }

    /// 符号主体颜色（万=红，条=绿，筒=蓝，风=墨，箭按各自颜色）。
    var symbolColorName: String {
        switch self {
        case .character: return "red"
        case .bamboo: return "green"
        case .dot: return "blue"
        case .wind: return "ink"
        case .dragon(let d):
            switch d {
            case .red: return "red"
            case .green: return "green"
            case .white: return "ink"
            }
        }
    }

    static func chineseNumeral(_ n: Int) -> String {
        let map = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        guard n >= 1, n <= 9 else { return "" }
        return map[n]
    }

    static func ordinal(_ n: Int) -> String {
        let map = ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
        guard n >= 1, n <= 9 else { return "\(n)" }
        return map[n]
    }
}
