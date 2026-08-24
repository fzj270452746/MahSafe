//
//  Theme.swift
//  MahSafe
//
//  夜场麻将馆的材质样本：茶黑木桌、旧铜、朱漆与牌骨白。
//

import UIKit

enum Theme {

    // 茶黑木桌，而不是常见的蓝黑科技渐变。
    static let backgroundTop = UIColor(hex: 0x231A16)
    static let backgroundMiddle = UIColor(hex: 0x121513)
    static let backgroundBottom = UIColor(hex: 0x080A09)
    static let vignette = UIColor(hex: 0x000000)

    // 金属层次
    static let metalDark = UIColor(hex: 0x171A18)
    static let metalMid = UIColor(hex: 0x292D29)
    static let metalLight = UIColor(hex: 0x41483F)
    static let metalEdge = UIColor(hex: 0x6C7669)
    static let lacquer = UIColor(hex: 0x4A211D)
    static let lacquerLight = UIColor(hex: 0x773229)

    // 黄铜 / 金色
    static let brass = UIColor(hex: 0xA98249)
    static let brassDark = UIColor(hex: 0x5B4127)
    static let brassLight = UIColor(hex: 0xD7B879)
    static let brassShine = UIColor(hex: 0xF0D9A0)
    static let brassPatina = UIColor(hex: 0x4F7469)

    // 麻将牌面
    static let tileIvory = UIColor(hex: 0xEEE7D2)
    static let tileIvoryLight = UIColor(hex: 0xFFF9E8)
    static let tileIvoryShadow = UIColor(hex: 0xBDB29A)
    static let tileEdge = UIColor(hex: 0x776C58)
    static let tileBack = UIColor(hex: 0x1E624B)

    // 麻将符号配色
    static let symbolRed = UIColor(hex: 0xB9322A)
    static let symbolGreen = UIColor(hex: 0x1F714A)
    static let symbolBlue = UIColor(hex: 0x28577A)
    static let symbolInk = UIColor(hex: 0x202724)

    // 文字
    static let textLight = UIColor(hex: 0xF0E7D3)
    static let textDim = UIColor(hex: 0xA79C8B)
    static let textGold = UIColor(hex: 0xD3AE69)
    static let textDark = UIColor(hex: 0x17201D)

    // 状态
    static let success = UIColor(hex: 0x58C995)
    static let warning = UIColor(hex: 0xE0A44B)
    static let danger = UIColor(hex: 0xD54A3F)
    static let cinnabar = UIColor(hex: 0xA82E27)

    // 选中 / 发光
    static let selectionGlow = UIColor(hex: 0xFFE092)
    static let hintGlow = UIColor(hex: 0x77D8B0)

    // 门内暖光
    static let innerLight = UIColor(hex: 0xF3C976)
    static let innerLightCore = UIColor(hex: 0xFFF1C4)

    // 玻璃 / 暗色面板
    static let panel = UIColor(hex: 0x171511).withAlphaComponent(0.94)
    static let panelRaised = UIColor(hex: 0x29231C).withAlphaComponent(0.96)
    static let panelBorder = UIColor(hex: 0x665747)

    // 标题带一点旧账簿气质，正文保持小屏可读性。
    static let displayFont = "Didot-Bold"
    static let headingFont = "AvenirNext-DemiBold"
    static let bodyFont = "AvenirNext-Regular"
}

extension UIColor {
    /// 0xRRGGBB 十六进制构造，alpha 默认 1。
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// 在自身与目标颜色之间做线性插值，t 取值 0...1。
    func blended(with other: UIColor, amount t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = min(max(t, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * k,
                       green: g1 + (g2 - g1) * k,
                       blue: b1 + (b2 - b1) * k,
                       alpha: a1 + (a2 - a1) * k)
    }
}
