//
//  KitoDynamicIsland.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import UIKit

/// How much of the island is showing.
public enum KitoIslandPresentation: Equatable, Sendable {
    /// Just the island's resting shape. Black, over the hardware island, so it's invisible there.
    case idle
    /// Widened, with a little content either side of the camera: artwork and a waveform, a timer.
    case compact
    /// Grown into a large rounded panel with full controls.
    case expanded
}

/// The island's size and placement. The default matches the hardware Dynamic Island on iPhone 14
/// Pro and later, so the idle shape sits exactly on top of it and every change looks like the
/// real island growing.
public struct KitoIslandMetrics: Equatable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    /// Distance from the top of the screen.
    public var topOffset: CGFloat
    /// Gap to the screen edges when expanded.
    public var expandedInset: CGFloat
    public var expandedCornerRadius: CGFloat
    /// Room for leading and trailing compact content, either side of the camera.
    public var compactSideWidth: CGFloat
    /// Line the island up with the hardware island by reading the top safe area (the island's
    /// offset differs between models). Off, or with no safe area, `topOffset` is used as is.
    public var followsHardwareIsland: Bool

    public init(width: CGFloat = 126, height: CGFloat = 37.33, topOffset: CGFloat = 11.33, expandedInset: CGFloat = 10,
                expandedCornerRadius: CGFloat = 46, compactSideWidth: CGFloat = 52, followsHardwareIsland: Bool = true) {
        self.width = width
        self.height = height
        self.topOffset = topOffset
        self.expandedInset = expandedInset
        self.expandedCornerRadius = expandedCornerRadius
        self.compactSideWidth = compactSideWidth
        self.followsHardwareIsland = followsHardwareIsland
    }

    public static let dynamicIsland = KitoIslandMetrics()

    /// The width when compact.
    public var compactWidth: CGFloat { width + compactSideWidth * 2 }

    /// Where the island's top edge goes for a given top safe area. Island iPhones put the island
    /// about 48pt above the safe area (11.33pt down on a 14 Pro, 14pt on a 16 or 17 Pro).
    public func resolvedTopOffset(safeAreaTop: CGFloat) -> CGFloat {
        guard followsHardwareIsland, safeAreaTop >= 58 else { return topOffset }
        return safeAreaTop - 48
    }
}

/// An in-app Dynamic Island: one black shape that springs between idle, compact and expanded,
/// with its content blurring in and out as it changes. Tap it to expand; tap outside or swipe it
/// up to collapse back to compact.
///
/// This is drawn by the app, not the system: iOS doesn't let apps resize the real island. Placed
/// over the hardware island (the default metrics), it reads as the island itself growing.
public struct KitoDynamicIsland<Leading: View, Trailing: View, Expanded: View>: View {
    @Binding var presentation: KitoIslandPresentation
    let metrics: KitoIslandMetrics
    let background: Color
    let availableWidth: CGFloat
    let tapToExpand: Bool
    let leading: () -> Leading
    let trailing: () -> Trailing
    let expanded: () -> Expanded

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        presentation: Binding<KitoIslandPresentation>,
        availableWidth: CGFloat,
        metrics: KitoIslandMetrics = .dynamicIsland,
        background: Color = .black,
        tapToExpand: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder expanded: @escaping () -> Expanded
    ) {
        _presentation = presentation
        self.availableWidth = availableWidth
        self.metrics = metrics
        self.background = background
        self.tapToExpand = tapToExpand
        self.leading = leading
        self.trailing = trailing
        self.expanded = expanded
    }

    private var cornerRadius: CGFloat {
        presentation == .expanded ? metrics.expandedCornerRadius : metrics.height / 2
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    /// Bouncy like the real island; critically damped with Reduce Motion.
    static func spring(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: 0.25) : .spring(response: 0.46, dampingFraction: 0.7, blendDuration: 0.1)
    }

    public var body: some View {
        content
            .background(shape.fill(background))
            .clipShape(shape)
            .shadow(color: .black.opacity(presentation == .expanded ? 0.35 : 0), radius: 24, y: 10)
            .contentShape(shape)
            .onTapGesture {
                guard tapToExpand, presentation == .compact else { return }
                presentation = .expanded
            }
            .gesture(
                DragGesture(minimumDistance: 12).onEnded { drag in
                    guard presentation == .expanded, drag.translation.height < -24 else { return }
                    presentation = .compact
                }
            )
            .animation(Self.spring(reduceMotion: reduceMotion), value: presentation)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(presentation == .compact && tapToExpand ? .isButton : [])
            .accessibilityHint(presentation == .compact && tapToExpand ? "Expands the activity" : "")
    }

    @ViewBuilder
    private var content: some View {
        switch presentation {
        case .idle:
            Color.clear.frame(width: metrics.width, height: metrics.height)
        case .compact:
            HStack(spacing: 0) {
                leading()
                    .frame(width: metrics.compactSideWidth, alignment: .leading)
                    .padding(.leading, 12)
                Spacer(minLength: metrics.width - 24)
                trailing()
                    .frame(width: metrics.compactSideWidth, alignment: .trailing)
                    .padding(.trailing, 12)
            }
            .frame(width: metrics.compactWidth, height: metrics.height)
            .transition(.blurReplace)
        case .expanded:
            expanded()
                .padding(.horizontal, 22)
                // Start below the hardware island so nothing sits under the camera.
                .padding(.top, metrics.height + 6)
                .padding(.bottom, 20)
                .frame(width: max(availableWidth - metrics.expandedInset * 2, metrics.compactWidth))
                .transition(.blurReplace)
        }
    }
}

public extension View {
    /// Pins a `KitoDynamicIsland` over the top of this view, where the hardware island sits.
    /// Attach it to a full-screen container (it ignores the top safe area). While expanded, a tap
    /// anywhere else collapses it to compact.
    func kitoDynamicIsland<Leading: View, Trailing: View, Expanded: View>(
        presentation: Binding<KitoIslandPresentation>,
        metrics: KitoIslandMetrics = .dynamicIsland,
        background: Color = .black,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder expanded: @escaping () -> Expanded
    ) -> some View {
        overlay {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    if presentation.wrappedValue == .expanded {
                        Color.black.opacity(0.001)
                            .onTapGesture { presentation.wrappedValue = .compact }
                            .accessibilityHidden(true)
                    }
                    KitoDynamicIsland(
                        presentation: presentation, availableWidth: geometry.size.width, metrics: metrics, background: background,
                        leading: leading, trailing: trailing, expanded: expanded
                    )
                    .padding(.top, metrics.resolvedTopOffset(safeAreaTop: IslandScreen.safeAreaTop(for: geometry)))
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            }
            .ignoresSafeArea()
        }
    }
}

/// The top safe area that decides where the hardware island is. A container that ignores the
/// safe area reports zero, so when the island is pinned to the top of the screen, ask the window.
/// Anywhere else (a preview inside a scroll view) there's no hardware island to line up with.
@MainActor
enum IslandScreen {
    static func safeAreaTop(for geometry: GeometryProxy) -> CGFloat {
        if geometry.safeAreaInsets.top > 0 { return geometry.safeAreaInsets.top }
        guard abs(geometry.frame(in: .global).minY) < 1 else { return 0 }
        return windowSafeAreaTop
    }

    static var windowSafeAreaTop: CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let window = scenes.flatMap(\.windows).first { $0.isKeyWindow } ?? scenes.first?.windows.first
        return window?.safeAreaInsets.top ?? 0
    }
}
