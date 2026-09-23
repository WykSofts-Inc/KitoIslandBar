//
//  KitoNowPlaying.swift
//  KitoIslandBar
//
//  Created by Wycliff on 9/23/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

/// Album art for the Now Playing island.
public enum KitoNowPlayingArtwork: Equatable, Sendable {
    /// A gradient tile with a symbol: handy when there's no image yet.
    case gradient([Color], symbol: String)
    case asset(String)
    case url(URL)

    /// The colour the waveform and scrubber pick up, like the system player tinting from the art.
    public var tint: Color {
        if case .gradient(let colors, _) = self, let first = colors.first { return first }
        return .white
    }
}

public struct KitoNowPlayingItem: Equatable, Sendable, Identifiable {
    public var id: String { "\(title)|\(artist)" }
    public var title: String
    public var artist: String
    public var artwork: KitoNowPlayingArtwork
    public var duration: TimeInterval
    /// Overrides the tint taken from the artwork.
    public var tint: Color?

    public init(title: String, artist: String, artwork: KitoNowPlayingArtwork, duration: TimeInterval, tint: Color? = nil) {
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.duration = duration
        self.tint = tint
    }

    var resolvedTint: Color { tint ?? artwork.tint }
}

public extension View {
    /// A music player in the island, like Apple Music's: artwork and a live waveform when
    /// compact; artwork, title, a draggable scrubber and back / play-pause / forward when expanded.
    func kitoNowPlayingIsland(
        presentation: Binding<KitoIslandPresentation>,
        item: KitoNowPlayingItem,
        isPlaying: Binding<Bool>,
        elapsed: Binding<TimeInterval>,
        metrics: KitoIslandMetrics = .dynamicIsland,
        onPrevious: @escaping () -> Void = {},
        onNext: @escaping () -> Void = {}
    ) -> some View {
        kitoDynamicIsland(presentation: presentation, metrics: metrics) {
            KitoNowPlayingArtworkView(artwork: item.artwork, cornerRadius: 7).frame(width: 26, height: 26)
        } trailing: {
            KitoWaveform(isPlaying: isPlaying.wrappedValue, tint: item.resolvedTint).frame(width: 24, height: 16)
        } expanded: {
            KitoNowPlayingExpanded(item: item, isPlaying: isPlaying, elapsed: elapsed, onPrevious: onPrevious, onNext: onNext)
        }
    }
}

/// The expanded Now Playing panel. Public so it can be placed inside a custom island or a card.
public struct KitoNowPlayingExpanded: View {
    let item: KitoNowPlayingItem
    @Binding var isPlaying: Bool
    @Binding var elapsed: TimeInterval
    let onPrevious: () -> Void
    let onNext: () -> Void

    public init(item: KitoNowPlayingItem, isPlaying: Binding<Bool>, elapsed: Binding<TimeInterval>, onPrevious: @escaping () -> Void = {}, onNext: @escaping () -> Void = {}) {
        self.item = item
        _isPlaying = isPlaying
        _elapsed = elapsed
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    public var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                KitoNowPlayingArtworkView(artwork: item.artwork, cornerRadius: 12)
                    .frame(width: 56, height: 56)
                    .scaleEffect(isPlaying ? 1 : 0.9)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPlaying)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).font(.subheadline.weight(.semibold)).foregroundStyle(.white).lineLimit(1)
                    Text(item.artist).font(.subheadline).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
                Spacer(minLength: 8)
                KitoWaveform(isPlaying: isPlaying, tint: item.resolvedTint).frame(width: 30, height: 22)
            }

            KitoScrubber(elapsed: $elapsed, duration: item.duration, tint: .white)

            HStack {
                Spacer()
                controlButton("backward.fill", size: 24, label: "Previous", action: onPrevious)
                Spacer()
                controlButton(isPlaying ? "pause.fill" : "play.fill", size: 34, label: isPlaying ? "Pause" : "Play") { isPlaying.toggle() }
                    .contentTransition(.symbolEffect(.replace))
                Spacer()
                controlButton("forward.fill", size: 24, label: "Next", action: onNext)
                Spacer()
            }
            .foregroundStyle(.white)
        }
    }

    private func controlButton(_ symbol: String, size: CGFloat, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 54, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(IslandPressStyle())
        .accessibilityLabel(label)
    }
}

/// A draggable progress track with elapsed and remaining time, like the system player's.
public struct KitoScrubber: View {
    @Binding var elapsed: TimeInterval
    let duration: TimeInterval
    let tint: Color

    @State private var isDragging = false

    public init(elapsed: Binding<TimeInterval>, duration: TimeInterval, tint: Color = .white) {
        _elapsed = elapsed
        self.duration = duration
        self.tint = tint
    }

    private var fraction: Double { duration > 0 ? min(max(elapsed / duration, 0), 1) : 0 }

    public var body: some View {
        HStack(spacing: 10) {
            Text(Self.format(elapsed)).frame(width: 40, alignment: .leading)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.25))
                    Capsule().fill(tint).frame(width: max(geometry.size.width * fraction, isDragging ? 8 : 5))
                }
                .frame(height: isDragging ? 10 : 6)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            isDragging = true
                            elapsed = min(max(drag.location.x / max(geometry.size.width, 1), 0), 1) * duration
                        }
                        .onEnded { _ in isDragging = false }
                )
            }
            .frame(height: 20)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
            Text("-" + Self.format(max(duration - elapsed, 0))).frame(width: 44, alignment: .trailing)
        }
        .font(.caption2.monospacedDigit().weight(.medium))
        .foregroundStyle(.white.opacity(0.55))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Playback position")
        .accessibilityValue("\(Self.format(elapsed)) of \(Self.format(duration))")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: elapsed = min(elapsed + 10, duration)
            case .decrement: elapsed = max(elapsed - 10, 0)
            @unknown default: break
            }
        }
    }

    /// "3:07", or "1:02:07" past an hour.
    static func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let hours = total / 3600, minutes = (total % 3600) / 60, secs = total % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, secs) : String(format: "%d:%02d", minutes, secs)
    }
}

/// Live equaliser bars. They settle flat when paused, and hold still with Reduce Motion.
public struct KitoWaveform: View {
    let isPlaying: Bool
    let tint: Color
    let barCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isPlaying: Bool, tint: Color = .white, barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.tint = tint
        self.barCount = barCount
    }

    public var body: some View {
        TimelineView(.animation(paused: !isPlaying || reduceMotion)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geometry in
                HStack(alignment: .center, spacing: geometry.size.width * 0.12) {
                    ForEach(0..<barCount, id: \.self) { index in
                        Capsule()
                            .fill(tint)
                            .frame(height: geometry.size.height * Self.level(bar: index, time: time, playing: isPlaying && !reduceMotion))
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isPlaying)
        .accessibilityHidden(true)
    }

    /// 0.2...1: a few out-of-phase sines per bar, so it reads as music rather than a metronome.
    static func level(bar: Int, time: TimeInterval, playing: Bool) -> CGFloat {
        guard playing else { return 0.22 }
        let b = Double(bar)
        let wave = sin(time * (5.1 + b * 1.7) + b * 1.3) * 0.5 + sin(time * (8.3 + b * 0.9) + b) * 0.3 + sin(time * 2.2 + b * 2.1) * 0.2
        return CGFloat(0.2 + (wave * 0.5 + 0.5) * 0.8)
    }
}

/// Album art in any of its forms.
public struct KitoNowPlayingArtworkView: View {
    let artwork: KitoNowPlayingArtwork
    let cornerRadius: CGFloat

    public init(artwork: KitoNowPlayingArtwork, cornerRadius: CGFloat = 12) {
        self.artwork = artwork
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            switch artwork {
            case .gradient(let colors, let symbol):
                LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .overlay {
                        GeometryReader { geometry in
                            Image(systemName: symbol)
                                .font(.system(size: geometry.size.width * 0.42, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
            case .asset(let name):
                Image(name).resizable().scaledToFill()
            case .url(let url):
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase { image.resizable().scaledToFill() } else { Color.white.opacity(0.12) }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }
}

struct IslandPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
