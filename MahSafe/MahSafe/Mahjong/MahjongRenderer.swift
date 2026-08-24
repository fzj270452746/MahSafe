//
//  MahjongRenderer.swift
//  MahSafe
//
//  全部麻将视觉都在这里用 CoreGraphics 程序化绘制，
//  产出 UIImage 再转 SKTexture 缓存。零外部图片资源。
//

import SpriteKit
import UIKit

final class MahjongRenderer {

    private static var frontCache: [MahjongType: SKTexture] = [:]
    private static var backCache: [BackMark: SKTexture] = [:]
    private static let logicalSide: CGFloat = 256

    // MARK: - 对外接口

    static func texture(for type: MahjongType) -> SKTexture {
        if let cached = frontCache[type] { return cached }
        let texture = SKTexture(image: renderFront(type))
        frontCache[type] = texture
        return texture
    }

    static func backTexture(for mark: BackMark) -> SKTexture {
        if let cached = backCache[mark] { return cached }
        let texture = SKTexture(image: renderBack(mark))
        backCache[mark] = texture
        return texture
    }

    /// 空槽占位纹理（缺失牌谜题里露出的凹槽）。
    static func emptySlotTexture() -> SKTexture {
        SKTexture(image: renderEmptySlot())
    }

    /// 无记号的纯色牌背（正常对局里牌不会翻面，仅防御性兜底）。
    static func plainBackTexture() -> SKTexture {
        SKTexture(image: renderPlainBack())
    }

    /// 柔和的径向发光纹理，用于选中与提示高亮。
    static func glowTexture(color: UIColor) -> SKTexture {
        let side: CGFloat = 128
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let center = CGPoint(x: side / 2, y: side / 2)
            let colors = [color.withAlphaComponent(0.55).cgColor,
                          color.withAlphaComponent(0.0).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors,
                                         locations: [0, 1]) {
                cg.drawRadialGradient(gradient,
                                      startCenter: center, startRadius: 0,
                                      endCenter: center, endRadius: side / 2,
                                      options: [])
            }
        }
        return SKTexture(image: image)
    }

    /// 预热全部 34 种牌与 6 种背面的纹理，避免对局中首帧卡顿。
    static func warmCache() {
        for type in MahjongType.all { _ = texture(for: type) }
        for mark in BackMark.allCases { _ = backTexture(for: mark) }
    }

    // MARK: - 位图入口

    private static func renderFront(_ type: MahjongType) -> UIImage {
        let side = logicalSide
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            drawBody(cg, rect: rect, face: .front)
            drawSymbol(cg, type: type, in: rect)
        }
    }

    private static func renderBack(_ mark: BackMark) -> UIImage {
        let side = logicalSide
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            drawBody(cg, rect: rect, face: .back)
            drawBackMark(cg, mark: mark, in: rect)
        }
    }

    private static func renderEmptySlot() -> UIImage {
        let side = logicalSide
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            drawEmptySlotBody(cg, rect: rect)
        }
    }

    private static func renderPlainBack() -> UIImage {
        let side = logicalSide
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: side, height: side)
            drawBody(cg, rect: rect, face: .back)
        }
    }

    // MARK: - 牌体

    private enum Face {
        case front
        case back
    }

    /// 画牌体：投影 + 侧边厚度 + 象牙面 + 倒角高光 + 内框。
    private static func drawBody(_ cg: CGContext, rect: CGRect, face: Face) {
        let side = rect.width
        let radius = side * 0.12
        let thickness = side * 0.045
        let faceRect = rect.insetBy(dx: side * 0.035, dy: side * 0.035)
        let facePath = UIBezierPath(roundedRect: faceRect, cornerRadius: radius).cgPath

        // 投影：向下偏移并柔化。
        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -side * 0.04),
                     blur: side * 0.06,
                     color: UIColor.black.withAlphaComponent(0.45).cgColor)
        cg.setFillColor(Theme.tileEdge.cgColor)
        cg.addPath(facePath)
        cg.fillPath()
        cg.restoreGState()

        // 侧边厚度：叠加多层略暗的圆角矩形，做出立体底面。
        for i in 0..<3 {
            let offset = CGFloat(i + 1) * thickness / 3
            let sideRect = faceRect.offsetBy(dx: 0, dy: -offset)
            let sidePath = UIBezierPath(roundedRect: sideRect, cornerRadius: radius).cgPath
            let shade = UIColor.black.withAlphaComponent(0.10 + 0.05 * CGFloat(i))
            cg.setFillColor(shade.cgColor)
            cg.addPath(sidePath)
            cg.fillPath()
        }

        // 面底色渐变。
        let topColor: UIColor
        let bottomColor: UIColor
        if face == .front {
            topColor = Theme.tileIvoryLight
            bottomColor = Theme.tileIvory
        } else {
            topColor = Theme.tileBack
            bottomColor = Theme.tileBack.blended(with: .black, amount: 0.3)
        }
        drawGradient(cg, path: facePath, colors: [topColor, bottomColor])

        // 倒角高光：面内再叠一层顶部亮边。
        cg.saveGState()
        let highlightPath = UIBezierPath(roundedRect: faceRect.insetBy(dx: side * 0.015, dy: side * 0.015),
                                         cornerRadius: radius * 0.8).cgPath
        cg.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        cg.setLineWidth(side * 0.012)
        cg.addPath(highlightPath)
        cg.strokePath()
        cg.restoreGState()

        // 内框细线。
        let innerRect = faceRect.insetBy(dx: side * 0.055, dy: side * 0.055)
        let innerPath = UIBezierPath(roundedRect: innerRect, cornerRadius: radius * 0.7).cgPath
        cg.setStrokeColor(face == .front ? Theme.tileEdge.withAlphaComponent(0.6).cgColor
                                         : UIColor.white.withAlphaComponent(0.18).cgColor)
        cg.setLineWidth(side * 0.008)
        cg.addPath(innerPath)
        cg.strokePath()
    }

    private static func drawEmptySlotBody(_ cg: CGContext, rect: CGRect) {
        let side = rect.width
        let radius = side * 0.12
        let faceRect = rect.insetBy(dx: side * 0.05, dy: side * 0.05)
        let path = UIBezierPath(roundedRect: faceRect, cornerRadius: radius).cgPath

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -side * 0.02),
                     blur: side * 0.03,
                     color: UIColor.black.withAlphaComponent(0.35).cgColor)
        cg.setFillColor(Theme.metalDark.cgColor)
        cg.addPath(path)
        cg.fillPath()
        cg.restoreGState()

        cg.setStrokeColor(Theme.metalLight.cgColor)
        cg.setLineWidth(side * 0.012)
        cg.addPath(path)
        cg.strokePath()
    }

    private static func drawGradient(_ cg: CGContext, path: CGPath, colors: [UIColor]) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors.map(\.cgColor) as CFArray,
                                        locations: [0, 1]) else { return }
        cg.saveGState()
        cg.addPath(path)
        cg.clip()
        let bounds = path.boundingBox
        cg.drawLinearGradient(gradient,
                              start: CGPoint(x: bounds.midX, y: bounds.maxY),
                              end: CGPoint(x: bounds.midX, y: bounds.minY),
                              options: [])
        cg.restoreGState()
    }

    // MARK: - 符号分派

    private static func drawSymbol(_ cg: CGContext, type: MahjongType, in rect: CGRect) {
        switch type {
        case .character(let n): drawCharacter(cg, number: n, in: rect)
        case .bamboo(let n): drawBamboo(cg, number: n, in: rect)
        case .dot(let n): drawDots(cg, number: n, in: rect)
        case .wind(let w): drawWind(cg, wind: w, in: rect)
        case .dragon(let d): drawDragon(cg, dragon: d, in: rect)
        }
    }

    // 万：中文数字 + 下方小「萬」。
    private static func drawCharacter(_ cg: CGContext, number: Int, in rect: CGRect) {
        let color = Theme.symbolRed
        let numeral = MahjongType.chineseNumeral(number)
        let numeralRect = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.34,
                                 width: rect.width, height: rect.height * 0.40)
        drawCenteredText(numeral, in: numeralRect, color: color, fontSize: rect.width * 0.36)

        let wanRect = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.10,
                             width: rect.width, height: rect.height * 0.20)
        drawCenteredText("萬", in: wanRect, color: color, fontSize: rect.width * 0.18)
    }

    // 条：按点数布局画竖长竹条。
    private static func drawBamboo(_ cg: CGContext, number: Int, in rect: CGRect) {
        let positions = pipCenters(number)
        let barWidth = rect.width * 0.16
        let barHeight = rect.height * 0.34
        let color = Theme.symbolGreen
        let dark = color.blended(with: .black, amount: 0.35)

        for pos in positions {
            let cx = rect.minX + pos.x * rect.width
            let cy = rect.minY + pos.y * rect.height
            let bar = CGRect(x: cx - barWidth / 2, y: cy - barHeight / 2,
                             width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: bar, cornerRadius: barWidth / 2).cgPath
            drawGradient(cg, path: path, colors: [color.blended(with: .white, amount: 0.2), dark])
            cg.setStrokeColor(dark.cgColor)
            cg.setLineWidth(rect.width * 0.008)
            cg.addPath(path)
            cg.strokePath()
        }
    }

    // 筒：按点数布局画圆。
    private static func drawDots(_ cg: CGContext, number: Int, in rect: CGRect) {
        let positions = pipCenters(number)
        let diameter = rect.width * 0.22
        let color = Theme.symbolBlue
        let dark = color.blended(with: .black, amount: 0.3)

        for pos in positions {
            let cx = rect.minX + pos.x * rect.width
            let cy = rect.minY + pos.y * rect.height
            let circle = CGRect(x: cx - diameter / 2, y: cy - diameter / 2,
                                width: diameter, height: diameter)
            let path = UIBezierPath(ovalIn: circle).cgPath
            drawGradient(cg, path: path, colors: [color.blended(with: .white, amount: 0.25), dark])
            cg.setStrokeColor(dark.cgColor)
            cg.setLineWidth(rect.width * 0.01)
            cg.addPath(path)
            cg.strokePath()
        }
    }

    // 风：单个汉字居中。
    private static func drawWind(_ cg: CGContext, wind: MahjongType.Wind, in rect: CGRect) {
        let text: String
        switch wind {
        case .east: text = "東"
        case .south: text = "南"
        case .west: text = "西"
        case .north: text = "北"
        }
        let box = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.18,
                         width: rect.width, height: rect.height * 0.64)
        drawCenteredText(text, in: box, color: Theme.symbolInk, fontSize: rect.width * 0.48)
    }

    // 箭牌：中 / 發 / 白板空框。
    private static func drawDragon(_ cg: CGContext, dragon: MahjongType.Dragon, in rect: CGRect) {
        switch dragon {
        case .red:
            let box = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.20,
                             width: rect.width, height: rect.height * 0.60)
            drawCenteredText("中", in: box, color: Theme.symbolRed, fontSize: rect.width * 0.46)
        case .green:
            let box = CGRect(x: rect.minX, y: rect.minY + rect.height * 0.20,
                             width: rect.width, height: rect.height * 0.60)
            drawCenteredText("發", in: box, color: Theme.symbolGreen, fontSize: rect.width * 0.46)
        case .white:
            // 白板：只画一个蓝框，无字。
            let frameRect = rect.insetBy(dx: rect.width * 0.20, dy: rect.height * 0.20)
            let path = UIBezierPath(roundedRect: frameRect, cornerRadius: rect.width * 0.04).cgPath
            cg.setStrokeColor(Theme.symbolBlue.cgColor)
            cg.setLineWidth(rect.width * 0.022)
            cg.addPath(path)
            cg.strokePath()
        }
    }

    // MARK: - 背面记号

    private static func drawBackMark(_ cg: CGContext, mark: BackMark, in rect: CGRect) {
        let color = UIColor.white.withAlphaComponent(0.92)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width * 0.18

        cg.setFillColor(color.cgColor)
        cg.setStrokeColor(color.cgColor)
        cg.setLineWidth(rect.width * 0.02)

        switch mark {
        case .dot:
            cg.fillEllipse(in: CGRect(x: center.x - r * 0.5, y: center.y - r * 0.5, width: r, height: r))
        case .ring:
            cg.strokeEllipse(in: CGRect(x: center.x - r * 0.7, y: center.y - r * 0.7, width: r * 1.4, height: r * 1.4))
        case .triangle:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y + r))
            path.addLine(to: CGPoint(x: center.x - r, y: center.y - r * 0.7))
            path.addLine(to: CGPoint(x: center.x + r, y: center.y - r * 0.7))
            path.closeSubpath()
            cg.addPath(path)
            cg.fillPath()
        case .square:
            cg.fill(CGRect(x: center.x - r * 0.7, y: center.y - r * 0.7, width: r * 1.4, height: r * 1.4))
        case .diamond:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y + r))
            path.addLine(to: CGPoint(x: center.x + r, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y - r))
            path.addLine(to: CGPoint(x: center.x - r, y: center.y))
            path.closeSubpath()
            cg.addPath(path)
            cg.fillPath()
        case .cross:
            let arm = r * 0.75
            let w = rect.width * 0.10
            cg.fill(CGRect(x: center.x - w / 2, y: center.y - arm, width: w, height: arm * 2))
            cg.fill(CGRect(x: center.x - arm, y: center.y - w / 2, width: arm * 2, height: w))
        }
    }

    // MARK: - 文本辅助

    private static func drawCenteredText(_ text: String, in rect: CGRect, color: UIColor, fontSize: CGFloat) {
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let measured = (text as NSString).size(withAttributes: attributes)
        let origin = CGPoint(x: rect.midX - measured.width / 2,
                             y: rect.midY - measured.height / 2)
        (text as NSString).draw(at: origin, withAttributes: attributes)
    }

    // MARK: - 点数布局

    /// 1...9 的骰点式布局，坐标归一化到 0...1。
    private static func pipCenters(_ count: Int) -> [CGPoint] {
        let grid: [(CGFloat, CGFloat)] = [
            (0.25, 0.75), (0.5, 0.75), (0.75, 0.75),
            (0.25, 0.5), (0.5, 0.5), (0.75, 0.5),
            (0.25, 0.25), (0.5, 0.25), (0.75, 0.25)
        ]
        let patterns: [[Int]] = [
            [],
            [4],
            [0, 8],
            [0, 4, 8],
            [0, 2, 6, 8],
            [0, 2, 4, 6, 8],
            [0, 2, 3, 5, 6, 8],
            [0, 1, 2, 4, 6, 7, 8],
            [0, 1, 2, 3, 5, 6, 7, 8],
            [0, 1, 2, 3, 4, 5, 6, 7, 8]
        ]
        let index = min(max(count, 0), 9)
        return patterns[index].map { CGPoint(x: grid[$0].0, y: grid[$0].1) }
    }
}
