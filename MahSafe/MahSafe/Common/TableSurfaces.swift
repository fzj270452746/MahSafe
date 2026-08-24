//
//  TableSurfaces.swift
//  MahSafe
//
//  牌桌表面与金属零件的程序纹理。
//

import SpriteKit
import UIKit

enum TableSurfaces {

    /// 全屏牌桌背景：木色渐变、细网格、中心光晕与暗角。
    static func vaultBackground(size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            drawGradient(in: cg,
                         rect: rect,
                         colors: [Theme.backgroundTop, Theme.backgroundMiddle, Theme.backgroundBottom],
                         locations: [0, 0.48, 1])

            cg.setStrokeColor(Theme.brassPatina.withAlphaComponent(0.12).cgColor)
            cg.setLineWidth(0.7)
            let spacing = max(24, size.width * 0.075)
            var x: CGFloat = spacing * 0.5
            while x < size.width {
                cg.move(to: CGPoint(x: x, y: 0))
                cg.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var y: CGFloat = spacing * 0.5
            while y < size.height {
                cg.move(to: CGPoint(x: 0, y: y))
                cg.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            cg.strokePath()

            cg.setStrokeColor(Theme.brass.withAlphaComponent(0.10).cgColor)
            cg.setLineWidth(1)
            let diamondSide = size.width * 0.23
            for centerY in stride(from: size.height * 0.18,
                                  through: size.height * 0.92,
                                  by: size.height * 0.24) {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: size.width / 2, y: centerY - diamondSide / 2))
                path.addLine(to: CGPoint(x: size.width / 2 + diamondSide / 2, y: centerY))
                path.addLine(to: CGPoint(x: size.width / 2, y: centerY + diamondSide / 2))
                path.addLine(to: CGPoint(x: size.width / 2 - diamondSide / 2, y: centerY))
                path.closeSubpath()
                cg.addPath(path)
            }
            cg.strokePath()

            if let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [Theme.lacquerLight.withAlphaComponent(0.36).cgColor,
                                              UIColor.clear.cgColor] as CFArray,
                                     locations: [0, 1]) {
                cg.drawRadialGradient(glow,
                                      startCenter: CGPoint(x: rect.midX, y: size.height * 0.46),
                                      startRadius: 0,
                                      endCenter: CGPoint(x: rect.midX, y: size.height * 0.46),
                                      endRadius: size.width * 0.82,
                                      options: [.drawsAfterEndLocation])
            }

            if let vignette = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: [UIColor.clear.cgColor,
                                                  Theme.vignette.withAlphaComponent(0.82).cgColor] as CFArray,
                                         locations: [0.48, 1]) {
                cg.drawRadialGradient(vignette,
                                      startCenter: CGPoint(x: rect.midX, y: rect.midY),
                                      startRadius: 0,
                                      endCenter: CGPoint(x: rect.midX, y: rect.midY),
                                      endRadius: hypot(size.width, size.height) * 0.56,
                                      options: [.drawsAfterEndLocation])
            }
        }
        return SKTexture(image: image)
    }

    /// 圆角矩形垂直渐变纹理。
    static func rounded(size: CGSize,
                        top: UIColor,
                        bottom: UIColor,
                        radius: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
            cg.saveGState()
            cg.addPath(path)
            cg.clip()
            drawGradient(in: cg, rect: rect, colors: [top, bottom], locations: [0, 1])
            cg.restoreGState()

            cg.addPath(path)
            cg.setStrokeColor(top.blended(with: .white, amount: 0.22).withAlphaComponent(0.72).cgColor)
            cg.setLineWidth(1)
            cg.strokePath()

            let highlightRect = CGRect(x: radius * 0.7,
                                       y: 1,
                                       width: max(0, size.width - radius * 1.4),
                                       height: 1)
            cg.setFillColor(UIColor.white.withAlphaComponent(0.11).cgColor)
            cg.fill(highlightRect)
        }
        return SKTexture(image: image)
    }

    /// 深色金属面板。
    static func metal(size: CGSize, radius: CGFloat) -> SKTexture {
        rounded(size: size, top: Theme.metalLight, bottom: Theme.metalDark, radius: radius)
    }

    /// 保险箱外壳：多段金属渐变与磨砂刻线。
    static func vaultMetal(size: CGSize, radius: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
            cg.saveGState()
            cg.addPath(path)
            cg.clip()
            drawGradient(in: cg,
                         rect: rect,
                         colors: [Theme.metalEdge, Theme.metalMid, Theme.metalDark],
                         locations: [0, 0.28, 1])
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.035).cgColor)
            cg.setLineWidth(0.5)
            for offset in stride(from: CGFloat(5), to: size.height, by: CGFloat(6)) {
                cg.move(to: CGPoint(x: 0, y: offset))
                cg.addLine(to: CGPoint(x: size.width, y: offset + size.width * 0.025))
            }
            cg.strokePath()
            cg.restoreGState()

            cg.addPath(path)
            cg.setStrokeColor(Theme.brassDark.withAlphaComponent(0.9).cgColor)
            cg.setLineWidth(max(1.5, size.width * 0.008))
            cg.strokePath()
        }
        return SKTexture(image: image)
    }

    /// 黄铜面板。
    static func brass(size: CGSize, radius: CGFloat) -> SKTexture {
        rounded(size: size, top: Theme.brassLight, bottom: Theme.brassDark, radius: radius)
    }

    /// 内凹面板（比外框更暗，模拟保险箱内部）。
    static func recessed(size: CGSize, radius: CGFloat) -> SKTexture {
        rounded(size: size, top: Theme.lacquer, bottom: Theme.backgroundBottom, radius: radius)
    }

    /// 八角切角控制键，用于把普通按钮变成保险箱控制台元件。
    static func control(size: CGSize,
                        top: UIColor,
                        bottom: UIColor,
                        border: UIColor,
                        cut: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 1.5, dy: 1.5)
            let amount = min(cut, min(rect.width, rect.height) * 0.28)
            let path = cutCornerPath(in: rect, cut: amount)

            cg.saveGState()
            cg.addPath(path)
            cg.clip()
            drawGradient(in: cg, rect: rect, colors: [top, bottom], locations: [0, 1])

            cg.setFillColor(UIColor.white.withAlphaComponent(0.08).cgColor)
            cg.fill(CGRect(x: rect.minX + amount,
                           y: rect.minY + 1,
                           width: max(0, rect.width - amount * 2),
                           height: 1.2))
            cg.restoreGState()

            cg.addPath(path)
            cg.setStrokeColor(border.cgColor)
            cg.setLineWidth(1.5)
            cg.strokePath()
        }
        return SKTexture(image: image)
    }

    /// 面板描边辅助：给已有精灵加一圈浅色高光边。
    static func highlightStroke(size: CGSize, radius: CGFloat, color: UIColor, width: CGFloat) -> SKShapeNode {
        let node = SKShapeNode()
        node.path = CGPath(roundedRect: CGRect(origin: .zero, size: size),
                           cornerWidth: radius, cornerHeight: radius, transform: nil)
        node.strokeColor = color
        node.lineWidth = width
        node.fillColor = .clear
        return node
    }

    private static func drawGradient(in context: CGContext,
                                     rect: CGRect,
                                     colors: [UIColor],
                                     locations: [CGFloat]) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: colors.map(\.cgColor) as CFArray,
                                        locations: locations) else { return }
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: rect.midX, y: rect.minY),
                                   end: CGPoint(x: rect.midX, y: rect.maxY),
                                   options: [])
    }

    private static func cutCornerPath(in rect: CGRect, cut: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cut))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cut))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.closeSubpath()
        return path
    }
}
