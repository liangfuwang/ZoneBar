import AppKit
import ServiceManagement

/// (identifier, 中文名) for the "quick add" submenu.
private let presets: [(String, String)] = [
    ("America/Los_Angeles", "洛杉矶"),
    ("America/Denver", "丹佛"),
    ("America/Chicago", "芝加哥"),
    ("America/New_York", "纽约"),
    ("America/Sao_Paulo", "圣保罗"),
    ("Europe/London", "伦敦"),
    ("Europe/Paris", "巴黎"),
    ("Europe/Berlin", "柏林"),
    ("Europe/Moscow", "莫斯科"),
    ("Asia/Dubai", "迪拜"),
    ("Asia/Kolkata", "孟买 / 新德里"),
    ("Asia/Singapore", "新加坡"),
    ("Asia/Shanghai", "上海 / 北京"),
    ("Asia/Hong_Kong", "香港"),
    ("Asia/Tokyo", "东京"),
    ("Asia/Seoul", "首尔"),
    ("Australia/Sydney", "悉尼"),
    ("Pacific/Auckland", "奥克兰"),
    ("Pacific/Honolulu", "檀香山"),
    ("UTC", "UTC"),
]

private func displayName(_ id: String) -> String {
    if let p = presets.first(where: { $0.0 == id }) { return p.1 }
    return id.split(separator: "/").last.map { $0.replacingOccurrences(of: "_", with: " ") } ?? id
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let settings = Settings.shared
    private var statusItem: NSStatusItem!
    private let menu = NSMenu()
    private var timer: Timer?
    private var zoneItems: [(id: String, item: NSMenuItem)] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
        tick()
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        // Align first fire to the next whole second, then repeat every second.
        let next = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970) + 1)
        let t = Timer(fire: next, interval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common) // .common keeps ticking while the menu is open
        timer = t
    }

    // DateFormatter is expensive to create; reuse instances across ticks.
    private var timeFormatters: [String: DateFormatter] = [:]
    private var dayFormatters: [String: DateFormatter] = [:]

    private func formatter(for id: String, seconds: Bool) -> DateFormatter {
        let key = "\(id)|\(seconds)|\(settings.use24Hour)"
        if let cached = timeFormatters[key] { return cached }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: id)
        let hm = settings.use24Hour ? "HH:mm" : "h:mm"
        let s = seconds ? ":ss" : ""
        let ampm = settings.use24Hour ? "" : " a"
        f.dateFormat = hm + s + ampm
        timeFormatters[key] = f
        return f
    }

    private func dayFormatter(for tz: TimeZone) -> DateFormatter {
        if let cached = dayFormatters[tz.identifier] { return cached }
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.timeZone = tz
        f.dateFormat = "M月d日 EEE"
        dayFormatters[tz.identifier] = f
        return f
    }

    private func tick() {
        let now = Date()
        let id = settings.primary
        let time = formatter(for: id, seconds: settings.showSeconds).string(from: now)
        statusItem.button?.title = settings.showCity ? "\(displayName(id)) \(time)" : time

        for (zid, item) in zoneItems {
            item.title = zoneLine(zid, now: now)
        }
    }

    private func zoneLine(_ id: String, now: Date) -> String {
        guard let tz = TimeZone(identifier: id) else { return id }
        let time = formatter(for: id, seconds: true).string(from: now)
        let abbr = tz.abbreviation(for: now) ?? ""
        return "\(displayName(id))   \(time)   \(dayFormatter(for: tz).string(from: now))  \(abbr)"
    }

    // MARK: - Menu

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
        tick()
    }

    private func rebuildMenu() {
        menu.removeAllItems()
        zoneItems.removeAll()

        let header = NSMenuItem(title: "点击时区设为菜单栏显示", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)

        for id in settings.zones {
            let item = NSMenuItem(title: id, action: #selector(selectPrimary(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = id
            item.state = id == settings.primary ? .on : .off
            menu.addItem(item)
            zoneItems.append((id, item))
        }

        menu.addItem(.separator())

        // Add: presets + custom
        let addItem = NSMenuItem(title: "添加时区", action: nil, keyEquivalent: "")
        let addMenu = NSMenu()
        for (id, name) in presets where !settings.zones.contains(id) {
            let m = NSMenuItem(title: "\(name)  (\(id))", action: #selector(addZone(_:)), keyEquivalent: "")
            m.target = self
            m.representedObject = id
            addMenu.addItem(m)
        }
        if addMenu.items.count > 0 { addMenu.addItem(.separator()) }
        let custom = NSMenuItem(title: "自定义…", action: #selector(addCustomZone), keyEquivalent: "")
        custom.target = self
        addMenu.addItem(custom)
        addItem.submenu = addMenu
        menu.addItem(addItem)

        // Remove
        if settings.zones.count > 1 {
            let rmItem = NSMenuItem(title: "移除时区", action: nil, keyEquivalent: "")
            let rmMenu = NSMenu()
            for id in settings.zones {
                let m = NSMenuItem(title: "\(displayName(id))  (\(id))", action: #selector(removeZone(_:)), keyEquivalent: "")
                m.target = self
                m.representedObject = id
                rmMenu.addItem(m)
            }
            rmItem.submenu = rmMenu
            menu.addItem(rmItem)
        }

        menu.addItem(.separator())

        menu.addItem(toggle("24 小时制", settings.use24Hour, #selector(toggle24)))
        menu.addItem(toggle("显示秒", settings.showSeconds, #selector(toggleSeconds)))
        menu.addItem(toggle("菜单栏显示城市名", settings.showCity, #selector(toggleCity)))
        menu.addItem(toggle("开机自启动", SMAppService.mainApp.status == .enabled, #selector(toggleLogin)))

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 ZoneBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func toggle(_ title: String, _ on: Bool, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    // MARK: - Actions

    @objc private func selectPrimary(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        settings.primary = id
        tick()
    }

    @objc private func addZone(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        append(id)
    }

    private func append(_ id: String) {
        guard TimeZone(identifier: id) != nil, !settings.zones.contains(id) else { return }
        settings.zones.append(id)
        settings.primary = id
        tick()
    }

    @objc private func removeZone(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        var zones = settings.zones
        zones.removeAll { $0 == id }
        settings.zones = zones
        if settings.primary == id { settings.primary = zones.first ?? TimeZone.current.identifier }
        tick()
    }

    @objc private func addCustomZone() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "添加自定义时区"
        alert.informativeText = "输入或选择 IANA 时区标识，例如 America/Los_Angeles、Europe/London。"
        let combo = NSComboBox(frame: NSRect(x: 0, y: 0, width: 300, height: 26))
        combo.addItems(withObjectValues: TimeZone.knownTimeZoneIdentifiers.sorted())
        combo.completes = true
        combo.numberOfVisibleItems = 15
        combo.placeholderString = "America/Los_Angeles"
        alert.accessoryView = combo
        alert.addButton(withTitle: "添加")
        alert.addButton(withTitle: "取消")
        alert.window.initialFirstResponder = combo

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let id = combo.stringValue.trimmingCharacters(in: .whitespaces)
        if TimeZone(identifier: id) != nil {
            append(id)
        } else {
            let err = NSAlert()
            err.messageText = "无效的时区：\(id)"
            err.runModal()
        }
    }

    @objc private func toggle24() { settings.use24Hour.toggle(); tick() }
    @objc private func toggleSeconds() { settings.showSeconds.toggle(); tick() }
    @objc private func toggleCity() { settings.showCity.toggle(); tick() }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let a = NSAlert()
            a.messageText = "无法设置开机自启动"
            a.informativeText = "请使用 scripts/build-app.sh 构建的 ZoneBar.app 运行。\n\(error.localizedDescription)"
            a.runModal()
        }
    }
}
