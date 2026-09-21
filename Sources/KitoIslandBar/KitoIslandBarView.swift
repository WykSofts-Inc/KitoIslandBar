//
//  KitoIslandBarView.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// The pill itself — a capsule shaped and positioned like the Dynamic
/// Island, rendered by this app rather than the system. `color` on each
/// `KitoIslandBarState` case is exactly the customization point the name
/// implies: it's this pill's background, so "change its color" is just
/// choosing a different `Color` per state, no system API involved.
public struct KitoIslandBarView: View {
    let state: KitoIslandBarState

    public init(state: KitoIslandBarState) {
        self.state = state
    }

    public var body: some View {
        Group {
            switch state {
            case .hidden:
                Color.clear.frame(width: 0, height: 0)
            case .compact(let systemImage, let color):
                pill(color: color) {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
            case .progress(let fraction, let color, let label):
                pill(color: color) {
                    HStack(spacing: 6) {
                        KitoIslandRing(fraction: fraction)
                        if let label {
                            Text(label)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
            case .expanded(let title, let message, let color):
                pill(color: color) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                        if let message {
                            Text(message)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white.opacity(0.75))
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: state)
    }

    private func pill<Content: View>(color: Color, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(color, in: Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
    }
}

/// A small ring, matching the pill's compact scale — `KitoLoaders.
/// KitoProgressRing` is themed for full-size app content and shows a
/// percentage label by default; this needs a bare, tiny, always-white ring.
private struct KitoIslandRing: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.3), lineWidth: 2)
            Circle()
                .trim(from: 0, to: max(0, min(fraction, 1)))
                .stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 14, height: 14)
    }
}

public extension View {
    /// Positions a `KitoIslandBarView` where the Dynamic Island sits, over
    /// this view's safe area. Attach once near the app root.
    func kitoIslandBar(_ state: KitoIslandBarState) -> some View {
        overlay(alignment: .top) {
            KitoIslandBarView(state: state)
                .padding(.top, 11)
                .transition(.scale(scale: 0.6).combined(with: .opacity))
        }
    }
}
