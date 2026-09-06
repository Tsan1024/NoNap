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
//   1. Auto-off timer (1h / 2h) — stores its deadline so a relaunch can resume it.
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
    let base = NSImage(systemSymbolName: name, accessibilityDescription: "Sleepless")?
        .withSymbolConfiguration(cfg)
        ?? NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Sleepless")
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

// Brand accent (2026 "Liquid Glass" redesign): indigo -> violet -> fuchsia. The
// violet mid-tone is the single accent the popover uses to communicate the
// privileged "awake" state, matching the app icon's gradient mid-stop. These are
// the only hard-coded colours; everything else stays on system semantic colours so
// the panel still reads as a first-party control.
private let brandAccent = NSColor(srgbRed: 139/255.0, green: 92/255.0, blue: 246/255.0, alpha: 1)   // #8B5CF6 violet
private let brandAccentSoft = NSColor(srgbRed: 167/255.0, green: 139/255.0, blue: 250/255.0, alpha: 1) // #A78BFA

// Frosted-glass popover backing: a flipped NSVisualEffectView so content still
// lays out top-down while the panel gets a translucent, blurred material that
// samples the desktop/windows behind it (system light/dark aware). On macOS 26 the
// .popover material renders as the system Liquid Glass automatically; we deliberately
// keep this native (no hand-rolled tint on the surface) so a sudo-touching panel
// stays visually first-party. Colour lives on the controls, never the surface.
private final class GlassView: NSVisualEffectView { override var isFlipped: Bool { true } }

// Inset grouping "card" (System Settings rhythm): a flipped, layer-backed container
// with a subtle, appearance-adaptive fill, a hairline border, and continuous-corner
// rounding. When `active`, the card carries a faint brand-violet wash + a violet
// hairline so the privileged "kept awake" state is unmistakable at a glance in the
// accent colour (Apple's "tint elements, not surfaces" model). Re-resolved on
// light/dark changes and on state changes via updateLayer.
private final class CardView: NSView {
    var active = false { didSet { if active != oldValue { needsDisplay = true } } }
    override var isFlipped: Bool { true }
    override var wantsUpdateLayer: Bool { true }
    override func updateLayer() {
        let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if active {
            layer?.backgroundColor = brandAccent.withAlphaComponent(dark ? 0.18 : 0.10).cgColor
            layer?.borderColor = brandAccent.withAlphaComponent(dark ? 0.60 : 0.45).cgColor
            layer?.borderWidth = 1
        } else {
            layer?.backgroundColor = (dark ? NSColor.white.withAlphaComponent(0.06)
                                           : NSColor.black.withAlphaComponent(0.045)).cgColor
            layer?.borderColor = (dark ? NSColor.white.withAlphaComponent(0.08)
                                       : NSColor.black.withAlphaComponent(0.06)).cgColor
            layer?.borderWidth = 1
        }
        layer?.cornerRadius = 11
        layer?.cornerCurve = .continuous
    }
}

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
    private var mainCard: CardView!         // group-1 card; gets the brand-violet wash when awake
    private var headerMark: NSImageView!    // header coffee mark; tints violet when awake
    private var captionLabel: NSTextField!
    private var mainLabel: NSTextField!
    private var timerLabel: NSTextField!
    private var floorLabel: NSTextField!
    private var loginLabel: NSTextField!
    private var floorValueLabel: NSTextField!
    private var floorSlider: NSSlider!
    private var autoOffControl: NSSegmentedControl!
    private var countdownLabel: NSTextField!
    private var loginSwitch: NSSwitch!
    private var languageControl: NSSegmentedControl!
    private var quitButton: NSButton!
    private var clickMonitor: Any?
    private var batteryFloorPercent = floorDefault
    private var isOn = false
    private var ownsDisableSleep = false
    private var stateReadFailureNotified = false
    private var language: AppLanguage = .english

    // Auto-off timer (deadline persisted for crash/relaunch recovery)
    private var autoOffMinutes = 0           // 0 = none (stay on until off), 60, or 120
    private var keepAwakeTimer: Timer?       // one-shot: flips sleep back on when it fires
    private var countdownTicker: Timer?      // 1 Hz label refresh, only while the popover is open
    private var timerEndDate: Date?

    private let popoverWidth: CGFloat = 320
    private let popoverHeight: CGFloat = 432

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

    // MARK: - Popover content (native NSSwitch toggle, macOS-aligned)
    private func makeContentController() -> NSViewController {
        let W = popoverWidth, pad: CGFloat = 16
        let contentW = W - pad * 2
        let ci: CGFloat = 12                 // card inner padding
        let cw = contentW - ci * 2           // card inner content width

        // Standard system popover material: untinted, no forced emphasis, so it reads
        // as a first-party control (like the Wi-Fi / Sound / Battery popovers), not a
        // themed panel. NSPopover supplies its own corner, shadow, and arrow.
        let root = GlassView(frame: NSRect(x: 0, y: 0, width: W, height: popoverHeight))
        root.material = .popover
        root.blendingMode = .behindWindow
        root.state = .followsWindowActiveState

        // Header: small coffee mark + "Sleepless" (quiet system glyph, not a branded logo).
        // The mark tints to the brand violet while the Mac is kept awake.
        let mark = NSImageView(frame: NSRect(x: pad, y: 14, width: 18, height: 18))
        let headerCup = makeCupGlyph(.on); headerCup.isTemplate = true
        mark.image = headerCup
        mark.contentTintColor = .labelColor
        root.addSubview(mark)
        headerMark = mark
        let title = makeLabel("Sleepless", font: .systemFont(ofSize: 14, weight: .semibold), color: .labelColor)
        title.frame = NSRect(x: pad + 24, y: 14, width: contentW - 24, height: 20)
        root.addSubview(title)

        // Grouped inset cards (System Settings rhythm) replace per-row hairline separators.
        func makeCard(_ rect: NSRect) -> CardView {
            let c = CardView(frame: rect)
            c.wantsLayer = true
            root.addSubview(c)
            return c
        }
        let swProto = NSSwitch().intrinsicContentSize
        let swW = swProto.width > 0 ? swProto.width : 38
        let swH = swProto.height > 0 ? swProto.height : 21

        // GROUP 1 — main switch + state caption
        let g1y: CGFloat = 46, g1h: CGFloat = 84
        let g1 = makeCard(NSRect(x: pad, y: g1y, width: contentW, height: g1h))
        mainCard = g1
        mainLabel = makeLabel("", font: .systemFont(ofSize: 13), color: .labelColor)
        mainLabel.frame = NSRect(x: ci, y: ci, width: cw - swW - 8, height: 22)
        g1.addSubview(mainLabel)
        toggleSwitch = NSSwitch()
        toggleSwitch.target = self
        toggleSwitch.action = #selector(switchToggled(_:))
        toggleSwitch.frame = NSRect(x: contentW - ci - swW, y: ci + (22 - swH) / 2, width: swW, height: swH)
        g1.addSubview(toggleSwitch)
        captionLabel = makeLabel("", font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
        captionLabel.frame = NSRect(x: ci, y: ci + 30, width: cw, height: 32)
        captionLabel.usesSingleLineMode = false
        captionLabel.lineBreakMode = .byWordWrapping
        captionLabel.maximumNumberOfLines = 2
        captionLabel.cell?.wraps = true
        g1.addSubview(captionLabel)

        // GROUP 2 — auto-off timer (label + segmented [Off | 1h | 2h] + countdown)
        let g2y = g1y + g1h + 12, g2h: CGFloat = 78
        let g2 = makeCard(NSRect(x: pad, y: g2y, width: contentW, height: g2h))
        timerLabel = makeLabel("", font: .systemFont(ofSize: 13), color: .labelColor)
        timerLabel.frame = NSRect(x: ci, y: ci + 3, width: 110, height: 22)
        g2.addSubview(timerLabel)
        autoOffControl = NSSegmentedControl(labels: ["Off", "1h", "2h"],
                                            trackingMode: .selectOne,
                                            target: self, action: #selector(autoOffChanged(_:)))
        autoOffControl.selectedSegment = 0
        autoOffControl.controlSize = .regular
        autoOffControl.segmentStyle = .automatic
        autoOffControl.sizeToFit()
        let segSize = autoOffControl.frame.size
        let segW = segSize.width > 0 ? segSize.width : 150
        autoOffControl.frame = NSRect(x: contentW - ci - segW, y: ci, width: segW, height: max(segSize.height, 24))
        g2.addSubview(autoOffControl)
        countdownLabel = makeLabel("", font: .systemFont(ofSize: 12), color: .secondaryLabelColor)
        countdownLabel.frame = NSRect(x: ci, y: ci + 36, width: cw, height: 16)
        g2.addSubview(countdownLabel)

        // GROUP 3 — battery-floor (label + value + slider + min/max hints)
        let g3y = g2y + g2h + 12, g3h: CGFloat = 92
        let g3 = makeCard(NSRect(x: pad, y: g3y, width: contentW, height: g3h))
        floorLabel = makeLabel("", font: .systemFont(ofSize: 13), color: .labelColor)
        floorLabel.frame = NSRect(x: ci, y: ci, width: cw - 54, height: 18)
        g3.addSubview(floorLabel)
        floorValueLabel = makeLabel("\(batteryFloorPercent)%", font: .systemFont(ofSize: 13, weight: .semibold), color: .secondaryLabelColor)
        floorValueLabel.alignment = .right
        floorValueLabel.frame = NSRect(x: contentW - ci - 54, y: ci, width: 54, height: 18)
        g3.addSubview(floorValueLabel)
        floorSlider = NSSlider(value: Double(batteryFloorPercent), minValue: Double(floorMin), maxValue: Double(floorMax),
                               target: self, action: #selector(floorSliderChanged(_:)))
        floorSlider.isContinuous = true          // live update while dragging
        floorSlider.controlSize = .regular
        floorSlider.frame = NSRect(x: ci, y: ci + 26, width: cw, height: 20)
        g3.addSubview(floorSlider)
        let minHint = makeLabel("\(floorMin)%", font: .systemFont(ofSize: 10), color: .tertiaryLabelColor)
        minHint.frame = NSRect(x: ci, y: ci + 50, width: 34, height: 13)
        g3.addSubview(minHint)
        let maxHint = makeLabel("\(floorMax)%", font: .systemFont(ofSize: 10), color: .tertiaryLabelColor)
        maxHint.alignment = .right
        maxHint.frame = NSRect(x: contentW - ci - 34, y: ci + 50, width: 34, height: 13)
        g3.addSubview(maxHint)

        // GROUP 4 — launch at login (off by default; never auto-enables sleep prevention)
        let g4y = g3y + g3h + 12, g4h: CGFloat = 46
        let g4 = makeCard(NSRect(x: pad, y: g4y, width: contentW, height: g4h))
        loginLabel = makeLabel("", font: .systemFont(ofSize: 13), color: .labelColor)
        loginLabel.frame = NSRect(x: ci, y: ci, width: cw - swW - 8, height: 22)
        g4.addSubview(loginLabel)
        loginSwitch = NSSwitch()
        loginSwitch.target = self
        loginSwitch.action = #selector(loginToggled(_:))
        loginSwitch.state = loginItemEnabled() ? .on : .off
        loginSwitch.frame = NSRect(x: contentW - ci - swW, y: ci + (22 - swH) / 2, width: swW, height: swH)
        g4.addSubview(loginSwitch)

        // Footer — language + Quit.
        languageControl = NSSegmentedControl(labels: ["English", "中文"], trackingMode: .selectOne,
                                             target: self, action: #selector(languageChanged(_:)))
        languageControl.selectedSegment = language.rawValue
        languageControl.controlSize = .small
        languageControl.frame = NSRect(x: pad, y: g4y + g4h + 14, width: 116, height: 24)
        root.addSubview(languageControl)

        quitButton = NSButton(title: "", target: self, action: #selector(quit))
        quitButton.controlSize = .regular
        quitButton.bezelStyle = .rounded
        root.addSubview(quitButton)
        updateLocalizedText()

        let vc = NSViewController()
        vc.view = root
        return vc
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

    @objc private func languageChanged(_ sender: NSSegmentedControl) {
        language = AppLanguage(rawValue: sender.selectedSegment) ?? .english
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        updateLocalizedText()
        applyUI(on: isOn)
    }

    private func updateLocalizedText() {
        mainLabel?.stringValue = text("Keep awake with lid closed", "合盖时保持运行")
        timerLabel?.stringValue = text("Auto-off timer", "自动关闭")
        autoOffControl?.setLabel(text("Off", "关闭"), forSegment: 0)
        autoOffControl?.setLabel(text("1h", "1小时"), forSegment: 1)
        autoOffControl?.setLabel(text("2h", "2小时"), forSegment: 2)
        autoOffControl?.sizeToFit()
        if let control = autoOffControl, let parent = control.superview {
            control.frame.origin.x = parent.bounds.width - 12 - control.frame.width
        }
        floorLabel?.stringValue = text("Auto-off at low battery", "低电量时自动关闭")
        loginLabel?.stringValue = text("Launch at login", "登录时启动")
        quitButton?.title = text("Quit Sleepless", "退出 Sleepless")
        quitButton?.sizeToFit()
        if let size = quitButton?.frame.size {
            quitButton?.frame = NSRect(x: popoverWidth - 16 - size.width, y: 394, width: size.width, height: size.height)
        }
    }

    // MARK: - Click the menu-bar cup to open/close the popover
    @objc private func statusClicked() {
        if popover.isShown { closePopover() } else { openPopover() }
    }

    private func openPopover() {
        refresh()                              // sync switch/caption to TRUE state before showing
        loginSwitch?.state = loginItemEnabled() ? .on : .off
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
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
            "Sleepless needs permission once to install a rule limited to two pmset commands. After that the switch works without more prompts.",
            "Sleepless 需要一次管理员授权，以安装仅限两条 pmset 命令的规则。之后使用开关无需再次授权。"
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
    @objc private func autoOffChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1: autoOffMinutes = 60
        case 2: autoOffMinutes = 120
        default: autoOffMinutes = 0
        }
        if isOn, ownsDisableSleep, autoOffMinutes > 0 {
            startKeepAwakeTimer(minutes: autoOffMinutes)
        } else {
            cancelKeepAwakeTimer()
            updateCountdownLabel()
        }
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
            success: text("Auto-off timer ended. Sleepless turned off.", "自动关闭计时结束，Sleepless 已关闭。"),
            failure: text("Auto-off failed. Turn Sleepless off manually.", "自动关闭失败，请手动关闭 Sleepless。")
        ) {
            autoOffMinutes = 0
            autoOffControl?.selectedSegment = 0
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
        autoOffMinutes = remaining <= 3600 ? 60 : 120
        autoOffControl?.selectedSegment = autoOffMinutes == 60 ? 1 : 2
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
        guard let end = timerEndDate, isOn else { countdownLabel?.stringValue = ""; return }
        let remaining = Int(end.timeIntervalSinceNow.rounded())
        guard remaining > 0 else { countdownLabel?.stringValue = ""; return }
        let h = remaining / 3600, m = (remaining % 3600) / 60, s = remaining % 60
        let t = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        countdownLabel?.stringValue = text("Auto-off in \(t)", "将在 \(t) 后关闭")
    }

    // MARK: - Launch at login (Feature 2) — OFF by default; never re-enables sleep prevention
    @objc private func loginToggled(_ sender: NSSwitch) {
        do {
            if sender.state == .on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Sleepless: login item update failed: %@", error.localizedDescription)
            notify(text("Couldn't update Launch at login.", "无法更新登录启动设置。"))
        }
        sender.state = loginItemEnabled() ? .on : .off
    }

    private func loginItemEnabled() -> Bool { SMAppService.mainApp.status == .enabled }

    // MARK: - Core state sync
    @objc private func refresh() {
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
                    ? text("Sleepless: on (battery). Auto-off at \(batteryFloorPercent)% or in Low Power Mode.",
                           "Sleepless：已开启（电池供电），将在 \(batteryFloorPercent)% 或低电量模式下关闭。")
                    : text("Sleepless: on. Stays awake with the lid closed.", "Sleepless：已开启，合盖后继续运行。"))
                : text("Sleepless: off. Sleeps normally.", "Sleepless：已关闭，正常休眠。")
        }
        toggleSwitch?.state = on ? .on : .off
        // Brand-violet accent communicates the privileged "awake" state at a glance.
        mainCard?.active = on
        headerMark?.contentTintColor = on ? brandAccentSoft : .labelColor
        renderText()
        updateCountdownLabel()
    }

    // Update text labels only (no pmset subprocess; safe to call on every slider tick).
    private func renderText() {
        floorValueLabel?.stringValue = "\(batteryFloorPercent)%"
        captionLabel?.stringValue = isOn
            ? text("Stays awake with the lid closed. Turns off at \(batteryFloorPercent)% battery or in Low Power Mode.",
                   "合盖后继续运行；电量降至 \(batteryFloorPercent)% 或进入低电量模式时关闭。")
            : text("Sleeps normally when you close the lid.", "合盖后正常休眠。")
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
            NSLog("Sleepless: failed to launch sudo: %@", error.localizedDescription)
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
                success: text("Battery status unavailable. Sleepless turned off safely.", "无法读取电池状态，Sleepless 已安全关闭。"),
                failure: text("Battery status unavailable and auto-off failed. Turn Sleepless off manually.", "无法读取电池状态且自动关闭失败，请手动关闭 Sleepless。")
            )
            return
        }
        guard onBattery, discharging else { return }
        // Hard battery floor ALWAYS wins, even over a deliberate turn-on: never drain to empty.
        if percent <= batteryFloorPercent {
            _ = turnOffForSafety(
                success: text("Battery low (\(percent)%). Sleepless turned off.", "电量较低（\(percent)%），Sleepless 已关闭。"),
                failure: text("Low-battery auto-off failed. Turn Sleepless off manually.", "低电量自动关闭失败，请手动关闭 Sleepless。")
            )
            return
        }
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            _ = turnOffForSafety(
                success: text("Low Power Mode on. Sleepless turned off.", "已进入低电量模式，Sleepless 已关闭。"),
                failure: text("Low Power Mode auto-off failed. Turn Sleepless off manually.", "低电量模式自动关闭失败，请手动关闭 Sleepless。")
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
        let script = "display notification \"\(message)\" with title \"Sleepless\" sound name \"Tink\""
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
        catch { NSLog("Sleepless: failed to launch %@: %@", launchPath, error.localizedDescription); return "" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    @objc private func quit() {
        if ownsDisableSleep, setDisableSleep(false) != .ok {
            notify(text("Couldn't restore normal sleep; Sleepless is still running.", "无法恢复正常休眠；Sleepless 将继续运行。"))
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
