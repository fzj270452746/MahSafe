//
//  Layout.swift
//  MahSafe
//
//  屏幕分区：Top HUD 15% / Safe 65% / Bottom Controls 20%。
//  所有尺寸都从 scene.size 与安全区动态推导，不写死任何机型。
//

import CoreGraphics
import UIKit

struct LayoutMetrics {
    let sceneSize: CGSize
    let safeArea: UIEdgeInsets

    var width: CGFloat { sceneSize.width }
    var height: CGFloat { sceneSize.height }
    var centerX: CGFloat { sceneSize.width / 2 }

    /// 顶部 HUD 区域（关卡标题 / 提示 / 计时）。
    var hudRect: CGRect {
        let top = safeArea.top
        let h = sceneSize.height * 0.14
        return CGRect(x: 0, y: sceneSize.height - top - h, width: sceneSize.width, height: h)
    }

    /// 保险箱占据的中央区域。
    var safeRect: CGRect {
        let topInset = safeArea.top + sceneSize.height * 0.14
        let bottomInset = safeArea.bottom + sceneSize.height * 0.20
        let h = max(sceneSize.height - topInset - bottomInset, sceneSize.height * 0.5)
        return CGRect(x: sceneSize.width * 0.05,
                      y: bottomInset,
                      width: sceneSize.width * 0.90,
                      height: h)
    }

    /// 底部操作区。
    var controlsRect: CGRect {
        CGRect(x: 0, y: safeArea.bottom, width: sceneSize.width, height: sceneSize.height * 0.20)
    }

    /// 保险箱主体（外框）保持接近正方形，居中于 safeRect。
    var safeBodyRect: CGRect {
        let side = min(safeRect.width, safeRect.height * 0.98)
        let x = safeRect.midX - side / 2
        let y = safeRect.midY - side / 2
        return CGRect(x: x, y: y, width: side, height: side)
    }

    /// 把手 / 锁等底部元件高度参考。
    var handleZoneHeight: CGFloat {
        safeBodyRect.height * 0.16
    }
}

extension LayoutMetrics {
    /// 依据麻将网格行列数，在保险箱内板里计算牌面尺寸与间距。
    func tileGeometry(rows: Int, cols: Int, in boardRect: CGRect) -> (tileSize: CGSize, gap: CGFloat) {
        guard rows > 0, cols > 0 else { return (.zero, 0) }
        let padding = boardRect.width * 0.06
        let usableW = boardRect.width - padding * 2
        let usableH = boardRect.height - padding * 2
        let gap = min(usableW, usableH) * 0.045
        let tileW = (usableW - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let tileH = (usableH - gap * CGFloat(rows - 1)) / CGFloat(rows)
        let side = min(tileW, tileH)
        return (CGSize(width: side, height: side), gap)
    }
}
