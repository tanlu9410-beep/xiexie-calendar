// SPDX-License-Identifier: MIT
import AppKit
import WebKit

// Native overlay receives input without depending on WebKit's private subviews.
final class PetInteractionView: NSView {
    var clicked: (() -> Void)?
    var moved: (() -> Void)?
    var contextMenu: (() -> NSMenu)?
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        guard let window = window else { return }
        let before = window.frame.origin
        window.performDrag(with: event)
        let after = window.frame.origin
        if hypot(after.x - before.x, after.y - before.y) < 3 { clicked?() }
        moved?()
    }
    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenu?() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}

final class PetDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var panel: NSPanel!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var looks: [[String: String]] = []
    var paused = false
    let defaults = UserDefaults.standard
    let sizes: [CGFloat] = [174, 232, 348]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let size = defaults.double(forKey: "petWidth")
        let width: CGFloat = sizes.contains(CGFloat(size)) ? CGFloat(size) : 232
        panel = NSPanel(contentRect: NSRect(x: 100, y: 100, width: width, height: width * 34 / 58),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false

        let content = NSView(frame: panel.contentView!.bounds)
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = content
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: content.bounds, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        content.addSubview(webView)
        let interaction = PetInteractionView(frame: content.bounds)
        interaction.autoresizingMask = [.width, .height]
        interaction.clicked = { [weak self] in self?.nextLook() }
        interaction.moved = { [weak self] in self?.savePosition() }
        interaction.contextMenu = { [weak self] in self?.makeMenu() ?? NSMenu() }
        content.addSubview(interaction)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🦀"
        statusItem.button?.toolTip = "蟹蟹桌宠：点击换职业，拖动移动，右键菜单"
        statusItem.menu = makeMenu()
        restorePosition()
        guard let resources = Bundle.main.resourceURL else { NSApp.terminate(nil); return }
        webView.loadFileURL(resources.appendingPathComponent("pet.html"), allowingReadAccessTo: resources)
        panel.orderFrontRegardless()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let selected = defaults.string(forKey: "lookID") ?? ""
        guard let literal = javascriptString(selected) else { return }
        webView.evaluateJavaScript("pet.select(\(literal)[0]); pet.list()") { [weak self] value, error in
            guard let self = self else { return }
            if let error = error { NSLog("Pet renderer failed: %@", error.localizedDescription); return }
            self.looks = value as? [[String: String]] ?? []
            self.statusItem.menu = self.makeMenu()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // No remote pages, sign-ins, APIs, or account data in this prototype.
        decisionHandler(navigationAction.request.url?.isFileURL == true ? .allow : .cancel)
    }

    @objc func nextLook() {
        webView.evaluateJavaScript("pet.next()") { [weak self] value, _ in
            if let id = value as? String { self?.defaults.set(id, forKey: "lookID") }
        }
    }

    @objc func chooseLook(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        guard let literal = javascriptString(id) else { return }
        webView.evaluateJavaScript("pet.select(\(literal)[0])")
        defaults.set(id, forKey: "lookID")
    }

    @objc func togglePause() {
        paused.toggle()
        webView.evaluateJavaScript("pet.pause(\(paused))")
        statusItem.menu = makeMenu()
    }

    @objc func resizePet(_ sender: NSMenuItem) {
        guard sizes.indices.contains(sender.tag) else { return }
        let width = sizes[sender.tag]
        let frame = panel.frame
        panel.setFrame(NSRect(x: frame.midX - width / 2, y: frame.minY, width: width, height: width * 34 / 58), display: true)
        defaults.set(Double(width), forKey: "petWidth")
        savePosition()
    }

    func restorePosition() {
        guard let screen = NSScreen.main else { return }
        let area = screen.visibleFrame
        if defaults.object(forKey: "petX") != nil {
            panel.setFrameOrigin(NSPoint(x: defaults.double(forKey: "petX"), y: defaults.double(forKey: "petY")))
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(panel.frame) }) { return }
        }
        panel.setFrameOrigin(NSPoint(x: area.maxX - panel.frame.width - 32, y: area.minY + 32))
    }

    func savePosition() {
        defaults.set(Double(panel.frame.minX), forKey: "petX")
        defaults.set(Double(panel.frame.minY), forKey: "petY")
    }

    // JSON quoting keeps user defaults out of executable JavaScript syntax.
    func javascriptString(_ value: String) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: [value]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @objc func resetPosition() {
        defaults.removeObject(forKey: "petX")
        restorePosition()
        panel.orderFrontRegardless()
        savePosition()
    }

    @objc func about() {
        let alert = NSAlert()
        alert.messageText = "蟹蟹桌宠 · 非官方同人原型"
        alert.informativeText = "原项目：蟹蟹日历 xiexie-calendar\n画：Claude · 审稿与验收：小船\n桌宠改编：Li-0803 fork\n\n代码遵循 MIT，美术遵循 CC BY-NC 4.0（署名、非商用）。Clawd 角色及商标归 Anthropic，项目与 Anthropic 无关联。\n\n左键点击换职业，拖动移动，右键打开菜单。全程离线，不读取其他应用或聊天数据。"
        alert.addButton(withTitle: "知道了")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc func quit() { savePosition(); NSApp.terminate(nil) }

    func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let value = NSMenuItem(title: title, action: action, keyEquivalent: "")
        value.target = self
        return value
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("下一个职业", #selector(nextLook)))
        let choose = NSMenuItem(title: "选择职业", action: nil, keyEquivalent: "")
        let choices = NSMenu()
        for look in looks {
            let value = item(look["title"] ?? "", #selector(chooseLook(_:)))
            value.representedObject = look["id"]
            choices.addItem(value)
        }
        choose.submenu = choices
        menu.addItem(choose)
        menu.addItem(item(paused ? "继续动画" : "暂停动画", #selector(togglePause)))
        let sizeMenu = NSMenuItem(title: "大小", action: nil, keyEquivalent: "")
        let sizesMenu = NSMenu()
        for (index, title) in ["小", "中", "大"].enumerated() {
            let value = item(title, #selector(resizePet(_:)))
            value.tag = index
            sizesMenu.addItem(value)
        }
        sizeMenu.submenu = sizesMenu
        menu.addItem(sizeMenu)
        menu.addItem(item("回到屏幕右下角", #selector(resetPosition)))
        menu.addItem(.separator())
        menu.addItem(item("关于与原作者署名", #selector(about)))
        menu.addItem(item("退出蟹蟹桌宠", #selector(quit)))
        return menu
    }
}

let app = NSApplication.shared
let delegate = PetDelegate()
app.setActivationPolicy(.accessory)
app.delegate = delegate
app.run()
