//
//  BackMark.swift
//  MahSafe
//
//  麻将背面的隐藏记号，用于翻牌类谜题。
//

import Foundation

enum BackMark: Int, CaseIterable {
    case dot
    case ring
    case triangle
    case square
    case diamond
    case cross

    var englishName: String {
        switch self {
        case .dot: return "Dot"
        case .ring: return "Ring"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .diamond: return "Diamond"
        case .cross: return "Cross"
        }
    }
}
