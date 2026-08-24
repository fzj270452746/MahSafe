//
//  Utilities.swift
//  MahSafe
//
//  确定性随机、几何与格式化等通用工具。
//

import CoreGraphics
import Foundation

/// SplitMix64 确定性随机数生成器。
/// 关卡生成依赖它：相同的 seed 永远产出相同谜题。
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension SeededGenerator {
    /// 生成 [0, upperBound) 内的整数。
    mutating func int(_ upperBound: Int) -> Int {
        guard upperBound > 0 else { return 0 }
        return Int(next() % UInt64(upperBound))
    }

    /// 生成 [lower, upper] 闭区间整数。
    mutating func int(_ lower: Int, _ upper: Int) -> Int {
        guard upper >= lower else { return lower }
        let span = UInt64(upper - lower + 1)
        return lower + Int(next() % span)
    }

    /// 生成 [0, 1) 的浮点数。
    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func bool(chance: Double = 0.5) -> Bool {
        unit() < chance
    }

    /// 从数组中随机挑一个元素；空数组返回 nil。
    mutating func pick<T>(from array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[int(array.count)]
    }

    /// 从数组中随机抽取 count 个互不相同的元素。
    mutating func sample<T>(_ count: Int, from array: [T]) -> [T] {
        guard count > 0, !array.isEmpty else { return [] }
        var pool = array
        pool.shuffle(using: &self)
        return Array(pool.prefix(min(count, pool.count)))
    }
}

enum Format {
    /// 把秒格式化成 "MM:SS"，超过一小时退化成分钟数。
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let m = total / 60
        let s = total % 60
        if m >= 100 {
            return String(format: "%d:%02d", m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

/// 把角度换算为 0...3 的四分之一旋转步数（90° 一档）。
func rotationSteps(degrees: CGFloat) -> Int {
    var d = Int(degrees.rounded() / 90) % 4
    if d < 0 { d += 4 }
    return d
}

/// 把旋转步数换算为弧度。
func radians(steps: Int) -> CGFloat {
    CGFloat(steps) * .pi / 2
}
