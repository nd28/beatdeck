# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.2.1] - 2026-09-06

### Fixed
- Volume on macOS. `wpctl` is PipeWire-only, so on a Mac the volume presets
  returned `{ok:1}` while doing nothing and status reported `vol: null`.
  Volume now goes through `osascript` (`set volume output volume N`) on
  darwin and `wpctl` everywhere else. Playback via `bctl` already worked.
- `vol` clamps its input to 0-100 instead of passing whatever came in.

## [1.2.0] - 2026-09-06

### Added
- Olivia Dean section: Jazz Cafe set, Sofar London set, the Messy live film,
  and two long greatest-hits mixes. Long-form only, so the deck stays a
  put-it-on-and-leave-it thing.
- Taylor Swift section: six hour-plus mixes (greatest hits, a Swiftie DJ set,
  chill/study playlists), full tour concerts from Fearless through Eras
  (Munich), and shorter live sets (Super Saturday Night, BBC Big Weekend,
  Tiny Desk, Live On The Seine).
- Optional `g` field on each entry in `songs.json` groups the list into
  labelled sections (`no vocals`, `olivia dean`, `taylor swift`). Entries
  without `g` render without a header.

### Changed
- Header is now just `beatdeck` — the deck is no longer instrumental-only.
- `songs.json` is re-read when its mtime changes, so editing the track list no
  longer needs a server restart (reload the page to see new rows).

### Fixed
- Row highlighting keys off `data-i` instead of DOM position, so it survives
  the section headers; tapping a row now clears the previous row's highlight
  immediately instead of showing two lit rows until the next poll.

## [1.1.0] - 2026-09-06

### Added
- Version tag in the header, filled from `package.json` by a
  `transformIndexHtml` hook (`%APP_VERSION%` placeholder).
- This changelog.

### Changed
- Replaced the fixed bottom control bar with a collapsible dock: a compact
  pill (thumbnail, title, status line, play/pause, thin progress line) that
  expands into the full deck (progress bar with elapsed/total time, prev /
  play-pause / next, volume presets). Tap the pill to toggle, tap outside or
  press Escape to collapse.
- Now-playing pill shows the YouTube thumbnail, which spins while playing;
  status line shows the channel instead of the title.
- Control buttons slightly smaller; list bottom padding reduced to match the
  collapsed dock.
- Honors `prefers-reduced-motion` (no spin, no dock transitions).

## [1.0.0] - 2026-09-06

### Added
- Phone remote for instrumental hip-hop mixes: song list from `songs.json`,
  YouTube playback driven through `bctl`, volume through `wpctl`.
- Vite dev server with `/api` endpoints for `status`, `play`, `prev`, `next`,
  `toggle`, and `vol`.
- Fixed bottom bar with progress, now-playing text, transport buttons, and
  25/50/75/100 volume presets.

[Unreleased]: https://github.com/nd28/beatdeck/compare/v1.2.1...HEAD
[1.2.1]: https://github.com/nd28/beatdeck/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/nd28/beatdeck/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/nd28/beatdeck/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nd28/beatdeck/releases/tag/v1.0.0
