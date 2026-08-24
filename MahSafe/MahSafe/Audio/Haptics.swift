//
//  Haptics.swift
//  MahSafe
//
//  触觉反馈。所有震动走 UIFeedbackGenerator，集中管理避免散落。
//

import UIKit

enum Haptics {

    static func tap() {
        guard SaveManager.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func rotate() {
        guard SaveManager.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func flip() {
        guard SaveManager.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func wrong() {
        guard SaveManager.hapticEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func correct() {
        guard SaveManager.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func bolt() {
        guard SaveManager.hapticEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    static func success() {
        guard SaveManager.hapticEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
