# ``KitoIslandBar``

An in-app, Dynamic Island-style status pill and island activities for SwiftUI.

## Overview

iOS never lets a third-party app draw on, resize, or recolor the real Dynamic
Island; the closest it gets is ActivityKit content inside the island, which
follows Apple's own layout rules. KitoIslandBar is the in-app alternative: a
pill that your app draws and colors, positioned where the island sits, for
glanceable live status such as battery level, upload progress, or a quick
alert, without a full screen or a toast interrupting the user.

The simplest form is a status pill driven by ``KitoIslandBarState``, which has
four cases: hidden, compact, progress, and expanded. Attach it once near the
app root with `kitoIslandBar(_:)`:

```swift
import KitoIslandBar

struct RootView: View {
    var body: some View {
        ContentView()
            .kitoIslandBar(.progress(fraction: 0.6, color: .blue, label: "60%"))
    }
}
```

For richer activities, `kitoDynamicIsland(presentation:metrics:background:leading:trailing:expanded:)`
draws a black shape over the hardware island and springs it between the
``KitoIslandPresentation`` states: idle, compact, and expanded. It aligns with
the hardware island by reading the top safe area, and ``KitoIslandMetrics``
adjusts its size, corners, and spacing. `kitoNowPlayingIsland` builds a
ready-made music player on top of it from a ``KitoNowPlayingItem``.

``KitoBatteryMonitor`` wraps the real `UIDevice` battery APIs and returns a
ready-to-use ``KitoIslandBarState``. The iOS Simulator reports no battery
hardware, so the monitor returns `.hidden` there.

## Topics

### Status Pill

- ``KitoIslandBarState``
- ``KitoIslandBarView``
- ``KitoBatteryMonitor``

### Dynamic Island Activities

- ``KitoDynamicIsland``
- ``KitoIslandPresentation``
- ``KitoIslandMetrics``

### Now Playing

- ``KitoNowPlayingItem``
- ``KitoNowPlayingArtwork``
- ``KitoNowPlayingExpanded``
- ``KitoNowPlayingArtworkView``
- ``KitoScrubber``
- ``KitoWaveform``
