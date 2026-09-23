# KitoIslandBar

An in-app Dynamic-Island-style status pill for SwiftUI. Part of the
[Kito](https://github.com/WykSofts-Inc/KitoDevKit) ecosystem.

## What this actually is (and isn't)

iOS never lets a third-party app draw on, resize, or recolor the real
notch / Dynamic Island — that's system chrome Apple owns exclusively. The
closest a third-party app gets is putting content *inside* the Island via
ActivityKit (see [KitoOrderTracking](https://github.com/WykSofts-Inc/KitoOrderTracking)'s
Live Activity support), which still follows Apple's own layout and styling
rules, not arbitrary colors.

`KitoIslandBar` is the honest alternative: a real in-app pill, shaped and
positioned where the Island sits, that *this app* draws and *this app*
colors — for glanceable live status (battery, an upload's progress, a
quick alert) without a full screen or a toast interrupting the user.

## Usage

```swift
import KitoIslandBar

struct RootView: View {
    var body: some View {
        ContentView()
            .kitoIslandBar(.progress(fraction: 0.6, color: .blue, label: "60%"))
    }
}
```

Four states, one enum:

```swift
.hidden
.compact(systemImage: "bolt.fill", color: .blue)
.progress(fraction: 0.42, color: .green, label: "42%")
.expanded(title: "Low battery", message: "12% remaining", color: .red)
```

## Dynamic Island activities

`kitoDynamicIsland` draws one black shape over the hardware island and springs it between three
presentations — `.idle` (invisible over the real island), `.compact` (content either side of the
camera) and `.expanded` (a large panel) — blurring content in and out as it changes. Tap to
expand; tap outside or swipe up to collapse.

```swift
@State private var presentation = KitoIslandPresentation.compact

ContentView()
    .kitoDynamicIsland(presentation: $presentation) {
        Image(systemName: "timer").foregroundStyle(.orange)      // compact, left
    } trailing: {
        Text("4:59").foregroundStyle(.orange)                    // compact, right
    } expanded: {
        TimerControls()                                          // the grown panel
    }
```

It lines up with each model's island by reading the top safe area, and stays a floating pill
anywhere else (a preview, a notch iPhone). `KitoIslandMetrics` adjusts size, corners and spacing.

### Now Playing

A ready-made music player, like Apple Music's: artwork and a live waveform when compact;
artwork, title, a draggable scrubber and back / play-pause / forward when expanded.

```swift
.kitoNowPlayingIsland(
    presentation: $presentation,
    item: KitoNowPlayingItem(title: "Midnight Drive", artist: "Neon Coast",
                             artwork: .gradient([.pink, .purple], symbol: "music.note"), duration: 214),
    isPlaying: $isPlaying,
    elapsed: $elapsed,
    onPrevious: previous, onNext: next
)
```

`KitoWaveform`, `KitoScrubber` and `KitoNowPlayingExpanded` are public for your own layouts.

## Real battery data

`KitoBatteryMonitor` wraps `UIDevice`'s actual battery APIs — a genuine
percentage, not a simulated one — and hands back a ready-to-use
`KitoIslandBarState`:

```swift
@State private var battery = KitoBatteryMonitor()
// ...
.kitoIslandBar(battery.islandBarState())
```

Every iOS Simulator reports no real battery hardware; `islandBarState()`
returns `.hidden` there rather than a fake percentage. Run on a real device
to see it live.

## Installation

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoIslandBar.git", from: "1.0.0")
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — open an issue, then a pull request
against `main`. All contributions are reviewed before merge.

## License

MIT — see [LICENSE](LICENSE).
