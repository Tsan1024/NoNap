// App.swift. Sleepless: a standalone menu-bar toggle that keeps the Mac running
// with the lid closed (on battery, no external display) via `pmset disablesleep`.
//
// Mechanism (verified live on this machine; disablesleep is UNDOCUMENTED in
// pmset(1) but real. It sets IORegistry "SleepDisabled" = Yes and disables
// idle + Apple-menu + lid-close clamshell sleep):
//   ON : sudo pmset -a disablesleep 1
//   OFF: sudo pmset -a disablesleep 0
//   READ (no root): pmset -g | grep -i SleepDisabled  (value 1 = ON; 0/absent = OFF)
// The OFF/ON commands run passwordless via a tightly-scoped /etc/sudoers.d drop-in.
// disablesleep is runtime-only and resets to 0 on reboot, and that reset is a
// deliberate safety feature; the app does NOT auto re-arm.
//
// UI: clicking the menu-bar coffee cup opens a small native popover with an NSSwitch
// toggle (the System-Settings control), a state caption, an auto-off timer, the
// battery-floor slider, a Launch-at-login switch, and Quit. The menu-bar glyph also
// shows state at a glance.
//
// The coffee-cup metaphor is literal: an EMPTY cup means the Mac sleeps normally, a
// FULL cup means it is being kept awake (caffeinated), and a full cup with a small
// dot means it is awake on battery with the auto-off safety net live.
//
// Three small, fail-safe features layer on top, none of which adds a daemon or
// persists OS state (so "reboot resets it" still holds):
//   1. Auto-off timer (0...24h) — stores its deadline so a relaunch can resume it.
//      Normal quit also restores sleep; reboot resets the flag.
//   2. Launch at login (SMAppService.mainApp) — OFF by default. The app always
//      launches reading the TRUE system state, so a login launch can never
//      re-enable disablesleep on its own.
//   3. Low-Power-Mode auto-off — on battery, if Low Power Mode is on, Sleepless
//      turns itself off. Same shape as the battery floor, evaluated on the same tick.
//
// Build (mirrors Nexus.app): Command Line Tools `swiftc`, NO Xcode project.
//   swiftc -O -parse-as-library -target arm64-apple-macos26.0 -framework AppKit \
//          -framework ServiceManagement
//   File MUST be named App.swift and compiled -parse-as-library so the
//   @main enum + @MainActor static main() entry is Swift-6 isolation-safe.
import AppKit
import ServiceManagement

// MARK: - Tunables
private let pollInterval: TimeInterval = 60
// Battery-floor config (user-adjustable via the popover slider; persisted in UserDefaults).
private let floorKey = "batteryFloorPercent"
private let languageKey = "appLanguage"
private let ownershipKey = "ownsDisableSleep"
private let timerEndKey = "autoOffEndDate"
private let floorDefault = 15
private let floorMin = 5
private let floorMax = 50

private enum AppLanguage: Int {
    case english
    case chinese
}

// MARK: - Menu-bar coffee glyph (native SF Symbols, MONOCHROME template — state by SHAPE)
// macOS convention: a menu-bar extra is a template image (no colour) so it adapts to light/dark
// bars and inverts on highlight. State is read from the SILHOUETTE, not colour. The old
// empty-vs-filled cups looked near-identical at 16 px, so we switch the silhouette dramatically
// with steam (a hot cup = awake):
//   OFF   (sleeps normally)        = cup.and.saucer            cup resting on its saucer, NO steam (cold/asleep)
//   ON    (kept awake, on power)   = cup.and.heat.waves.fill   hot cup with rising steam (awake)
//   ARMED (kept awake, on battery) = cup.and.heat.waves.fill + a small dot (awake, safety net live)
// The no-steam → steam change reads instantly even at 16 px; the armed dot is the only extra
// mark. All template (monochrome) — SF Symbols only, no hand-drawn paths.
enum SleepGlyph {
    case off
    case on
    case armed
}

private func makeCupGlyph(_ glyph: SleepGlyph) -> NSImage {
    let cfg = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular).applying(.init(scale: .medium))
    let name = (glyph == .off) ? "cup.and.saucer" : "cup.and.heat.waves.fill"
    let base = NSImage(systemSymbolName: name, accessibilityDescription: "Atomic Grunt")?
        .withSymbolConfiguration(cfg)
        ?? NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Atomic Grunt")
        ?? NSImage()

    guard glyph == .armed else {
        base.isTemplate = true
        return base
    }
    // ARMED: full steaming cup + a small filled dot top-right (the "auto-off safety net is live"
    // mark). Drawn in template black so it tints + inverts with the menu bar exactly like the cup.
    let size = base.size
    guard size.width > 0, size.height > 0 else { base.isTemplate = true; return base }
    let composed = NSImage(size: size)
    composed.lockFocus()
    base.draw(in: NSRect(origin: .zero, size: size))
    let d = max(size.height * 0.26, 4)
    let dot = NSBezierPath(ovalIn: NSRect(x: size.width - d, y: size.height - d, width: d, height: d))
    NSColor.black.setFill()
    dot.fill()
    composed.unlockFocus()
    composed.isTemplate = true
    return composed
}

// Flipped container so popover content lays out top-down with simple frames.
private final class FlippedView: NSView { override var isFlipped: Bool { true } }

// Frosted-glass popover backing: a flipped NSVisualEffectView so content still
// lays out top-down while the panel gets a translucent, blurred material that
// samples the desktop/windows behind it (system light/dark aware). On macOS 26 the
// .popover material renders as the system Liquid Glass automatically; we deliberately
// keep this native (no hand-rolled tint on the surface) so a sudo-touching panel
// stays visually first-party. Colour lives on the controls, never the surface.
private final class GlassView: NSVisualEffectView { override var isFlipped: Bool { true } }

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let onGlyph = makeCupGlyph(.on)
    private let offGlyph = makeCupGlyph(.off)
    private let armedGlyph = makeCupGlyph(.armed)

    // Popover UI
    private let popover = NSPopover()
    private var toggleSwitch: NSSwitch!
    private var titleLabel: NSTextField!
    private var headerMark: NSImageView!    // header coffee mark; tints violet when awake
    private var captionLabel: NSTextField!
    private var mainLabel: NSTextField!
    private var timerLabel: NSTextField!
    private var floorButton: NSButton!
    private var batteryEstimateLabel: NSTextField!
    private var floorControls: FlippedView!
    private var footer: FlippedView!
    private var settingsButton: NSButton!
    private var timerHintLabel: NSTextField!
    private var batteryEstimate: BatteryEstimate?
    private var floorSlider: NSSlider!
    private var autoOffSlider: NSSlider!
    private var autoOffField: NSTextField!
    private var autoOffUnitLabel: NSTextField!
    private var countdownLabel: NSTextField!
    private var clickMonitor: Any?
    private var batteryFloorPercent = floorDefault
    private var isOn = false
    private var ownsDisableSleep = false
    private var stateReadFailureNotified = false
    private var language: AppLanguage = .english

    // Auto-off timer (deadline persisted for crash/relaunch recovery)
    private var autoOffMinutes = 0           // 0 = no limit; slider covers 0...24 hours
    private var keepAwakeTimer: Timer?       // one-shot: flips sleep back on when it fires
    private var countdownTicker: Timer?      // 1 Hz label refresh, only while the popover is open
    private var timerEndDate: Date?

    private let popoverWidth: CGFloat = 344
    private let popoverHeight: CGFloat = 382

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        batteryFloorPercent = min(max((UserDefaults.standard.object(forKey: floorKey) as? Int) ?? floorDefault, floorMin), floorMax)
        ownsDisableSleep = UserDefaults.standard.bool(forKey: ownershipKey)
        if let saved = UserDefaults.standard.object(forKey: languageKey) as? Int,
           let selected = AppLanguage(rawValue: saved) {
            language = selected
        } else if Locale.preferredLanguages.first?.hasPrefix("zh") == true {
            language = .chinese
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = offGlyph
            button.action = #selector(statusClicked)
            button.target = self
        }
        popover.behavior = .applicationDefined   // app-managed dismissal (no transient close/reopen flicker)
        popover.animates = true
        popover.contentSize = NSSize(width: popoverWidth, height: popoverHeight)
        popover.contentViewController = makeContentController()

        refresh()   // reflect TRUE system state on launch (never a stale assumption)
        restoreKeepAwakeTimer()
        timer = Timer.scheduledTimer(timeInterval: pollInterval, target: self,
                                     selector: #selector(poll), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // ponytail: this covers normal quit/logout; a tiny app cannot recover from SIGKILL
        // without adding a privileged daemon. Reboot still resets disablesleep.
        if ownsDisableSleep, setDisableSleep(false) == .ok { setOwnership(false) }
    }

    // MARK: - Popover content
    private func makeContentController() -> NSViewController {
        let pad: CGFloat = 22, width = popoverWidth - 44
        let root = GlassView(frame: NSRect(x: 0, y: 0, width: popoverWidth, height: popoverHeight))
        root.material = .popover
        root.blendingMode = .behindWindow
        root.state = .active

        func label(_ frame: NSRect, size: CGFloat, weight: NSFont.Weight = .regular,
                   color: NSColor = .labelColor) -> NSTextField {
            let view = makeLabel("", font: .systemFont(ofSize: size, weight: weight), color: color)
            view.frame = frame
            root.addSubview(view)
            return view
        }
        func divider(_ y: CGFloat, in parent: NSView) {
            let line = NSBox(frame: NSRect(x: pad, y: y, width: width, height: 1))
            line.boxType = .separator
            parent.addSubview(line)
        }
        let mark = NSImageView(frame: NSRect(x: pad, y: 21, width: 20, height: 20))
        mark.image = makeCupGlyph(.on)
        root.addSubview(mark)
        headerMark = mark
        titleLabel = label(NSRect(x: pad + 28, y: 21, width: width - 88, height: 22),
                           size: 15, weight: .semibold)
        toggleSwitch = NSSwitch()
        toggleSwitch.target = self
        toggleSwitch.action = #selector(switchToggled(_:))
        let switchSize = toggleSwitch.intrinsicContentSize
        toggleSwitch.frame = NSRect(x: popoverWidth - pad - switchSize.width, y: 19,
                                    width: switchSize.width, height: switchSize.height)
        root.addSubview(toggleSwitch)

        mainLabel = label(NSRect(x: pad, y: 67, width: width, height: 18),
                          size: 11, weight: .medium, color: .secondaryLabelColor)
        countdownLabel = label(NSRect(x: pad - 1, y: 91, width: width + 2, height: 43),
                               size: 29, weight: .medium)
        captionLabel = label(NSRect(x: pad, y: 140, width: width, height: 30),
                            size: 11, color: .secondaryLabelColor)
        captionLabel.maximumNumberOfLines = 2
        captionLabel.usesSingleLineMode = false
        captionLabel.cell?.wraps = true
        divider(183, in: root)

        timerLabel = label(NSRect(x: pad, y: 198, width: 175, height: 22), size: 12, weight: .medium)
        let formatter = NumberFormatter()
        formatter.minimum = 0
        formatter.maximum = 24
        formatter.maximumFractionDigits = 2
        autoOffField = NSTextField(frame: NSRect(x: popoverWidth - pad - 76, y: 194, width: 50, height: 25))
        autoOffField.alignment = .right
        autoOffField.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        autoOffField.bezelStyle = .roundedBezel
        autoOffField.formatter = formatter
        autoOffField.target = self
        autoOffField.action = #selector(autoOffFieldChanged(_:))
        autoOffField.cell?.sendsActionOnEndEditing = true
        root.addSubview(autoOffField)
        autoOffUnitLabel = label(NSRect(x: popoverWidth - pad - 22, y: 200, width: 24, height: 17),
                                size: 11, color: .secondaryLabelColor)
        autoOffSlider = NSSlider(value: 0, minValue: 0, maxValue: 24,
                                 target: self, action: #selector(autoOffSliderChanged(_:)))
        autoOffSlider.isContinuous = false
        autoOffSlider.frame = NSRect(x: pad, y: 227, width: width, height: 18)
        root.addSubview(autoOffSlider)
        timerHintLabel = label(NSRect(x: pad, y: 249, width: width, height: 17),
                              size: 10, color: .secondaryLabelColor)
        divider(279, in: root)

        floorButton = NSButton(title: "", target: self, action: #selector(toggleFloorControls))
        floorButton.isBordered = false
        floorButton.alignment = .left
        floorButton.font = .systemFont(ofSize: 12, weight: .medium)
        floorButton.frame = NSRect(x: pad - 3, y: 289, width: width + 6, height: 27)
        root.addSubview(floorButton)
        batteryEstimateLabel = label(NSRect(x: pad, y: 319, width: width, height: 30),
                                     size: 11, color: .secondaryLabelColor)
        batteryEstimateLabel.maximumNumberOfLines = 2
        batteryEstimateLabel.usesSingleLineMode = false
        batteryEstimateLabel.cell?.wraps = true
        floorControls = FlippedView(frame: NSRect(x: pad, y: 354, width: width, height: 48))
        floorControls.isHidden = true
        floorSlider = NSSlider(value: Double(batteryFloorPercent), minValue: Double(floorMin),
                               maxValue: Double(floorMax), target: self, action: #selector(floorSliderChanged(_:)))
        floorSlider.frame = NSRect(x: 0, y: 0, width: width, height: 18)
        floorSlider.isContinuous = true
        floorControls.addSubview(floorSlider)
        for (x, value) in [(CGFloat(0), floorMin), (width - 30, floorMax)] {
            let hint = makeLabel("\(value)%", font: .systemFont(ofSize: 10), color: .secondaryLabelColor)
            hint.frame = NSRect(x: x, y: 22, width: 30, height: 16)
            floorControls.addSubview(hint)
        }
        root.addSubview(floorControls)

        footer = FlippedView(frame: NSRect(x: 0, y: 354, width: popoverWidth, height: 28))
        settingsButton = NSButton(title: "", target: self, action: #selector(showSettings(_:)))
        settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsButton.imagePosition = .imageLeading
        settingsButton.isBordered = false
        settingsButton.font = .systemFont(ofSize: 11)
        settingsButton.contentTintColor = .secondaryLabelColor
        settingsButton.frame = NSRect(x: pad - 3, y: 0, width: 90, height: 22)
        settingsButton.alignment = .left
        footer.addSubview(settingsButton)
        root.addSubview(footer)
        updateLocalizedText()
        let vc = NSViewController()
        vc.view = root
        return vc
    }

    @objc private func toggleFloorControls() {
        floorControls.isHidden.toggle()
        let extra: CGFloat = floorControls.isHidden ? 0 : 48
        footer.frame.origin.y = 354 + extra
        let size = NSSize(width: popoverWidth, height: popoverHeight + extra)
        popover.contentViewController?.view.setFrameSize(size)
        popover.contentSize = size
        renderText()
    }

    @objc private func showSettings(_ sender: NSButton) {
        let menu = NSMenu()
        let login = NSMenuItem(title: text("Launch at login", "登录时启动"),
                               action: #selector(loginToggled(_:)), keyEquivalent: "")
        login.target = self
        login.state = loginItemEnabled() ? .on : .off
        menu.addItem(login)
        menu.addItem(.separator())
        for (index, title) in ["English", "中文"].enumerated() {
            let item = NSMenuItem(title: title, action: #selector(languageChanged(_:)), keyEquivalent: "")
            item.tag = index
            item.target = self
            item.state = language.rawValue == index ? .on : .off
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: text("Quit Atomic Grunt", "退出核动力牛马"),
                                  action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.maxY), in: sender)
    }

    private func makeLabel(_ s: String, font: NSFont, color: NSColor) -> NSTextField {
        let t = NSTextField(labelWithString: s)
        t.font = font
        t.textColor = color
        t.isEditable = false
        t.isBordered = false
        t.drawsBackground = false
        return t
    }

    private func text(_ english: String, _ chinese: String) -> String {
        language == .chinese ? chinese : english
    }

    @objc private func languageChanged(_ sender: NSMenuItem) {
        language = AppLanguage(rawValue: sender.tag) ?? .english
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        updateLocalizedText()
        applyUI(on: isOn)
    }

    private func updateLocalizedText() {
        titleLabel?.stringValue = text("Atomic Grunt", "核动力牛马")
        timerLabel?.stringValue = text("Auto-off duration", "保持运行时长")
        autoOffUnitLabel?.stringValue = text("h", "小时")
        timerHintLabel?.stringValue = text("0 = no time limit · up to 24 hours", "0 = 不限时 · 最长 24 小时")
        settingsButton?.title = text("Settings", "设置")
        toggleSwitch?.setAccessibilityLabel(text("Keep awake with lid closed", "合盖保持运行"))
        autoOffSlider?.setAccessibilityLabel(text("Auto-off duration in hours", "保持运行时长（小时）"))
        autoOffField?.setAccessibilityLabel(text("Auto-off duration in hours", "保持运行时长（小时）"))
        floorSlider?.setAccessibilityLabel(text("Battery cutoff percentage", "电量保护阈值"))
        syncAutoOffControls()
        renderText()
        updateCountdownLabel()
    }

    // MARK: - Click the menu-bar cup to open/close the popover
    @objc private func statusClicked() {
        if popover.isShown { closePopover() } else { openPopover() }
    }

    private func openPopover() {
        refresh()                              // sync switch/caption to TRUE state before showing
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        popover.contentViewController?.view.window?.makeFirstResponder(toggleSwitch)
        if keepAwakeTimer != nil { startCountdownTicker() }
        updateCountdownLabel()
        // Close when the user clicks anywhere outside the app (status bar, another app, desktop).
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        countdownTicker?.invalidate(); countdownTicker = nil   // stop the 1 Hz label refresh (keep-awake timer keeps running)
        if let monitor = clickMonitor { NSEvent.removeMonitor(monitor); clickMonitor = nil }
    }

    @objc private func switchToggled(_ sender: NSSwitch) {
        _ = performToggle(wantOn: sender.state == .on)
        sender.state = isOn ? .on : .off
    }

    // Core keep-awake toggle, decoupled from the UI sender. Returns true ONLY when the user
    // must act (the passwordless grant is missing and setup did not complete) so the caller can
    // reflect OFF. The decision to prompt is made on the REAL sudo result (see setDisableSleep),
    // never by re-reading SleepDisabled: a successful sudo means the command ran, even if a
    // safety net (Low Power Mode / battery floor) legitimately turns sleep back on afterwards —
    // which must NOT be mistaken for "permission missing" and trigger a password prompt. This
    // unobservable, state-proxy decision is what made earlier releases re-prompt spuriously.
    @discardableResult
    private func performToggle(wantOn: Bool) -> Bool {
        var result = setDisableSleep(wantOn)
        // Only a genuinely MISSING grant warrants the one-time native-auth setup. A successful
        // sudo (.ok) — or any other failure — never re-prompts here.
        if wantOn, result == .grantMissing {
            if installGrantViaAuth() { result = setDisableSleep(true) }
            if result != .ok {
                notify(text("Couldn't keep awake. Permission setup failed.", "无法保持运行：权限设置失败。"))
                return true
            }
        }
        guard result == .ok else {
            notify(text("The sleep setting could not be changed.", "无法更改休眠设置。"))
            refresh()
            return true
        }
        setOwnership(wantOn)
        applyUI(on: wantOn)
        refresh()                              // applies UI + safety nets; switch reflects reality
        if isOn, ownsDisableSleep, autoOffMinutes > 0 { startKeepAwakeTimer(minutes: autoOffMinutes) }
        return false
    }

    // Install the one-time scoped grant via a SINGLE native macOS authorization (the
    // standard Touch ID / password sheet) — no Terminal. The fixed command below creates,
    // validates, and atomically installs a root-owned sudoers file. It never executes a
    // mutable file from the app bundle as root.
    // Returns true once the passwordless grant is in place; after that the app never asks again.
    @discardableResult
    private func installGrantViaAuth() -> Bool {
        let intro = NSAlert()
        intro.alertStyle = .informational
        intro.messageText = text("Enable keeping your Mac awake", "允许 Mac 合盖后继续运行")
        intro.informativeText = text(
            "Atomic Grunt needs permission once to install a rule limited to two pmset commands. After that the switch works without more prompts.",
            "核动力牛马 需要一次管理员授权，以安装仅限两条 pmset 命令的规则。之后使用开关无需再次授权。"
        )
        intro.addButton(withTitle: text("Enable", "允许"))
        intro.addButton(withTitle: text("Not now", "暂不"))
        NSApp.activate(ignoringOtherApps: true)
        guard intro.runModal() == .alertFirstButtonReturn else { return false }

        let user = NSUserName()
        guard user != "root",
              user.range(of: #"^[A-Za-z_][A-Za-z0-9._-]*$"#, options: .regularExpression) != nil else {
            notify(text("Unsupported account name; permission was not changed.", "账户名称不受支持，权限未更改。"))
            return false
        }
        let grant = "\(user) ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
        // The temporary file lives in root-owned /etc/sudoers.d, so another user process
        // cannot alter it between validation and rename.
        let shellCmd = "set -eu; /usr/bin/install -d -m 0755 -o root -g wheel /etc/sudoers.d; umask 077; tmp=$(/usr/bin/mktemp /etc/sudoers.d/.sleepless.XXXXXX); trap '/bin/rm -f \"$tmp\"' EXIT; /usr/bin/printf '%s\\n' '\(grant)' > \"$tmp\"; /usr/sbin/chown root:wheel \"$tmp\"; /bin/chmod 0440 \"$tmp\"; /usr/sbin/visudo -cf \"$tmp\" >/dev/null; /bin/mv -f \"$tmp\" /etc/sudoers.d/sleepless-disablesleep; trap - EXIT; /usr/sbin/visudo -c >/dev/null"
        let escaped = shellCmd.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let osa = "do shell script \"\(escaped)\" with administrator privileges"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", osa]
        proc.standardOutput = Pipe(); proc.standardError = Pipe()
        do { try proc.run(); proc.waitUntilExit() }
        catch { notify(text("Couldn't start the one-time setup.", "无法启动一次性权限设置。")); return false }
        if proc.terminationStatus == 0 { return true }
        if proc.terminationStatus != 128 {               // 128 = user cancelled the auth sheet
            notify(text("Permission setup didn't complete.", "权限设置未完成。"))
        }
        return false
    }

    // A brief, subtle pulse on the menu-bar glyph whenever the state (and thus the cup
    // shape) changes, so the change is noticeable. Opacity-only: no layer geometry is
    // mutated, so it can't shift the status item on any macOS version.
    private func pulseStatusItem() {
        guard let b = statusItem.button else { return }
        b.wantsLayer = true
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.3
        pulse.toValue = 1.0
        pulse.duration = 0.34
        pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
        b.layer?.add(pulse, forKey: "statePulse")
    }

    @objc private func poll() { refresh() }

    // MARK: - Auto-off timer (Feature 1)
    @objc private func autoOffSliderChanged(_ sender: NSSlider) {
        let hours = (sender.doubleValue * 2).rounded() / 2
        setAutoOff(minutes: Int(hours * 60))
    }

    @objc private func autoOffFieldChanged(_ sender: NSTextField) {
        let formatter = sender.formatter as? NumberFormatter
        guard let hours = formatter?.number(from: sender.stringValue)?.doubleValue, hours.isFinite else {
            syncAutoOffControls()
            return
        }
        setAutoOff(minutes: Int((min(max(hours, 0), 24) * 60).rounded()))
    }

    private func setAutoOff(minutes: Int) {
        autoOffMinutes = min(max(minutes, 0), 24 * 60)
        syncAutoOffControls()
        if isOn, ownsDisableSleep, autoOffMinutes > 0 {
            startKeepAwakeTimer(minutes: autoOffMinutes)
        } else {
            cancelKeepAwakeTimer()
            updateCountdownLabel()
        }
    }

    private func syncAutoOffControls() {
        let hours = Double(autoOffMinutes) / 60
        autoOffSlider?.doubleValue = hours
        autoOffField?.stringValue = hours.rounded() == hours
            ? String(Int(hours))
            : String(format: "%.2f", hours).replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
    }

    private func startKeepAwakeTimer(minutes: Int) {
        cancelKeepAwakeTimer()
        guard minutes > 0, isOn, ownsDisableSleep else { updateCountdownLabel(); return }
        let seconds = TimeInterval(minutes * 60)
        let end = Date().addingTimeInterval(seconds)
        timerEndDate = end
        UserDefaults.standard.set(end.timeIntervalSince1970, forKey: timerEndKey)
        keepAwakeTimer = Timer.scheduledTimer(timeInterval: seconds, target: self,
                                              selector: #selector(keepAwakeTimerFired), userInfo: nil, repeats: false)
        if popover.isShown { startCountdownTicker() }
        updateCountdownLabel()
    }

    private func cancelKeepAwakeTimer() {
        keepAwakeTimer?.invalidate(); keepAwakeTimer = nil
        countdownTicker?.invalidate(); countdownTicker = nil
        timerEndDate = nil
        UserDefaults.standard.removeObject(forKey: timerEndKey)
    }

    @objc private func keepAwakeTimerFired() {
        if turnOffForSafety(
            success: text("Auto-off timer ended. Atomic Grunt turned off.", "自动关闭计时结束，核动力牛马 已关闭。"),
            failure: text("Auto-off failed. Turn Atomic Grunt off manually.", "自动关闭失败，请手动关闭 核动力牛马。")
        ) {
            autoOffMinutes = 0
            syncAutoOffControls()
        } else {
            keepAwakeTimer = Timer.scheduledTimer(timeInterval: pollInterval, target: self,
                                                  selector: #selector(keepAwakeTimerFired), userInfo: nil, repeats: false)
        }
    }

    private func restoreKeepAwakeTimer() {
        let timestamp = UserDefaults.standard.double(forKey: timerEndKey)
        guard ownsDisableSleep, isOn, timestamp > 0 else {
            UserDefaults.standard.removeObject(forKey: timerEndKey)
            return
        }
        let end = Date(timeIntervalSince1970: timestamp)
        let remaining = end.timeIntervalSinceNow
        timerEndDate = end
        autoOffMinutes = min(max(Int(ceil(remaining / 60)), 1), 24 * 60)
        syncAutoOffControls()
        if remaining <= 0 {
            keepAwakeTimerFired()
        } else {
            keepAwakeTimer = Timer.scheduledTimer(timeInterval: remaining, target: self,
                                                  selector: #selector(keepAwakeTimerFired), userInfo: nil, repeats: false)
        }
    }

    private func startCountdownTicker() {
        countdownTicker?.invalidate()
        countdownTicker = Timer.scheduledTimer(timeInterval: 1, target: self,
                                               selector: #selector(countdownTick), userInfo: nil, repeats: true)
    }

    @objc private func countdownTick() { updateCountdownLabel() }

    private func updateCountdownLabel() {
        mainLabel?.stringValue = isOn
            ? text("KEEPING YOUR MAC AWAKE", "合盖后继续运行")
            : text("OFF DUTY", "休息中")
        countdownLabel?.font = .monospacedDigitSystemFont(ofSize: 29, weight: .medium)
        if !isOn {
            countdownLabel?.stringValue = text("Sleeping normally", "正常休眠")
            countdownLabel?.font = .systemFont(ofSize: 26, weight: .medium)
            captionLabel?.stringValue = text("Clock out. It clocks in.", "你下班，它加班。")
        } else if let end = timerEndDate {
            let minutes = max(0, Int(ceil(end.timeIntervalSinceNow / 60)))
            countdownLabel?.stringValue = minutes > 0
                ? text("\(minutes / 60)h \(minutes % 60)m", "\(minutes / 60) 小时 \(minutes % 60) 分")
                : text("Stopping…", "正在停止…")
            captionLabel?.stringValue = text("Timer remaining · battery protection may stop earlier.",
                                             "定时剩余 · 电量保护可能提前结束运行")
        } else {
            countdownLabel?.stringValue = text("No time limit", "持续保持唤醒")
            countdownLabel?.font = .systemFont(ofSize: 26, weight: .medium)
            captionLabel?.stringValue = text("Battery cutoff and Low Power Mode still apply.",
                                             "电量保护及低电量模式仍会停止运行")
        }
    }

    // MARK: - Launch at login
    @objc private func loginToggled(_ sender: NSMenuItem) {
        do {
            if loginItemEnabled() { try SMAppService.mainApp.unregister() }
            else { try SMAppService.mainApp.register() }
        } catch {
            NSLog("Atomic Grunt: login item update failed: %@", error.localizedDescription)
            notify(text("Couldn't update Launch at login.", "无法更新登录启动设置。"))
        }
    }

    private func loginItemEnabled() -> Bool { SMAppService.mainApp.status == .enabled }

    // MARK: - Core state sync
    @objc private func refresh() {
        batteryEstimate = BatteryEstimate.read()
        renderText()
        guard let on = readSleepDisabled() else {
            if !stateReadFailureNotified {
                notify(text("Couldn't read the system sleep state.", "无法读取系统休眠状态。"))
                stateReadFailureNotified = true
            }
            return
        }
        stateReadFailureNotified = false
        if !on, ownsDisableSleep { setOwnership(false) }
        applyUI(on: on)
        if on, ownsDisableSleep { enforceSafetyNets() }
    }

    private func applyUI(on: Bool) {
        isOn = on
        if !on { cancelKeepAwakeTimer() }   // going OFF clears any countdown/timer
        // ARMED = kept awake while actively discharging on battery, so the
        // auto-off safety net is live. Distinct menu-bar glyph (cup + dot).
        var armed = false
        if on, let (onBattery, discharging, _) = batteryStatus() {
            armed = onBattery && discharging
        }
        if let button = statusItem.button {
            let newImage = on ? (armed ? armedGlyph : onGlyph) : offGlyph
            if button.image !== newImage {   // state (cup shape) changed -> swap + pulse
                button.image = newImage
                pulseStatusItem()
            }
            button.toolTip = on
                ? (armed
                    ? text("Atomic Grunt: on (battery). Auto-off at \(batteryFloorPercent)% or in Low Power Mode.",
                           "核动力牛马：已开启（电池供电），将在 \(batteryFloorPercent)% 或低电量模式下关闭。")
                    : text("Atomic Grunt: on. Stays awake with the lid closed.", "核动力牛马：已开启，合盖后继续运行。"))
                : text("Atomic Grunt: off. Sleeps normally.", "核动力牛马：已关闭，正常休眠。")
        }
        toggleSwitch?.state = on ? .on : .off
        headerMark?.contentTintColor = on ? .controlAccentColor : .secondaryLabelColor
        renderText()
        updateCountdownLabel()
    }

    // Update text labels only (no pmset subprocess; safe to call on every slider tick).
    private func renderText() {
        let arrow = floorControls?.isHidden == false ? "▴" : "▾"
        floorButton?.title = text("Stop at \(batteryFloorPercent)% battery  \(arrow)",
                                  "电量降至 \(batteryFloorPercent)% 时停止  \(arrow)")
        floorButton?.setAccessibilityLabel(text("Battery cutoff: \(batteryFloorPercent) percent. Expand to adjust.",
                                                 "电量保护阈值 \(batteryFloorPercent)%，点击展开调整"))
        guard let battery = batteryEstimate else {
            batteryEstimateLabel?.stringValue = text("Battery estimate unavailable", "暂无法估算电池时间")
            return
        }
        guard battery.onBattery else {
            batteryEstimateLabel?.stringValue = text("Connected to power", "已接通电源")
            return
        }
        guard let minutes = battery.minutesToFloor(batteryFloorPercent) else {
            batteryEstimateLabel?.stringValue = text("Battery estimate unavailable", "暂无法估算电池时间")
            return
        }
        if minutes <= 0 {
            batteryEstimateLabel?.stringValue = text("Battery is at or below the cutoff", "当前电量已达到保护阈值")
        } else {
            // Round the system estimate to 5 minutes; never imply countdown precision.
            let rounded = max(5, Int((min(minutes, 525600) / 5).rounded()) * 5)
            let duration = rounded >= 60
                ? text("\(rounded / 60)h \(rounded % 60)m", "\(rounded / 60) 小时 \(rounded % 60) 分")
                : text("\(rounded)m", "\(rounded) 分钟")
            batteryEstimateLabel?.stringValue = minutes < 5
                ? text("Cutoff in under 5 min · estimate varies with load", "预计不足 5 分钟触发保护 · 随负载变化")
                : text("≈ \(duration) to cutoff · varies with load", "预计约 \(duration)后触发保护 · 随负载变化")
        }
    }

    @objc private func floorSliderChanged(_ sender: NSSlider) {
        let v = min(max(Int(sender.doubleValue.rounded()), floorMin), floorMax)
        if v != batteryFloorPercent {
            batteryFloorPercent = v
            UserDefaults.standard.set(v, forKey: floorKey)
        }
        renderText()
    }

    // Result of the privileged keep-awake toggle, based on sudo's REAL exit status — not on a
    // second, independent state read. `.ok` = the command ran; `.grantMissing` = the passwordless
    // sudoers grant isn't installed (sudo -n refused), the one case that warrants setup; `.failed`
    // = any other error. Using sudo's own result (instead of re-reading SleepDisabled) is the fix:
    // a safety net flipping sleep back on must never look like "permission missing" and re-prompt.
    private enum ToggleResult: Equatable { case ok, grantMissing, failed(String) }

    private func setOwnership(_ owned: Bool) {
        ownsDisableSleep = owned
        UserDefaults.standard.set(owned, forKey: ownershipKey)
    }

    @discardableResult
    private func setDisableSleep(_ on: Bool) -> ToggleResult {
        // sudo -n: never prompt (GUI app has no TTY). The exact argument vector matches the
        // NOPASSWD sudoers grant, so this runs without a password.
        let (exit, _, err) = runPrivileged(["-n", "/usr/bin/pmset", "-a", "disablesleep", on ? "1" : "0"])
        let result: ToggleResult
        if exit == 0 {
            result = .ok
        } else if err.range(of: "a password is required", options: .caseInsensitive) != nil
               || err.range(of: "not allowed", options: .caseInsensitive) != nil
               || err.range(of: "may not run", options: .caseInsensitive) != nil {
            result = .grantMissing   // grant absent/removed -> sudo -n refused to run passwordless
        } else {
            result = .failed(err.isEmpty ? "exit \(exit)" : err.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result
    }

    // Run a privileged command via sudo, capturing exit status + stderr (which the generic
    // runCapture discards). stdin is /dev/null so a GUI process with no controlling TTY can
    // never block on a prompt. This is what lets the app KNOW whether its own toggle worked.
    private func runPrivileged(_ args: [String]) -> (exit: Int32, out: String, err: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"
        env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        process.environment = env
        let outPipe = Pipe(), errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = FileHandle.nullDevice
        do { try process.run() }
        catch {
            NSLog("Atomic Grunt: failed to launch sudo: %@", error.localizedDescription)
            return (-1, "", "launch failed: \(error.localizedDescription)")
        }
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus,
                String(data: outData, encoding: .utf8) ?? "",
                String(data: errData, encoding: .utf8) ?? "")
    }

    // MARK: - Battery + Low-Power-Mode safety nets (silent; no extra UI) — Feature 3
    private func enforceSafetyNets() {
        guard ownsDisableSleep else { return }
        guard let (onBattery, discharging, percent) = batteryStatus() else {
            _ = turnOffForSafety(
                success: text("Battery status unavailable. Atomic Grunt turned off safely.", "无法读取电池状态，核动力牛马 已安全关闭。"),
                failure: text("Battery status unavailable and auto-off failed. Turn Atomic Grunt off manually.", "无法读取电池状态且自动关闭失败，请手动关闭 核动力牛马。")
            )
            return
        }
        guard onBattery, discharging else { return }
        // Hard battery floor ALWAYS wins, even over a deliberate turn-on: never drain to empty.
        if percent <= batteryFloorPercent {
            _ = turnOffForSafety(
                success: text("Battery low (\(percent)%). Atomic Grunt turned off.", "电量较低（\(percent)%），核动力牛马 已关闭。"),
                failure: text("Low-battery auto-off failed. Turn Atomic Grunt off manually.", "低电量自动关闭失败，请手动关闭 核动力牛马。")
            )
            return
        }
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            _ = turnOffForSafety(
                success: text("Low Power Mode on. Atomic Grunt turned off.", "已进入低电量模式，核动力牛马 已关闭。"),
                failure: text("Low Power Mode auto-off failed. Turn Atomic Grunt off manually.", "低电量模式自动关闭失败，请手动关闭 核动力牛马。")
            )
        }
    }

    @discardableResult
    private func turnOffForSafety(success: String, failure: String) -> Bool {
        guard setDisableSleep(false) == .ok, readSleepDisabled() == false else {
            applyUI(on: readSleepDisabled() ?? isOn)
            notify(failure)
            return false
        }
        setOwnership(false)
        cancelKeepAwakeTimer()
        applyUI(on: false)
        notify(success)
        return true
    }

    // MARK: - Readers (no root needed)
    private func readSleepDisabled() -> Bool? {
        let out = runCapture("/usr/bin/pmset", ["-g"])
        guard !out.isEmpty else { return nil }
        for line in out.split(whereSeparator: { $0 == "\n" }) {
            if line.range(of: "SleepDisabled", options: .caseInsensitive) != nil {
                let toks = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
                if let last = toks.last { return last == "1" }
            }
        }
        return false   // successful output with no line -> OFF
    }

    private func batteryStatus() -> (onBattery: Bool, discharging: Bool, percent: Int)? {
        let out = runCapture("/usr/bin/pmset", ["-g", "batt"])
        guard out.contains("Battery Power") || out.contains("AC Power") else { return nil }
        let onBattery = out.contains("Battery Power")
        let discharging = out.range(of: "discharging", options: .caseInsensitive) != nil
        var percent: Int?
        for tok in out.split(whereSeparator: { " \t\n;".contains($0) }) {
            if tok.hasSuffix("%"), let v = Int(tok.dropLast()) { percent = v; break }
        }
        guard let percent else { return nil }
        return (onBattery, discharging, percent)
    }

    // MARK: - Notification (mirrors Nexus' osascript approach)
    private func notify(_ message: String) {
        let script = "display notification \"\(message)\" with title \"Atomic Grunt\" sound name \"Tink\""
        _ = runCapture("/usr/bin/osascript", ["-e", script])
    }

    // MARK: - Process runner (explicit PATH/HOME; captures stdout)
    @discardableResult
    private func runCapture(_ launchPath: String, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"
        env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        process.environment = env
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do { try process.run() }
        catch { NSLog("Atomic Grunt: failed to launch %@: %@", launchPath, error.localizedDescription); return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    @objc private func quit() {
        if ownsDisableSleep, setDisableSleep(false) != .ok {
            notify(text("Couldn't restore normal sleep; Atomic Grunt is still running.", "无法恢复正常休眠；核动力牛马 将继续运行。"))
            refresh()
            return
        }
        setOwnership(false)
        NSApp.terminate(nil)
    }
}

@main
enum SleeplessApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        objc_setAssociatedObject(app, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
        app.run()
    }
}

nonisolated(unsafe) private var delegateKey = 0
