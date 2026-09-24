//
//  KitoBatteryMonitor.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import Observation
import UIKit

/// Wraps `UIDevice`'s real battery APIs — the genuine "percentage" +
/// "efficiency" signal an island pill can show, not a simulated one.
/// Simulators report `batteryLevel == -1` (no hardware battery); `level`
/// surfaces that as `nil` rather than a nonsense negative percentage, and
/// `islandBarState()` returns `.hidden` in that case.
@Observable
@MainActor
public final class KitoBatteryMonitor {
    /// 0...1, or `nil` when the platform can't report a real value
    /// (every iOS Simulator, always).
    public private(set) var level: Double?
    public private(set) var state: UIDevice.BatteryState

    // `deinit` runs nonisolated even on a `@MainActor` class, so this can't
    // be actor-isolated storage — it's only ever touched from `init` (before
    // any other access is possible) and `deinit`, never concurrently.
    private nonisolated(unsafe) var observers: [NSObjectProtocol] = []

    public init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let rawLevel = UIDevice.current.batteryLevel
        self.level = rawLevel >= 0 ? Double(rawLevel) : nil
        self.state = UIDevice.current.batteryState

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            },
            center.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            },
        ]
    }

    deinit {
        let center = NotificationCenter.default
        for observer in observers { center.removeObserver(observer) }
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    private func refresh() {
        let rawLevel = UIDevice.current.batteryLevel
        level = rawLevel >= 0 ? Double(rawLevel) : nil
        state = UIDevice.current.batteryState
    }

    /// A ready-to-use `KitoIslandBarState.progress` for the current battery
    /// level — blue while charging/full, red at or below 20%, green
    /// otherwise. Returns `.hidden` where `level` is `nil` (no real
    /// hardware to report, e.g. every Simulator).
    public func islandBarState() -> KitoIslandBarState {
        guard let level else { return .hidden }
        let percent = Int((level * 100).rounded())
        let color: Color
        if state == .charging || state == .full {
            color = Color(red: 0.35, green: 0.75, blue: 1.0)
        } else if level <= 0.2 {
            color = Color(red: 1.0, green: 0.35, blue: 0.35)
        } else {
            color = Color(red: 0.35, green: 0.85, blue: 0.55)
        }
        return .progress(fraction: level, color: color, label: (Double(percent) / 100).formatted(.percent))
    }
}
