# Changelog

All notable changes to **MonitorApp** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-11-26

### Added
- **Graphical Menu Bar Representations**:
  - **Progress Bar Style**: Miniature horizontal progress bar with track and filled level indicator reflecting real-time load for CPU, Memory, and Network.
  - **History Graph (Sparkline) Style**: Real-time waveform sparkline rendering recent 30-sample load curves with smooth gradient fills directly within the macOS menu bar.
  - **Bar & Text Style**: Compact progress bar combined with numerical percentage/rate indicator.
  - **Independent Metric Customization**: Choose a unified preset or customize CPU, Memory, and Network representation styles independently in Settings and the right-click menu.
- **Hover Zoomed-In View (HUD)**:
  - Non-activating, floating frosted-glass HUD appears beneath the hovered menu bar metric.
  - **CPU Zoomed View**: Detailed 30-second load sparkline with grid lines, peak percentage, User/System/Idle breakdown, chip architecture, and per-core utilization bars.
  - **Memory Zoomed View**: 30-second memory trend graph, pressure status badge, unified RAM usage, and multi-segment bar (Wired, Active, Compressed, Free).
  - **Network Zoomed View**: Dual high-resolution sparklines for download and upload throughput, IP address, interface name, and session transfer totals.
  - Quick toggle to enable/disable Hover Zoom in Settings and Context Menu.

---

## [1.1.0] - 2026-11-21

### Added
- **Dedicated Processes Tab**: Added a dedicated Processes tab in the inspector popover displaying the top 25 active processes.
- **Alphabetical & Metric Sorting**: Interactive sort selector allowing sorting by **CPU**, **Memory**, or **Name (A–Z)**.
- **Process Termination / Force Quit**: Quick-action kill button (`xmark.circle.fill`) on each process row with visual confirmation to terminate runaway applications.
- **Unresponsive Process Detection**: Detects hung or zombie processes (`Not Responding`), displays an alert banner, styles the affected process in red, and prioritizes it at the top of the list.
- **Full-Height Process List**: Process list container expands to 100% available vertical height with smooth internal scrolling and compact row spacing.

### Changed
- **Accurate Memory Calculation**: Updated RAM calculation formula to `(Active + Wired + Compressed) / Total RAM * 100%`, excluding inactive cached files and purgeable memory.
- **Memory Pressure Styling**: Menu bar memory indicator and detail view circular gauge dynamically change color based on macOS memory pressure (Green for Normal, Yellow for Warning, Red for Critical).
- **CPU Sparkline Height**: Enlarged CPU historical sparkline graph height from 38px to 58px for enhanced visibility.
- **Cleaner Tab Bar**: Removed percentage badges from tab buttons and enforced single-line headers to prevent wrapping.
- **Settings Redesign**: Replaced native segmented pickers with custom toggle controls to prevent layout snapping and remove excessive vertical padding.
- **Installation Path**: Updated `build.sh install` and documentation to install directly into the system `/Applications` directory instead of user-local `~/Applications`.

---

## [1.0.0] - 2026-11-11

### Added
- **Initial Release** of MonitorApp for macOS.
- **Menu Bar Status Item (`LSUIElement`)**: Live real-time percentages for CPU, Memory, and Network throughput.
- **Interactive Popover Inspector**:
  - **CPU Tab**: Real-time gauge, Apple Silicon core breakdown (Super, Performance, Efficiency cores) and Intel core breakdown, 30-second live sparkline, and top 5 CPU processes.
  - **Memory Tab**: RAM usage gauge, wired/active/compressed/free breakdown, swap memory metrics, and dynamic memory pressure card.
  - **Network Tab**: Live download/upload speed gauges, interface info (IP, MAC, link rate), and sparkline charts.
  - **Settings Tab**: Customizable refresh intervals, appearance modes (System, Dark, Light), and network display formatting.
- **Vertical Resizing & State Persistence**: Drag-to-resize popover with height persistence across app launches.
- **Context Menu**: Right-click menu for quick settings, Activity Monitor shortcut, and app quit.
