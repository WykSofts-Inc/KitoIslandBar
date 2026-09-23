//
//  KitoDynamicIslandTests.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
import SwiftUI
@testable import KitoIslandBar

final class KitoDynamicIslandTests: XCTestCase {
    func testDefaultMetricsMatchTheHardwareIsland() {
        let metrics = KitoIslandMetrics.dynamicIsland
        XCTAssertEqual(metrics.width, 126)
        XCTAssertEqual(metrics.height, 37.33, accuracy: 0.01)
        XCTAssertEqual(metrics.topOffset, 11.33, accuracy: 0.01)
    }

    func testCompactWidensByBothSides() {
        let metrics = KitoIslandMetrics(width: 126, compactSideWidth: 50)
        XCTAssertEqual(metrics.compactWidth, 226)
    }

    func testTheIslandFollowsEachModelsHardwarePosition() {
        let metrics = KitoIslandMetrics.dynamicIsland
        XCTAssertEqual(metrics.resolvedTopOffset(safeAreaTop: 59), 11, "iPhone 14 Pro")
        XCTAssertEqual(metrics.resolvedTopOffset(safeAreaTop: 62), 14, "iPhone 16 / 17 Pro")
        XCTAssertEqual(metrics.resolvedTopOffset(safeAreaTop: 47), metrics.topOffset, "a notch: no island to follow")
        XCTAssertEqual(metrics.resolvedTopOffset(safeAreaTop: 0), metrics.topOffset, "a preview with no safe area")
        var fixed = metrics
        fixed.followsHardwareIsland = false
        XCTAssertEqual(fixed.resolvedTopOffset(safeAreaTop: 62), metrics.topOffset)
    }

    func testTimesReadLikeThePlayer() {
        XCTAssertEqual(KitoScrubber.format(0), "0:00")
        XCTAssertEqual(KitoScrubber.format(187.9), "3:07")
        XCTAssertEqual(KitoScrubber.format(3727), "1:02:07")
    }

    func testThePausedWaveformIsFlat() {
        for bar in 0..<4 {
            XCTAssertEqual(KitoWaveform.level(bar: bar, time: 12.3, playing: false), 0.22)
        }
    }

    func testThePlayingWaveformStaysInRangeAndMoves() {
        var levels: Set<Int> = []
        for step in 0..<200 {
            let level = KitoWaveform.level(bar: step % 4, time: Double(step) * 0.05, playing: true)
            XCTAssertGreaterThanOrEqual(level, 0.2)
            XCTAssertLessThanOrEqual(level, 1.0001)
            levels.insert(Int(level * 10))
        }
        XCTAssertGreaterThan(levels.count, 4, "bars should move across their range")
    }

    func testTheTintComesFromTheArtworkUnlessOverridden() {
        let art = KitoNowPlayingArtwork.gradient([.pink, .purple], symbol: "music.note")
        XCTAssertEqual(art.tint, .pink)
        XCTAssertEqual(KitoNowPlayingItem(title: "T", artist: "A", artwork: art, duration: 200).resolvedTint, .pink)
        XCTAssertEqual(KitoNowPlayingItem(title: "T", artist: "A", artwork: art, duration: 200, tint: .green).resolvedTint, .green)
        XCTAssertEqual(KitoNowPlayingArtwork.asset("cover").tint, .white)
    }
}
