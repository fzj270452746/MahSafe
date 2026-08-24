//
//  TileRack.swift
//  MahSafe
//
//  底部候选牌库：补牌 / 替换类谜题的备选牌。点一张牌触发 onPick。
//

import SpriteKit
import UIKit

final class TileRack: SKNode {

    var onPick: ((MahjongType) -> Void)?

    private var items: [(type: MahjongType, tile: MahjongTile)] = []
    private var tileSize: CGSize = .zero

    func layout(in rect: CGRect, rack: [MahjongType]) {
        removeAllChildren()
        items.removeAll()

        let count = rack.count
        guard count > 0 else { return }

        let gap: CGFloat = rect.width * 0.03
        let side = min((rect.width - gap * CGFloat(count - 1)) / CGFloat(count),
                       rect.height * 0.92)
        tileSize = CGSize(width: side, height: side)

        let totalWidth = side * CGFloat(count) + gap * CGFloat(count - 1)
        var x = rect.midX - totalWidth / 2 + side / 2

        for type in rack {
            let tile = MahjongTile(state: .face(type))
            tile.size = tileSize
            tile.layoutSubvisuals()
            tile.position = CGPoint(x: x, y: rect.midY)
            tile.zPosition = 1
            addChild(tile)
            items.append((type, tile))
            x += side + gap
        }
    }

    func target(at p: CGPoint) -> TapTarget? {
        for item in items {
            let half = tileSize.width / 2
            if abs(p.x - item.tile.position.x) <= half && abs(p.y - item.tile.position.y) <= half {
                return TapTarget(
                    action: { [weak self] in self?.onPick?(item.type) },
                    onPress: { item.tile.pulse() },
                    onRelease: nil
                )
            }
        }
        return nil
    }
}
