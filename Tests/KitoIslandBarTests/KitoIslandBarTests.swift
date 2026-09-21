//
//  KitoIslandBarTests.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoIslandBar

@MainActor
final class KitoIslandBarTests: XCTestCase {
    func testStateEquatability() {
        XCTAssertEqual(KitoIslandBarState.hidden, .hidden)
        XCTAssertEqual(
            KitoIslandBarState.compact(systemImage: "bolt.fill", color: .blue),
            .compact(systemImage: "bolt.fill", color: .blue)
        )
        XCTAssertNotEqual(
            KitoIslandBarState.compact(systemImage: "bolt.fill", color: .blue),
            .compact(systemImage: "bolt.fill", color: .red)
        )
    }

    func testProgressStateCarriesFractionColorAndOptionalLabel() {
        let state = KitoIslandBarState.progress(fraction: 0.42, color: .green, label: "42%")
        guard case .progress(let fraction, let color, let label) = state else {
            return XCTFail("expected .progress")
        }
        XCTAssertEqual(fraction, 0.42)
        XCTAssertEqual(color, .green)
        XCTAssertEqual(label, "42%")
    }

    func testExpandedStateMessageIsOptional() {
        let withMessage = KitoIslandBarState.expanded(title: "Low battery", message: "12% remaining", color: .red)
        let withoutMessage = KitoIslandBarState.expanded(title: "Charging", message: nil, color: .blue)
        guard case .expanded(_, let message1, _) = withMessage, case .expanded(_, let message2, _) = withoutMessage else {
            return XCTFail("expected .expanded")
        }
        XCTAssertEqual(message1, "12% remaining")
        XCTAssertNil(message2)
    }

    // MARK: KitoBatteryMonitor

    func testBatteryMonitorReturnsHiddenStateWhenLevelIsUnavailable() {
        // Every Simulator reports batteryLevel == -1 (no real hardware),
        // which `KitoBatteryMonitor` must surface as `nil`, not -100%.
        let monitor = KitoBatteryMonitor()
        if monitor.level == nil {
            XCTAssertEqual(monitor.islandBarState(), .hidden)
        } else {
            // A real device running this test suite does have a level —
            // just prove the state it produces is internally consistent.
            guard case .progress(let fraction, _, let label) = monitor.islandBarState() else {
                return XCTFail("expected .progress when level is known")
            }
            XCTAssertEqual(fraction, monitor.level!)
            XCTAssertNotNil(label)
        }
    }
}
