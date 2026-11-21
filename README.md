# MonitorApp 🖥️

A native, lightweight, and modern macOS menu bar application that displays real-time system metrics (CPU, Memory, and Network) in percentages and opens detailed inspector views upon clicking each metric.

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-black?style=flat&logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?style=flat&logo=swift)
![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20%2F%20Intel-blue?style=flat)

---

## ✨ Features

- **Top Menu Bar Residency (`LSUIElement`)**:
  - Resides unobtrusively in the macOS top menu bar without cluttering the Dock.
  - Displays real-time **CPU %**, **Memory %**, and **Network %** (or throughput speed) with clean SF symbols and native hover effects.
  - **Direct Tab Activation**: Clicking on **CPU %**, **Memory %**, or **Network %** in the menu bar instantly opens the popup directly to that exact tab.
  - **Vertical Resizing & Size Memory**: The popup can be freely resized vertically (by dragging the bottom border or the visual bottom grabber handle). The chosen height is remembered in `UserDefaults` and restored every time you reopen the popup.
  - **Right-Click Context Menu**: Right-click (or Ctrl+click) anywhere on the status item to open a quick context menu to:
    - Change **Appearance**: Match System (Auto), Dark Mode, or Light Mode.
    - Change **Display Options**: Toggle Network format (% or speed) and top process visibility.
    - Change **Update Frequency**: 1.0s, 1.5s, 2.0s, 3.0s, 5.0s.
    - Quick access to CPU, Memory, and Network inspectors.
    - Launch macOS Activity Monitor.
    - **Quit MonitorApp** (`⌘Q`).

- **CPU Core Breakdown (Click on CPU %)**:
  - Real-time overall CPU usage gauge, user %, system %, and idle %.
  - **Dynamic Core Architecture Detection**:
    - Distinguishes **Super Cores**, **Performance Cores (P-Cores)**, and **Efficiency Cores (E-Cores)** on Apple Silicon (M1/M2/M3/M4/M5 Pro/Max/Ultra) and standard cores on Intel.
    - Beautiful color-coded badges for each core type (Indigo for Super, Amber for Performance, Mint for Efficiency).
    - Per-core real-time animated utilization progress bars and percentages.
  - 30-second live CPU usage history sparkline graph.
  - Top 5 CPU-intensive processes with app icons, names, and PIDs.

- **Memory Inspector (Click on Memory %)**:
  - Overall RAM usage gauge and total installed memory.
  - **Wired Memory Card**: Exact wired memory amount, percentage of total RAM, and OS kernel lock description.
  - **Memory Pressure Card**: Dynamic status badge (**Normal** / **Warning** / **Critical**) with pulsating indicator and pressure percentage.
  - **Swap Usage Card**: Exact swap memory used, total allocated swap, and free swap.
  - Proportional multi-segment bar displaying Wired, Active, Compressed, and Free memory.
  - Detailed breakdown table (Active, Inactive, Compressed, Purgeable, Swap).
  - Top 5 Memory-consuming processes.

- **Network Inspector (Click on Network %)**:
  - Download & Upload live speeds (e.g. `2.4 MB/s`, `420 KB/s`).
  - Bandwidth usage percentage relative to active link capacity.
  - Real-time sparkline history charts for both download and upload throughput.
  - Active network interface details (e.g. `en0`, Wi-Fi / Ethernet, IPv4 address, MAC address, Baud link rate).
  - Session cumulative data totals (Total downloaded & uploaded).

- **Modern Native macOS Aesthetics**:
  - Translucent `.ultraThinMaterial` / `NSVisualEffectView` popover background.
  - Smooth 60fps animations.
  - Non-blocking asynchronous Mach kernel sampling on a background queue.
  - Quick action to launch macOS Activity Monitor or quit the app.

---

## 🚀 Quick Start

### Build and Run
From the root directory of this repository:

```bash
# Build the native .app bundle
./build.sh

# Or build and launch directly
./build.sh run
```

Alternatively, use `make`:
```bash
make
make run
```

### Install to Applications
To install MonitorApp into `/Applications`:
```bash
./build.sh install
```
You can then launch **MonitorApp** from Spotlight (`Cmd + Space`), Launchpad, or Finder.

---

## 🛠️ Project Structure

```
MonitorApp/
├── Package.swift                    # Swift Package Manager definition
├── Info.plist                       # macOS bundle metadata (LSUIElement = true)
├── build.sh                         # Automated build & code-signing script
├── Makefile                         # Convenient build targets
├── AppIcon.icns                     # Native macOS squircle icon
└── Sources/
    └── MonitorApp/
        ├── Main.swift               # Application entry point
        ├── App/
        │   ├── AppDelegate.swift    # App lifecycle & accessory configuration
        │   └── MenuBarManager.swift # Status item & popover presentation coordinator
        ├── Models/
        │   ├── SystemStats.swift    # Data models for CPU, Cores, Memory & Network
        │   └── AppSettings.swift    # User preferences & persistence
        ├── Services/
        │   ├── SystemMonitorService.swift # Central sampling coordinator (MainActor)
        │   ├── CPUMonitor.swift     # Mach processor info & IOKit core classification
        │   ├── MemoryMonitor.swift  # Mach VM statistics, memory pressure & swap sysctl
        │   ├── NetworkMonitor.swift # getifaddrs network throughput & bandwidth %
        │   └── ProcessMonitor.swift # libproc & NSWorkspace top process tracker
        └── Views/
            ├── MenuBarStatusView.swift   # High-performance AppKit status bar view
            ├── PopoverContentView.swift  # Main popover container with tab navigation
            ├── CPUDetailView.swift       # CPU gauge, per-core breakdown & top processes
            ├── MemoryDetailView.swift    # Memory breakdown, Wired, Pressure & Swap cards
            ├── NetworkDetailView.swift   # Live download/upload throughput & interface details
            ├── SettingsDetailView.swift  # Refresh rate & display options
            └── Components/
                ├── GlassCard.swift       # Translucent macOS glass container
                ├── SparklineChartView.swift # Smooth Bezier curve area chart
                ├── CircularGaugeView.swift  # Modern circular progress ring
                ├── SegmentedProgressBar.swift # Multi-segment distribution bar
                └── ProcessRowView.swift  # Process row with app icon & metric badge
```

---

## 🔬 System APIs Used

- **CPU & Cores**:
  - `host_processor_info` with `PROCESSOR_CPU_LOAD_INFO` (Mach Kernel)
  - `IOPlatformDevice` via IOKit to determine `cluster-type` per core (`E`, `P`, `M`)
  - `sysctlbyname("hw.perflevel*")` for heterogeneous core names and counts
  - `machdep.cpu.brand_string` for processor identification
- **Memory**:
  - `host_statistics64` with `HOST_VM_INFO64` for Wired, Active, Inactive, Compressed, Free
  - `sysctlbyname("kern.memorystatus_vm_pressure_level")` for kernel memory pressure
  - `sysctlbyname("vm.swapusage")` (`xsw_usage`) for swap memory metrics
- **Network**:
  - `getifaddrs` querying `AF_LINK` interface byte counters (`ifi_ibytes`, `ifi_obytes`, `ifi_baudrate`)
  - `getnameinfo` for active interface IPv4 address resolution
- **Top Processes**:
  - `proc_listpids` & `proc_pidinfo` (`PROC_PIDTASKINFO`) via Darwin `libproc`
  - `NSWorkspace.shared.runningApplications` for localized app names and vector icons
