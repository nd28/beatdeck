# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/nd28/beatdeck/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/nd28/beatdeck/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nd28/beatdeck/releases/tag/v1.0.0
