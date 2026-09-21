//
//  KitoIslandBarState.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// What the pill shows right now. Not a system Dynamic Island replacement —
/// iOS never lets a third-party app draw on or recolor the real notch/
/// Dynamic Island hardware chrome, only ActivityKit content *inside* it
/// (see KitoOrderTracking's Live Activity for that). This is an in-app
/// status pill positioned where the Island sits, for glanceable live status
/// (battery, upload/sync progress, a quick alert) without a full screen or
/// a toast — the "efficiency" case: one glance, no navigation.
public enum KitoIslandBarState: Equatable, Sendable {
    case hidden
    /// A single glyph, tinted `color` — "charging," "offline," "recording."
    case compact(systemImage: String, color: Color)
    /// A ring filling to `fraction` (0...1), with an optional short label —
    /// upload/download/sync progress, or battery level.
    case progress(fraction: Double, color: Color, label: String? = nil)
    /// A short title + optional message, for a brief alert that needs more
    /// than one glyph can say ("Low battery", "12% remaining").
    case expanded(title: String, message: String?, color: Color)
}
